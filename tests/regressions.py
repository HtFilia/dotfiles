"""Offline behavioral checks. All mutable state is confined to temporary homes."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Contracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-tests-")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.home = self.work / "home"
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), DOTFILES_PROFILE="",
                        GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1",
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_DATA_HOME=str(self.home / ".local/share"),
                        XDG_STATE_HOME=str(self.home / ".local/state"),
                        XDG_CACHE_HOME=str(self.home / ".cache"))
        for key in list(self.env):
            if key.startswith("DOTFILES_") and key != "DOTFILES_PROFILE":
                del self.env[key]
        self.env["PATH"] = str(Path(shutil.which("chezmoi")).parent) + ":" + self.env["PATH"]

    def run_command(self, *args, cwd=None, env=None, success=True):
        result = subprocess.run(args, cwd=cwd or ROOT, env=env or self.env,
                                text=True, capture_output=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def function(self, name):
        lines = (ROOT / "home/dot_zshrc").read_text().splitlines()
        start = next(i for i, line in enumerate(lines) if line.startswith(name + "()"))
        if lines[start].endswith("}"):
            return lines[start]
        end = lines.index("}", start)
        return "\n".join(lines[start:end + 1])

    def test_cli_validation(self):
        for script in (ROOT / "scripts").glob("*.sh"):
            if script.name in {"pinned-assets.sh", "pinned-plugins.sh", "preflight.sh", "server-packages.sh", "asset-manifest.sh"}:
                continue
            self.run_command(str(script), "--help")
        result = self.run_command(str(ROOT / "scripts/bootstrap.sh"), "--profile", "invalid", "--yes", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unknown profile", result.stderr)

    def test_node_launchers_repair_without_download_when_runtime_exists(self):
        local_bin = self.home / ".local/bin"
        local_bin.mkdir(parents=True)
        runtime = self.home / ".local/opt/node-vfixture/bin"
        runtime.mkdir(parents=True)
        for binary in ("node", "npm", "npx"):
            target = runtime / binary
            target.write_text("#!/bin/sh\nprintf fixture\\\\n\n")
            target.chmod(0o755)
        (local_bin / "node").symlink_to(self.work / "missing")
        for installer in ("install-debian.sh", "install-server.sh"):
            source = (ROOT / "scripts" / installer).read_text()
            functions = source[source.index("install_runtime() {"):source.index('\nif [[ -f /etc/os-release') if installer == "install-debian.sh" else source.index('\ncommand -v fdfind')]
            script = 'pinned_asset_field() { echo vfixture; }; cached_asset_path() { return 99; }; fatal() { exit 1; }; ARCH=x86_64; SKIP_PACKAGES=1\n' + functions + '\ninstall_node; install_node'
            self.run_command("bash", "-euc", script, env=dict(self.env, LOCAL_BIN=str(local_bin)))
            for binary in ("node", "npm", "npx"):
                self.assertEqual((local_bin / binary).resolve(), (runtime / binary).resolve())

    def test_tool_update_dispatch_and_package_boundaries(self):
        scripts = self.work / "scripts"
        shutil.copytree(ROOT / "scripts", scripts)
        (scripts / "preflight.sh").write_text("preflight_linux() { :; }\n")
        binaries = self.work / "bin"
        binaries.mkdir()
        log = self.work / "calls"
        def stub(path, body):
            path.write_text("#!/bin/sh\n" + body + "\n")
            path.chmod(0o755)
        for name in ("sudo", "rustup", "uv"):
            stub(binaries / name, 'printf "%s %s\\n" "' + name + '" "$*" >> "$CALLS"')
        for name in ("install-debian.sh", "install-server.sh", "install-macos.sh"):
            stub(scripts / name, 'printf "%s %s\\n" "' + name + '" "$*" >> "$CALLS"')
        stub(binaries / "uname", 'printf "%s\\n" "$TEST_OS"')
        env = dict(self.env, PATH=str(binaries) + ":/usr/bin:/bin", CALLS=str(log), TEST_OS="Linux")
        self.run_command("bash", str(scripts / "update-tools.sh"), "--profile", "server", "--skip-packages", env=env)
        self.assertEqual(log.read_text(), "install-server.sh --skip-packages\n")
        log.unlink()
        self.run_command("bash", str(scripts / "update-tools.sh"), "--profile", "workstation", "--skip-packages", "--skip-docker", env=env)
        calls = log.read_text()
        self.assertIn("install-debian.sh --skip-packages --skip-docker", calls)
        self.assertNotIn("sudo", calls)
        log.unlink()
        env["TEST_OS"] = "Darwin"
        self.run_command("bash", str(scripts / "update-tools.sh"), "--profile", "workstation", "--skip-packages", env=env)
        self.assertFalse(log.exists())
        self.run_command("bash", str(scripts / "update-tools.sh"), "--profile", "workstation", "--skip-fonts", "--skip-docker", env=env)
        self.assertEqual(log.read_text(), "install-macos.sh --skip-fonts --skip-docker\n")

    def test_server_fallback_preserves_existing_launchers(self):
        source = (ROOT / "scripts/install-server.sh").read_text()
        functions = source[source.index("install_go() {"):source.index('\ncommand -v fdfind')]
        local_bin = self.home / ".local/bin"
        local_bin.mkdir(parents=True)
        for tool in ("go", "node", "npm"):
            executable = local_bin / tool
            executable.write_text("#!/bin/sh\necho fixture\n")
            executable.chmod(0o755)
        script = 'install_runtime() { return 1; }; warn() { :; }; SKIP_PACKAGES=1; ARCH=x86_64; GO_ARCH=amd64\n' + functions + '\ninstall_go || true; install_node || true'
        env = dict(self.env, LOCAL_BIN=str(local_bin), PATH=str(local_bin) + ":/usr/bin:/bin")
        self.run_command("bash", "-euc", script, env=env)
        for tool in ("go", "node", "npm"):
            self.assertFalse((local_bin / tool).is_symlink())

    def test_bootstrap_requires_complete_checkout(self):
        script = self.work / "bootstrap.sh"
        shutil.copy2(ROOT / "scripts/bootstrap.sh", script)
        result = self.run_command("bash", str(script), "--yes", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("complete dotfiles checkout", result.stderr)

    def test_profile_update_preview_never_uses_workstation_installer(self):
        state = self.home / ".local/state/dotfiles"
        state.mkdir(parents=True)
        (state / "editor-languages").write_text("python shell\n")
        if os.uname().sysname == "Darwin":
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "server", "--dry-run", success=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Server profile requires Linux", result.stderr)
            self.assertNotIn("would run:", result.stdout)
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "workstation", "--dry-run")
            self.assertIn("install-macos.sh", result.stdout)
            self.assertNotIn("install-server.sh", result.stdout)
        else:
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "server", "--skip-packages", "--dry-run")
            self.assertIn("install-server.sh --skip-packages --editor-languages python\\,shell", result.stdout)
            self.assertIn("setup-editor.sh python shell", result.stdout)
            self.assertNotIn("sudo", result.stdout)
            self.assertNotIn("install-debian.sh", result.stdout)
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "workstation", "--skip-packages", "--dry-run")
            self.assertIn("install-debian.sh", result.stdout)
        result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "broken", "--dry-run", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("would run:", result.stdout)

    @unittest.skipUnless(os.uname().sysname == "Linux", "server installer requires Linux")
    def test_server_editor_prerequisites_are_selected_by_language(self):
        script = 'source "$1"; dotfiles_server_editor_packages python shell'
        result = self.run_command("bash", "-euc", script, "_", str(ROOT / "scripts/server-packages.sh"))
        self.assertEqual(result.stdout.splitlines(), ["build-essential", "python3", "python3-venv"])
        result = self.run_command("bash", "-euc", 'source "$1"; dotfiles_server_editor_packages go',
                                  "_", str(ROOT / "scripts/server-packages.sh"))
        self.assertEqual(result.stdout.splitlines(), ["build-essential"])

    @unittest.skipUnless(os.uname().sysname == "Linux", "server baseline requires Linux")
    def test_server_baseline_preview_is_read_only(self):
        if "VERSION_CODENAME=trixie" not in Path("/etc/os-release").read_text():
            self.skipTest("Debian 13 baseline")
        fake_bin = self.work / "bin"
        fake_bin.mkdir()
        fake_sudo = fake_bin / "sudo"
        fake_sudo.write_text("#!/bin/sh\necho unexpected-sudo >&2\nexit 99\n")
        fake_sudo.chmod(0o755)
        self.env["PATH"] = str(fake_bin) + ":" + self.env["PATH"]
        result = self.run_command(str(ROOT / "scripts/server-baseline.sh"), "--dry-run")
        self.assertIn("journal retention", result.stdout)
        self.assertNotIn("unexpected-sudo", result.stderr)

    @unittest.skipUnless(os.uname().sysname == "Linux", "Linux updater")
    def test_invalid_editor_state_stops_before_package_actions(self):
        state = self.home / ".local/state/dotfiles"
        state.mkdir(parents=True)
        (state / "editor-languages").write_text("unknown-language\n")
        result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "server", "--dry-run", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unknown editor language", result.stderr)
        self.assertNotIn("apt-get", result.stdout)

    def test_fga_handles_spaces_and_dashes(self):
        self.run_command("git", "init", "-q", str(self.work))
        for name in ["space name.txt", "-leading.txt", "colon:name.txt"]:
            (self.work / name).write_text("needle\n")
        script = self.function("fga") + "\nfzf() { cat; }\nfga"
        self.run_command("zsh", "-fc", script, cwd=self.work)
        result = self.run_command("git", "diff", "--cached", "--name-only", "-z", cwd=self.work)
        self.assertEqual(set(result.stdout.split("\0")[:-1]), {"space name.txt", "-leading.txt", "colon:name.txt"})

    def test_fga_cancellation_does_not_stage(self):
        self.run_command("git", "init", "-q", str(self.work))
        (self.work / "file.txt").write_text("needle\n")
        self.run_command("zsh", "-fc", self.function("fga") + "\nfzf() { return 130; }\nfga", cwd=self.work, success=False)
        self.assertEqual(self.run_command("git", "diff", "--cached", "--name-only", cwd=self.work).stdout, "")

    def test_frg_keeps_filename_and_line_plain(self):
        (self.work / "space:name.txt").write_text("needle\n")
        output = self.work / "arguments.json"
        editor = self.work / "editor"
        editor.write_text("#!/usr/bin/env python3\nimport json,sys\njson.dump(sys.argv[1:],open(" + repr(str(output)) + ", 'w'))\n")
        editor.chmod(0o755)
        self.env["EDITOR"] = str(editor)
        script = self.function("frg") + "\nfzf() { sed -n '1p'; }\nfrg needle"
        self.run_command("zsh", "-fc", script, cwd=self.work)
        self.assertEqual(json.loads(output.read_text()), ["+1", "--", "./space:name.txt"])

    def test_git_metadata_not_ignored(self):
        self.run_command("git", "init", "-q", str(self.work))
        result = self.run_command("git", "-c", "core.excludesFile=" + str(ROOT / "home/dot_config/git/ignore"),
                                  "check-ignore", "Cargo.lock", ".python-version", ".vscode/tasks.json", "vendor/code.go",
                                  cwd=self.work, success=False)
        self.assertEqual(result.returncode, 1)
        self.run_command("git", "config", "--file", str(ROOT / "home/dot_gitconfig"), "--list")

    def test_plugin_errors_propagate_in_conditionals(self):
        script = '''source "$1"
expected=$(pinned_plugin_field zsh-autosuggestions commit)
git() { case "$*" in *rev-parse*) printf '%s\\n' "$expected";; *status*) return 0;; *) return 1;; esac; }
mkdir -p "$2/zsh-autosuggestions/.git"
if install_pinned_plugin zsh-autosuggestions "$2"; then exit 1; fi
'''
        self.run_command("bash", "-euc", script, "_", str(ROOT / "scripts/pinned-plugins.sh"), str(self.work / "plugins"))

    def test_verification_fails_when_required_tools_missing(self):
        result = self.run_command(str(ROOT / "scripts/verify.sh"), "--profile", "server", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("verification failure", result.stdout)

    def test_cache_is_versioned_and_replaces_corruption(self):
        script = r'''source "$1"
pinned_asset_field() {
  case "$2" in version) printf '%s\n' "$fixture_version";; file) printf 'same.tar.gz\n';; esac
}
require_pinned_file() { [[ -f "$2/same.tar.gz" && "$(cat "$2/same.tar.gz")" == verified ]]; }
download_pinned_asset() { mkdir -p "$2"; printf verified >"$2/same.tar.gz"; }
fixture_version=v1
first=$(cached_asset_path tool "$2")
[[ "$first" == "$2/tool/v1/same.tar.gz" ]] || exit 1
printf corrupt >"$first"
[[ "$(cat "$(cached_asset_path tool "$2")")" == verified ]] || exit 1
fixture_version=v2
second=$(cached_asset_path tool "$2")
[[ "$second" == "$2/tool/v2/same.tar.gz" && -f "$first" ]] || exit 1
'''
        self.run_command("bash", "-euc", script, "_", str(ROOT / "scripts/pinned-assets.sh"), str(self.work / "cache"))

    def test_mergetool_quotes_path_arguments(self):
        result = self.run_command("git", "config", "--file", str(ROOT / "home/dot_gitconfig"), "mergetool.nvim.cmd")
        script = "nvim() { printf '%s\\n' \"$@\"; }\n" + result.stdout
        self.env.update(LOCAL="local file", REMOTE="remote file", MERGED="merged file")
        output = self.run_command("sh", "-c", script)
        self.assertEqual(output.stdout.splitlines()[:4], ["-d", "local file", "remote file", "merged file"])

    def test_inventory_matches_manifest(self):
        result = self.run_command(str(ROOT / "scripts/asset-manifest.sh"))
        self.assertEqual(result.stdout, (ROOT / "docs/ASSET-MANIFEST.md").read_text())

    def test_binary_upgrade_replaces_symlink_without_overwriting_system_target(self):
        original = self.work / "system-binary"
        original.write_text("original")
        link = self.work / "tool"
        link.symlink_to(original)
        replacement = self.work / "replacement"
        replacement.write_text("updated")
        self.run_command("bash", "-euc", 'source "$1"; atomic_install_binary "$2" "$3"',
                         "_", str(ROOT / "scripts/pinned-assets.sh"), str(replacement), str(link))
        self.assertEqual(original.read_text(), "original")
        self.assertFalse(link.is_symlink())
        self.assertEqual(link.read_text(), "updated")


if __name__ == "__main__":
    unittest.main(verbosity=2)
