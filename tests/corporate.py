"""Corporate contracts with synthetic artifacts; never use a real registry."""
import base64
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from unittest import mock
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def module(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), ROOT / "scripts" / (name + ".py"))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


installer = module("install-editor-tools")
download = installer.download


class Corporate(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="corporate-tests-")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.home = self.work / "home"
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home),
                        DOTFILES_NPM_REGISTRY="https://artifactory.example.invalid/npm/",
                        DOTFILES_PYTHON_REGISTRY="https://artifactory.example.invalid/python/simple/",
                        DOTFILES_GIT_NAME="Test", DOTFILES_GIT_EMAIL="test@example.invalid")
        self.environment = mock.patch.dict(os.environ, self.env, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def shell(self, script, *args, success=True):
        result = subprocess.run(["bash", "-euc", script, "_", *map(str, args)],
                                env=self.env, cwd=ROOT, text=True, capture_output=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def npm_fixture(self, external=False):
        source = self.work / "npm-source"
        source.mkdir()
        (source / "package.json").write_text(json.dumps({"name": "fixture-root", "version": "1.0.0",
                                                       "dependencies": {"fixture-cli": "1.0.0"}}))
        archive = self.work / "fixture.tgz"
        package = {"name": "fixture-cli", "version": "1.0.0", "bin": {"fixture-cli": "cli.js"},
                   "scripts": {"postinstall": "node -e \"require('fs').writeFileSync('UNEXPECTED-SCRIPT','bad')\""}}
        contents = {"package/package.json": json.dumps(package).encode(),
                    "package/cli.js": b"#!/usr/bin/env node\nconsole.log('fixture 1.0.0')\n"}
        with tarfile.open(archive, "w:gz") as tar:
            for name, data in contents.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                info.mode = 0o755
                tar.addfile(info, io.BytesIO(data))
        url = ("https://registry.npmjs.org/" if external else self.env["DOTFILES_NPM_REGISTRY"]) + "fixture.tgz"
        integrity = "sha512-" + base64.b64encode(hashlib.sha512(archive.read_bytes()).digest()).decode()
        lock = {"name": "fixture-root", "version": "1.0.0", "lockfileVersion": 3,
                "packages": {"": {"name": "fixture-root", "version": "1.0.0", "dependencies": {"fixture-cli": "1.0.0"}},
                             "node_modules/fixture-cli": {"version": "1.0.0", "resolved": url,
                                                           "integrity": integrity, "bin": {"fixture-cli": "cli.js"}}}}
        (source / "package-lock.json").write_text(json.dumps(lock))
        return source, archive

    def test_external_npm_dependency_is_rejected_before_download(self):
        source, _ = self.npm_fixture(external=True)
        with mock.patch.object(download, "fetch") as fetched:
            with self.assertRaisesRegex(ValueError, "unapproved"):
                installer.npm_install(source, self.work / "destination")
            fetched.assert_not_called()

    @unittest.skipUnless(shutil.which("npm"), "npm required for native offline integration")
    def test_native_npm_install_is_offline_and_ignores_lifecycle_scripts(self):
        source, archive = self.npm_fixture()
        destination = self.work / "npm-destination"
        destination.mkdir()

        def fetch(url, path, checksum, algorithm, registry):
            self.assertEqual(hashlib.sha512(archive.read_bytes()).hexdigest(), checksum)
            shutil.copy2(archive, path)
            return Path(path)

        with mock.patch.object(download, "fetch", side_effect=fetch):
            binaries = installer.npm_install(source, destination)
        result = subprocess.run([str(binaries / "fixture-cli")], capture_output=True, text=True)
        self.assertEqual(result.stdout.strip(), "fixture 1.0.0")
        self.assertFalse(list(destination.rglob("UNEXPECTED-SCRIPT")))

    def test_python_wheel_requires_internal_source_and_hash(self):
        source = self.work / "python"
        source.mkdir()
        (source / "wheels.json").write_text(json.dumps({"wheels": [{"filename": "fixture-1-py3-none-any.whl",
                                                                 "url": "https://files.pythonhosted.org/a.whl", "sha256": "a" * 64}]}))
        with self.assertRaises(ValueError):
            installer.validate_python(source)

    def test_native_pip_installs_hashed_wheel_offline(self):
        source = self.work / "python"
        source.mkdir()
        archive = self.work / "fixture_cli-1.0.0-py3-none-any.whl"
        info = "fixture_cli-1.0.0.dist-info/"
        files = {"fixture_cli.py": "def main():\n    print('fixture 1.0.0')\n",
                 info + "METADATA": "Metadata-Version: 2.1\nName: fixture-cli\nVersion: 1.0.0\n",
                 info + "WHEEL": "Wheel-Version: 1.0\nGenerator: corporate-test\nRoot-Is-Purelib: true\nTag: py3-none-any\n",
                 info + "entry_points.txt": "[console_scripts]\nfixture-cli = fixture_cli:main\n"}
        files[info + "RECORD"] = "".join(name + ",,\n" for name in [*files, info + "RECORD"])
        with zipfile.ZipFile(archive, "w") as zipped:
            for name, contents in files.items():
                zipped.writestr(name, contents)
        (source / "wheels.json").write_text(json.dumps({"wheels": [{"filename": archive.name,
            "url": self.env["DOTFILES_PYTHON_REGISTRY"] + archive.name,
            "sha256": hashlib.sha256(archive.read_bytes()).hexdigest()}]}))
        destination = self.work / "python-destination"
        destination.mkdir()

        def fetch(url, path, checksum, registry):
            self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(), checksum)
            Path(path).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(archive, path)
            return Path(path)

        with mock.patch.object(download, "fetch", side_effect=fetch):
            binaries = installer.python_install(source, destination)
        actual = subprocess.run([str(binaries / "fixture-cli")], capture_output=True, text=True, check=True)
        self.assertEqual(actual.stdout.strip(), "fixture 1.0.0")

    @unittest.skipUnless(shutil.which("npm"), "npm required for native offline integration")
    def test_repeated_setup_reuses_prefix_and_detects_changed_executable(self):
        source, archive = self.npm_fixture()
        manifests = self.work / "manifests"
        shutil.copytree(source, manifests / "fixture")

        def fetch(url, path, checksum, algorithm, registry):
            shutil.copy2(archive, path)
            return Path(path)

        with mock.patch.dict(os.environ, DOTFILES_EDITOR_MANIFEST_DIR=str(manifests), LOCAL_BIN=str(self.home / ".local/bin")), \
                mock.patch.dict(installer.TOOLS, {"fixture": ["fixture-cli"]}), \
                mock.patch("sys.argv", ["installer", "fixture"]), mock.patch.object(download, "fetch", side_effect=fetch) as fetched:
            installer.main()
            path = self.home / ".local/bin/fixture-cli"
            actual = subprocess.run([str(path)], capture_output=True, text=True, check=True)
            self.assertEqual(actual.stdout.strip(), "fixture 1.0.0")
            original = path.resolve()
            fetched.reset_mock()
            installer.main()
            fetched.assert_not_called()
            self.assertEqual(path.resolve(), original)
            original.write_text("#!/bin/sh\necho modified\n")
            with self.assertRaisesRegex(ValueError, "Partial editor"):
                installer.main()
            fetched.assert_not_called()

    def test_all_selected_inputs_are_checked_before_any_install(self):
        source, _ = self.npm_fixture()
        manifests = self.work / "manifests"
        shutil.copytree(source, manifests / "fixture")
        with mock.patch.dict(os.environ, DOTFILES_EDITOR_MANIFEST_DIR=str(manifests)), \
                mock.patch.dict(installer.TOOLS, {"fixture": ["fixture-cli"]}), \
                mock.patch("sys.argv", ["installer", "fixture", "lua"]), mock.patch.object(download, "fetch") as fetched:
            with self.assertRaisesRegex(ValueError, "reviewed manifests"):
                installer.main()
            fetched.assert_not_called()
        self.assertFalse((self.home / ".local").exists())

    def test_bad_artifact_version_preserves_previous_launcher_and_cleans_stage(self):
        source = self.home / ".config/dotfiles/corporate-packages/fixture"
        source.mkdir(parents=True)
        binary = self.work / "wrong-version"
        binary.write_text("#!/bin/sh\necho fixture 2.0.0\n")
        (source / "artifacts.json").write_text(json.dumps([{"tool": "fixture-cli", "version": "1.0.0",
            "url": "https://github.com/org/tool/releases/download/v1/tool", "member": "fixture-cli",
            "sha256": hashlib.sha256(binary.read_bytes()).hexdigest()}]))
        previous = self.home / ".local/bin/fixture-cli"
        previous.parent.mkdir(parents=True)
        previous.write_text("previous")
        with mock.patch.dict(os.environ, LOCAL_BIN=str(previous.parent)), \
                mock.patch.dict(installer.TOOLS, {"fixture": ["fixture-cli"]}), \
                mock.patch("sys.argv", ["installer", "fixture"]), mock.patch.object(download, "fetch", return_value=binary):
            with self.assertRaisesRegex(ValueError, "reviewed version"):
                installer.main()
        self.assertEqual(previous.read_text(), "previous")
        self.assertFalse(list((self.home / ".local/opt/dotfiles-editor").iterdir()))
        self.assertFalse((self.home / ".local/state/dotfiles/editor-tools.pending").exists())

    def test_missing_selected_language_has_no_installation_or_success_marker(self):
        with mock.patch("sys.argv", ["installer", "lua"]):
            with self.assertRaisesRegex(ValueError, "reviewed manifests"):
                installer.main()
        self.assertFalse((self.home / ".local").exists())

    def test_public_registry_configuration_is_rejected(self):
        for url in ["https://registry.npmjs.org", "https://pypi.org/simple", "https://user:secret@internal.invalid/npm", "http://internal.invalid"]:
            with mock.patch.dict(os.environ, DOTFILES_NPM_REGISTRY=url):
                with self.assertRaises(ValueError):
                    download.internal_registry("DOTFILES_NPM_REGISTRY")

    def test_registry_redirect_cannot_forward_credentials_to_another_host(self):
        redirect = download.ApprovedRedirects(self.env["DOTFILES_NPM_REGISTRY"])
        req = urllib.request.Request(self.env["DOTFILES_NPM_REGISTRY"], headers={"Authorization": "Bearer secret"})
        with self.assertRaises(ValueError):
            redirect.redirect_request(req, None, 302, "", {}, "https://other.invalid/package")

    def test_github_redirects_are_bounded(self):
        redirect = download.ApprovedRedirects(None)
        req = urllib.request.Request("https://github.com/org/tool/releases/download/v1/tool")
        with self.assertRaises(ValueError):
            redirect.redirect_request(req, None, 302, "", {}, "https://vendor.invalid/tool")
        self.assertIsNotNone(redirect.redirect_request(req, None, 302, "", {}, "https://release-assets.githubusercontent.com/tool"))

    def test_corrupt_download_preserves_existing_cache(self):
        destination = self.work / "artifact"
        destination.write_bytes(b"previous")
        opener = mock.Mock()
        opener.open.return_value = io.BytesIO(b"corrupt")
        with mock.patch("urllib.request.build_opener", return_value=opener):
            with self.assertRaisesRegex(ValueError, "checksum"):
                download.fetch("https://github.com/org/tool/releases/download/v1/tool", destination,
                               hashlib.sha256(b"expected").hexdigest())
        self.assertEqual(destination.read_bytes(), b"previous")
        self.assertFalse(list(destination.parent.glob("artifact.partial-*")))

    def test_unsupported_architecture_is_rejected_before_sudo(self):
        result = self.shell('source "$1"; uname() { case "$1" in -s) echo Linux;; *) echo aarch64;; esac; }; corporate_platform workstation',
                            ROOT / "scripts/corporate-preflight.sh", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("x86_64", result.stderr)

    def test_wrong_branch_is_rejected(self):
        repo = self.work / "repo"
        subprocess.run(["git", "init", "-q", "--initial-branch=master", str(repo)], check=True)
        result = self.shell('source "$1"; corporate_repository "$2"', ROOT / "scripts/corporate-preflight.sh", repo, success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refusing", result.stderr)

    def test_wrong_upstream_is_rejected_before_snapshot(self):
        repo = self.work / "repo"
        shutil.copytree(ROOT / "scripts", repo / "scripts")
        subprocess.run(["git", "init", "-q", "--initial-branch=environment/corporate", str(repo)], check=True)

        def git(*args):
            subprocess.run(["git", "-C", str(repo), *args], check=True, capture_output=True)

        git("config", "user.name", "Test")
        git("config", "user.email", "test@example.invalid")
        git("add", "scripts")
        git("commit", "-qm", "fixture")
        git("remote", "add", "origin", "https://github.com/HtFilia/dotfiles.git")
        git("update-ref", "refs/remotes/origin/master", "HEAD")
        git("config", "branch.environment/corporate.remote", "origin")
        git("config", "branch.environment/corporate.merge", "refs/heads/master")
        result = subprocess.run([str(repo / "scripts/update-dotfiles.sh")], env=self.env,
                                capture_output=True, text=True, timeout=30)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("different upstream", result.stderr)
        self.assertFalse((self.home / ".local").exists())

    def test_matching_plugin_pin_does_not_fetch(self):
        self.shell('''source "$1"
expected=$(pinned_plugin_field zsh-autosuggestions commit)
mkdir -p "$2/zsh-autosuggestions/.git"
git() { case "$*" in *status*) return 0;; *remote*) pinned_plugin_field zsh-autosuggestions repo;; *rev-parse*) printf '%s\\n' "$expected";; *) echo unexpected-network >&2; return 91;; esac; }
install_pinned_plugin zsh-autosuggestions "$2"
''', ROOT / "scripts/pinned-plugins.sh", self.work / "plugins")

    def test_shell_policy_applies_to_noninteractive_commands(self):
        shutil.copy2(ROOT / "home/dot_zshenv", self.home / ".zshenv")
        result = subprocess.run(["zsh", "-c", 'printf "%s\\n" "$NPM_CONFIG_REGISTRY" "$PIP_EXTRA_INDEX_URL" "$UV_PYTHON_DOWNLOADS" "$GOTOOLCHAIN" "$CARGO_NET_OFFLINE"'],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.stdout.splitlines(), [self.env["DOTFILES_NPM_REGISTRY"], "", "never", "local", "true"])

    def test_archive_traversal_is_rejected_before_activation(self):
        source = self.work / "artifact-source"
        source.mkdir()
        archive = self.work / "bad.tar.gz"
        with tarfile.open(archive, "w:gz") as tar:
            entry = tarfile.TarInfo("../escaped")
            entry.size = 3
            tar.addfile(entry, io.BytesIO(b"bad"))
        manifest = [{"tool": "fixture", "version": "1.0.0", "url": "https://github.com/org/tool/releases/download/v1/tool.tar.gz",
                     "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(), "member": "fixture", "format": "tar.gz"}]
        (source / "artifacts.json").write_text(json.dumps(manifest))
        destination = self.work / "extract"
        destination.mkdir()
        with mock.patch.object(download, "fetch", return_value=archive):
            with self.assertRaises(tarfile.TarError):
                installer.artifacts_install(source, destination)
        self.assertFalse((destination / "escaped").exists())

    def test_unreviewed_vsix_does_not_download(self):
        vsix = module("install-vscode-extensions")
        path = self.work / "vsix.json"
        path.write_text(json.dumps([{"id": "org.extension", "version": "1.0.0"}]))
        with mock.patch("sys.argv", ["vsix"]), mock.patch.dict(os.environ, DOTFILES_VSIX_MANIFEST=str(path)), mock.patch.object(vsix.download, "fetch") as fetched:
            with self.assertRaisesRegex(ValueError, "Review"):
                vsix.main()
            fetched.assert_not_called()

    def test_vsix_dependencies_install_before_dependents(self):
        vsix = module("install-vscode-extensions")
        items = []
        paths = {}
        for name, dependencies in [("parent", ["org.child"]), ("child", [])]:
            path = self.work / (name + ".vsix")
            with zipfile.ZipFile(path, "w") as zipped:
                zipped.writestr("extension/package.json", json.dumps({"publisher": "org", "name": name,
                    "version": "1.0.0", "extensionDependencies": dependencies}))
            url = "https://github.com/org/tool/releases/download/v1/" + path.name
            paths[url] = path
            items.append({"id": "org." + name, "version": "1.0.0", "runtime_reviewed": True,
                          "url": url, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
        manifest = self.work / "vsix.json"
        manifest.write_text(json.dumps(items))
        activated = []

        def code(args, **kwargs):
            if "--install-extension" in args:
                name = Path(args[2]).stem
                if name == "parent":
                    self.assertIn("org.child@1.0.0", activated)
                activated.append("org." + name + "@1.0.0")
            return subprocess.CompletedProcess(args, 0, "\n".join(activated), "")

        with mock.patch("sys.argv", ["vsix"]), mock.patch.dict(os.environ, DOTFILES_VSIX_MANIFEST=str(manifest)), \
                mock.patch.object(vsix.download, "fetch", side_effect=lambda url, *args: paths[url]), \
                mock.patch.object(vsix.subprocess, "run", side_effect=code):
            vsix.main()
        self.assertEqual(activated, ["org.child@1.0.0", "org.parent@1.0.0"])

    def test_binary_backup_does_not_follow_previous_symlink(self):
        destination = self.work / "bin/tool"
        destination.parent.mkdir()
        destination.write_text("old")
        outside = self.work / "untouched"
        outside.write_text("untouched")
        destination.with_name("tool.previous").symlink_to(outside)
        source = self.work / "new"
        source.write_text("new")
        self.shell('source "$1"; atomic_install_binary "$2" "$3"', ROOT / "scripts/pinned-assets.sh", source, destination)
        self.assertEqual(destination.read_text(), "new")
        self.assertEqual(destination.with_name("tool.previous").read_text(), "old")
        self.assertEqual(outside.read_text(), "untouched")

    @unittest.skipUnless(shutil.which("nvim"), "Neovim required")
    def test_missing_editor_plugins_fail_without_clone_on_startup(self):
        env = dict(self.env, XDG_DATA_HOME=str(self.home / ".local/share"), XDG_CONFIG_HOME=str(self.home / ".config"),
                   XDG_STATE_HOME=str(self.home / ".local/state"), XDG_CACHE_HOME=str(self.home / ".cache"))
        env.pop("DOTFILES_EDITOR_PROVISION", None)
        result = subprocess.run(["nvim", "--headless", "-u", str(ROOT / "home/dot_config/nvim/init.lua"), "+qa"],
                                env=env, capture_output=True, text=True, timeout=30)
        self.assertIn("plugins are missing", result.stderr)
        self.assertFalse((self.home / ".local/share/nvim/lazy/lazy.nvim").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
