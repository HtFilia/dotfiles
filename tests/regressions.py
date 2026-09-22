"""Offline behavioral checks. All mutable state is confined to temporary homes."""
import json
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
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

    def apply(self, *args):
        return self.run_command(str(ROOT / "scripts/apply-dotfiles.sh"), *args)

    def function(self, name):
        lines = (ROOT / "home/dot_zshrc").read_text().splitlines()
        start = next(i for i, line in enumerate(lines) if line.startswith(name + "()"))
        if lines[start].endswith("}"):
            return lines[start]
        end = lines.index("}", start)
        return "\n".join(lines[start:end + 1])

    def test_cli_validation(self):
        for script in (ROOT / "scripts").glob("*.sh"):
            if script.name in {"pinned-assets.sh", "pinned-plugins.sh", "preflight.sh", "profile.sh", "server-packages.sh", "asset-manifest.sh"}:
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
                self.assertEqual((local_bin / binary).resolve(), runtime / binary)

    def test_retired_binary_is_backed_up_without_execution(self):
        scripts = self.work / "scripts"
        scripts.mkdir()
        shutil.copy2(ROOT / "scripts/retire-dotfiles.py", scripts)
        binary = self.home / ".local/bin/tmux"
        binary.parent.mkdir(parents=True)
        payload = b"old compiled executable fixture"
        binary.write_bytes(payload)
        (scripts / "retired-files.json").write_text(json.dumps([{
            "target": ".local/bin/tmux", "sha256": [hashlib.sha256(payload).hexdigest()]}]))
        self.run_command("python3", str(scripts / "retire-dotfiles.py"), "--destination", str(self.home),
                         "--source", str(ROOT / "home"), "--profile", "workstation")
        self.assertFalse(binary.exists())
        backup = next((self.home / ".local/state/dotfiles/backups").glob("retired-*"))
        with tarfile.open(backup / "contents.tar") as archive:
            self.assertEqual(archive.extractfile(".local/bin/tmux").read(), payload)

    def test_profile_retirement_backs_up_and_restores(self):
        target = self.home / ".config/ghostty/config.ghostty"
        target.parent.mkdir(parents=True)
        original = (ROOT / "home/dot_config/ghostty/config.ghostty").read_bytes()
        target.write_bytes(original)
        self.apply("--profile", "server", "--dry-run")
        self.assertEqual(target.read_bytes(), original)
        self.assertFalse((self.home / ".local/state/dotfiles/backups").exists())
        self.apply("--profile", "server", "--force")
        self.assertFalse(target.exists())
        backups = list((self.home / ".local/state/dotfiles/backups").glob("retired-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o700)
        self.assertEqual((backups[0] / "contents.tar").stat().st_mode & 0o777, 0o600)
        self.apply("--profile", "server")
        self.assertEqual(len(list(backups[0].parent.glob("retired-*"))), 1)
        self.run_command(str(ROOT / "scripts/restore-dotfiles.sh"), str(backups[0]), str(self.home))
        self.assertEqual(target.read_bytes(), original)

    def test_retirement_preserves_modified_and_unknown_targets(self):
        target = self.home / ".config/ghostty/config.ghostty"
        target.parent.mkdir(parents=True)
        target.write_text("custom config\n")
        result = self.run_command(str(ROOT / "scripts/apply-dotfiles.sh"), "--profile", "server", success=False)
        self.assertEqual(result.returncode, 2)
        self.assertIn("Unresolved cleanup", result.stderr)
        self.assertEqual(target.read_text(), "custom config\n")
        target.unlink()
        unknown = self.work / "unknown"
        shutil.copy2(ROOT / "home/dot_config/ghostty/config.ghostty", unknown)
        target.symlink_to(unknown)
        result = self.run_command(str(ROOT / "scripts/apply-dotfiles.sh"), "--profile", "server", success=False)
        self.assertEqual(result.returncode, 2)
        self.assertTrue(target.is_symlink())

    def test_retirement_handles_old_checkout_dangling_links(self):
        target = self.home / ".config/ghostty/config.ghostty"
        target.parent.mkdir(parents=True)
        old = self.work / "moved-checkout"
        target.symlink_to(old / "home/dot_config/ghostty/config.ghostty")
        state = self.home / ".local/state/dotfiles"
        state.mkdir(parents=True)
        (state / "source").write_text(str(old) + "\n")
        self.apply("--profile", "server")
        self.assertFalse(target.is_symlink())
        backup = next((state / "backups").glob("retired-*"))
        with tarfile.open(backup / "targets.tar") as archive:
            self.assertTrue(archive.getmember(".config/ghostty/config.ghostty").issym())

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
        state = self.home / ".local/state/dotfiles"
        state.mkdir(parents=True)
        env = dict(self.env, PATH=str(binaries) + ":/usr/bin:/bin", CALLS=str(log), TEST_OS="Linux")
        (state / "profile").write_text("server\n")
        self.run_command("bash", str(scripts / "update-tools.sh"), "--skip-packages", env=env)
        self.assertEqual(log.read_text(), "install-server.sh --skip-packages\n")
        log.unlink()
        (state / "profile").write_text("workstation\n")
        env["WSL_DISTRO_NAME"] = "Debian"
        self.run_command("bash", str(scripts / "update-tools.sh"), "--skip-packages", "--skip-docker", env=env)
        calls = log.read_text()
        self.assertIn("install-debian.sh wsl --skip-packages --skip-docker", calls)
        self.assertNotIn("sudo", calls)
        log.unlink()
        env["TEST_OS"] = "Darwin"
        self.run_command("bash", str(scripts / "update-tools.sh"), "--skip-packages", env=env)
        self.assertFalse(log.exists())
        self.run_command("bash", str(scripts / "update-tools.sh"), "--skip-fonts", "--skip-docker", env=env)
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

    def test_dry_run_has_no_destination_writes(self):
        destination = self.work / "dry"
        self.apply("--destination", str(destination), "--dry-run")
        self.assertFalse(destination.exists())

    def test_profile_and_materialization_persist(self):
        self.apply("--destination", str(self.home), "--profile", "server", "--force")
        self.assertFalse((self.home / ".zshrc").is_symlink())
        self.assertFalse((self.home / ".config/Code").exists())
        self.assertFalse((self.home / ".local/bin/dotfiles-deck").exists())
        self.assertFalse((self.home / ".local/share/dotfiles/workbooks").exists())
        self.assertFalse((self.home / ".config/dotfiles/windows-terminal.json").exists())
        self.assertFalse((self.home / ".config/dotfiles/shaders").exists())
        self.assertFalse((self.home / ".config/dotfiles/styles/operator/ghostty.conf").exists())
        self.apply("--destination", str(self.home))
        self.assertFalse((self.home / ".config/Code").exists())
        self.assertEqual((self.home / ".local/state/dotfiles/profile").read_text().strip(), "server")
        self.assertEqual((self.home / ".local/state/dotfiles/source").read_text().strip(), str(ROOT))

    def test_profile_update_preview_never_uses_workstation_installer(self):
        state = self.home / ".local/state/dotfiles"
        state.mkdir(parents=True)
        (state / "profile").write_text("server\n")
        (state / "editor-languages").write_text("python shell\n")
        if os.uname().sysname == "Darwin":
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--dry-run", success=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Server profile requires Linux", result.stderr)
            self.assertNotIn("would run:", result.stdout)
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "workstation", "--dry-run")
            self.assertIn("install-macos.sh", result.stdout)
            self.assertNotIn("install-server.sh", result.stdout)
        else:
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--skip-packages", "--dry-run")
            self.assertIn("install-server.sh --skip-packages --editor-languages python\\,shell", result.stdout)
            self.assertIn("setup-editor.sh python shell", result.stdout)
            self.assertNotIn("sudo", result.stdout)
            self.assertNotIn("install-debian.sh", result.stdout)
            result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--profile", "workstation", "--skip-packages", "--dry-run")
            self.assertIn("install-debian.sh", result.stdout)
        (state / "profile").write_text("broken\n")
        result = self.run_command(str(ROOT / "scripts/update-tools.sh"), "--dry-run", success=False)
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

    def test_local_git_and_ssh_overrides(self):
        self.apply("--destination", str(self.home), "--profile", "server")
        local = self.home / ".gitconfig.local"
        self.run_command("git", "config", "--file", str(local), "user.name", "Local Person")
        name = self.run_command("git", "config", "--includes", "--file", str(self.home / ".gitconfig"), "user.name")
        self.assertEqual(name.stdout.strip(), "Local Person")
        ssh_local = self.home / ".ssh/config.local"
        ssh_local.write_text("Host audit-alias\n  HostName 192.0.2.1\n  User audit-user\n")
        config = self.home / ".ssh/config"
        config.write_text(config.read_text().replace("~/.ssh/config.local", str(ssh_local)))
        options = self.run_command("ssh", "-G", "-F", str(config), "audit-alias").stdout
        self.assertIn("hostname 192.0.2.1\n", options)
        self.assertIn("user audit-user\n", options)

    def test_atuin_policy_is_deployed(self):
        self.apply("--destination", str(self.home), "--profile", "server")
        import tomllib
        policy = tomllib.loads((self.home / ".config/atuin/config.toml").read_text())
        self.assertEqual({key: policy[key] for key in ("auto_sync", "update_check", "enter_accept")},
                         {"auto_sync": False, "update_check": False, "enter_accept": False})

    def test_apply_repairs_plugin_parent_permissions(self):
        parent = self.home / ".local/share/zsh/plugins"
        parent.mkdir(parents=True)
        for path in [self.home / ".local", self.home / ".local/share", self.home / ".local/share/zsh", parent]:
            path.chmod(0o775)
        self.apply("--destination", str(self.home), "--profile", "server")
        for path in [self.home / ".local", self.home / ".local/share", self.home / ".local/share/zsh", parent]:
            self.assertFalse(path.stat().st_mode & 0o022, str(path))

    def test_link_and_content_backups(self):
        source = self.work / "source"
        shutil.copytree(ROOT / "home", source)
        original = self.work / "original"
        original.write_text("original contents\n")
        (self.home / ".zshrc").symlink_to(original)
        self.apply("--source", str(source), "--destination", str(self.home), "--profile", "server", "--force")
        backups = list((self.home / ".local/state/dotfiles/backups").glob("*"))
        with tarfile.open(backups[0] / "targets.tar") as archive:
            self.assertTrue(archive.getmember(".zshrc").issym())
        with tarfile.open(backups[0] / "contents.tar") as archive:
            self.assertEqual(archive.extractfile(".zshrc").read(), b"original contents\n")
        original.write_text("changed\n")
        self.run_command(str(ROOT / "scripts/restore-dotfiles.sh"), str(backups[0]), str(self.home))
        self.assertEqual((self.home / ".zshrc").read_text(), "original contents\n")

    def test_identity_roundtrip(self):
        self.env.update(DOTFILES_GIT_NAME='A "Name" # comment', DOTFILES_GIT_EMAIL="a@example.com")
        self.apply("--destination", str(self.home), "--profile", "server")
        result = self.run_command("git", "config", "--file", str(self.home / ".gitconfig.local"), "user.name")
        self.assertEqual(result.stdout.strip(), self.env["DOTFILES_GIT_NAME"])
        self.assertEqual((self.home / ".gitconfig.local").stat().st_mode & 0o777, 0o600)

    def test_effective_identity_survives_migration(self):
        (self.home / ".gitconfig").write_text('[user]\n name = Existing User\n email = existing@example.com\n')
        self.apply("--profile", "server", "--force")
        result = self.run_command("git", "config", "--file", str(self.home / ".gitconfig"), "--includes", "user.name")
        self.assertEqual(result.stdout.strip(), "Existing User")
        (self.home / ".gitconfig.local").write_text('[user]\n name = Local Override\n email = local@example.com\n')
        self.apply("--profile", "server", "--force")
        result = self.run_command("git", "config", "--file", str(self.home / ".gitconfig"), "--includes", "user.name")
        self.assertEqual(result.stdout.strip(), "Local Override")

    def test_symlink_identity_survives_post_pull_migration(self):
        (self.home / ".gitconfig").symlink_to(ROOT / "home/dot_gitconfig")
        self.apply("--profile", "server", "--force")
        result = self.run_command("git", "config", "--file", str(self.home / ".gitconfig"), "--includes", "user.email")
        self.assertEqual(result.stdout.strip(), "contact@lucaslebihan.dev")

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

    @unittest.skipUnless(os.uname().sysname == "Linux", "server bootstrap requires Linux")
    def test_bootstrap_sees_child_installed_tools(self):
        fixture = self.work / "repository"
        shutil.copytree(ROOT / "scripts", fixture / "scripts")
        (fixture / "home").mkdir()
        (fixture / "home/dot_zshrc").write_text("# fixture")
        (fixture / "scripts/preflight.sh").write_text("preflight_linux() { return 0; }\n")
        (fixture / "scripts/install-server.sh").write_text('mkdir -p "$HOME/.local/bin"\nprintf "#!/bin/sh\\nexit 0\\n" >"$HOME/.local/bin/chezmoi"\nchmod +x "$HOME/.local/bin/chezmoi"\n')
        (fixture / "scripts/apply-dotfiles.sh").write_text('#!/bin/sh\ncommand -v chezmoi >"$HOME/found"\n')
        self.env.update(PATH="/usr/bin:/bin", SHELL="/bin/bash")
        self.run_command("bash", str(fixture / "scripts/bootstrap.sh"), "--yes", "--profile", "server", "--no-shell-plugins")
        self.assertEqual((self.home / "found").read_text().strip(), str(self.home / ".local/bin/chezmoi"))

    def test_verification_fails_when_required_tools_missing(self):
        result = self.run_command(str(ROOT / "scripts/verify.sh"), "--profile", "server", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("verification failure", result.stdout)

    def test_verification_detects_managed_server_drift(self):
        self.apply("--destination", str(self.home), "--profile", "server", "--force")
        result = self.run_command(str(ROOT / "scripts/verify.sh"), "--profile", "server", success=False)
        self.assertIn("ok - all managed server files match source", result.stdout)
        (self.home / ".config/ripgrep/config").write_text("--hidden\n")
        result = self.run_command(str(ROOT / "scripts/verify.sh"), "--profile", "server", success=False)
        self.assertIn("FAIL - all managed server files match source", result.stderr)

    def test_existing_ssh_identity_is_preserved(self):
        ssh = self.home / ".ssh"
        ssh.mkdir(mode=0o700)
        (ssh / "config").write_text("Host github.com\n  IdentityFile ~/.ssh/personal-key\n")
        self.apply("--destination", str(self.home), "--profile", "server", "--force")
        self.assertIn("personal-key", (ssh / "config.local").read_text())
        managed = (ssh / "config").read_text()
        self.assertIn("Host github.com", managed)
        self.assertIn("IdentityFile ~/.ssh/github", managed)
        self.assertIn("IdentitiesOnly yes", managed)
        self.assertIn("IdentityAgent none", managed)
        self.assertIn("Include ~/.ssh/config.local", managed)
        rewrites = self.run_command(
            "git", "config", "--file", str(self.home / ".gitconfig"),
            "--get-all", "url.git@github.com:.insteadOf",
        ).stdout.splitlines()
        self.assertEqual(set(rewrites), {"https://github.com/", "http://github.com/", "git://github.com/"})

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

    def test_mac_native_settings_target(self):
        if os.uname().sysname != "Darwin":
            self.skipTest("native macOS routing is covered on macOS CI")
        self.apply("--destination", str(self.home), "--profile", "workstation")
        native = self.home / "Library/Application Support/Code/User/settings.json"
        self.assertEqual(native.resolve(), (ROOT / "home/dot_config/Code/User/settings.json").resolve())
        self.assertFalse((self.home / ".config/Code").exists())

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

    def test_operator_is_native_without_style_initialization(self):
        self.apply("--profile", "workstation")
        self.assertIn("142727", (self.home / ".config/ghostty/config.ghostty").read_text())
        self.assertIn("142727", (self.home / ".tmux.conf").read_text())
        self.assertNotIn("DOTFILES_STYLE", (self.home / ".zshrc").read_text())
        self.assertFalse((self.home / ".config/dotfiles/style").exists())

    def test_generated_style_cleanup_and_unknown_preservation(self):
        root = self.home / ".config/dotfiles"
        root.mkdir(parents=True)
        (root / "style").write_text("operator\n")
        (root / "ghostty-style.conf").write_text('# Use the managed Gruvbox theme.\ncustom-shader = "' + str(root / 'shaders/scanlines.glsl') + '"\ncustom-shader-animation = false\n')
        (root / "tmux-style.conf").write_text("custom settings\n")
        result = self.run_command(str(ROOT / "scripts/apply-dotfiles.sh"), "--profile", "workstation", success=False)
        self.assertEqual(result.returncode, 2)
        self.assertFalse((root / "style").exists())
        self.assertFalse((root / "ghostty-style.conf").exists())
        self.assertEqual((root / "tmux-style.conf").read_text(), "custom settings\n")

    def test_windows_style_preserves_other_profiles_and_creates_backup(self):
        config = {"profiles": {"list": [
            {"name": "Debian", "source": "Microsoft.WSL", "font": {"face": "My Font"}},
            {"name": "PowerShell", "colorScheme": "Existing"}]}, "defaultProfile": "unchanged"}
        path = self.work / "settings.json"
        path.write_text(json.dumps(config))
        self.run_command("python3", str(ROOT / "scripts/setup-windows-terminal.py"), str(path), "--profile", "Debian")
        result = json.loads(path.read_text())
        self.assertEqual(result["profiles"]["list"][1], config["profiles"]["list"][1])
        self.assertEqual(result["profiles"]["list"][0]["font"], {"face": "My Font"})
        self.assertEqual(result["defaultProfile"], "unchanged")
        backups = list(self.work.glob("settings.dotfiles-backup-*.json"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(json.loads(backups[0].read_text()), config)


if __name__ == "__main__":
    unittest.main(verbosity=2)
