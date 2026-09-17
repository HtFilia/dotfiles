"""Offline behavioral checks. All mutable state is confined to temporary homes."""
import json
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
            if script.name in {"pinned-assets.sh", "pinned-plugins.sh", "preflight.sh", "asset-manifest.sh"}:
                continue
            self.run_command(str(script), "--help")
        result = self.run_command(str(ROOT / "scripts/bootstrap.sh"), "--profile", "invalid", "--yes", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unknown profile", result.stderr)

    def test_dry_run_has_no_destination_writes(self):
        destination = self.work / "dry"
        self.apply("--destination", str(destination), "--dry-run")
        self.assertFalse(destination.exists())

    def test_profile_and_materialization_persist(self):
        self.apply("--destination", str(self.home), "--profile", "server", "--force")
        self.assertFalse((self.home / ".zshrc").is_symlink())
        self.assertFalse((self.home / ".config/Code").exists())
        self.apply("--destination", str(self.home))
        self.assertFalse((self.home / ".config/Code").exists())
        self.assertEqual((self.home / ".local/state/dotfiles/profile").read_text().strip(), "server")

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

    def test_existing_ssh_identity_is_preserved(self):
        ssh = self.home / ".ssh"
        ssh.mkdir(mode=0o700)
        (ssh / "config").write_text("Host github.com\n  IdentityFile ~/.ssh/personal-key\n")
        self.apply("--destination", str(self.home), "--profile", "server", "--force")
        self.assertIn("personal-key", (ssh / "config.local").read_text())
        self.assertIn("Include ~/.ssh/config.local", (ssh / "config").read_text())

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

    def test_visual_switch_does_not_edit_managed_source(self):
        self.apply("--destination", str(self.home), "--profile", "workstation")
        script = str(ROOT / "home/dot_local/bin/executable_dotfiles-style")
        source = ROOT / "home/dot_config/dotfiles/styles/operator/tmux.conf"
        before = source.read_text()
        self.run_command("python3", script, "operator", "--crt")
        self.assertIn("custom-shader", (self.home / ".config/dotfiles/ghostty-style.conf").read_text())
        self.run_command("python3", script, "classic")
        self.assertNotIn("custom-shader =", (self.home / ".config/dotfiles/ghostty-style.conf").read_text())
        self.assertEqual(source.read_text(), before)

    def test_workbooks_reject_noninteractive_menu(self):
        script = str(ROOT / "home/dot_local/share/dotfiles/workbooks/lab.py")
        result = self.run_command("python3", script, "--list")
        self.assertIn("archives", result.stdout)
        result = self.run_command("python3", script, success=False)
        self.assertEqual(result.returncode, 2)
        self.assertIn("needs a terminal", result.stderr)

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
