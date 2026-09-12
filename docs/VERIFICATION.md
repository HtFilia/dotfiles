# Verification and maintenance

## Offline repository checks

```sh
just check
just dry-run
```

`check` parses every Bash/Zsh file, runs ShellCheck, and runs Python behavioral
regressions with temporary homes. Tests cover deployment modes, persistent
profiles, no-write previews, backups, Git identity escaping, filename-safe fuzzy
helpers, plugin errors, and fresh-bootstrap PATH. They do not install packages
or download editor tools. Python 3, Zsh, ShellCheck, and Chezmoi must be installed.

CI runs these checks on Linux and macOS, lints workflows with actionlint, checks
the generated asset inventory, and scans full Git history with redacted gitleaks
output. Package installers and interactive GUI behavior are not fully exercised
by offline CI.

`.gitleaks.toml` extends all built-in detection rules. Its only exception requires
both the historical VS Code keybindings path and the literal `shift+alt+down`
keyboard shortcut to match the generic API key rule. Full history remains scanned,
including deleted files; other values in that file still receive normal checks.
To investigate a failure, run `gitleaks git --redact --no-banner --verbose` and
inspect the rule, path, commit, and fingerprint before adding an exception.

## Machine acceptance

```sh
./scripts/verify.sh
./scripts/verify.sh --profile server
```

The saved profile determines required tools and deployed leaf files. Linux
upstream binary pins are compared as complete version tokens. Existing plugins
must match pins and have clean working trees. Verification returns nonzero for
required failures. Plugins/TPM deliberately skipped during installation are
optional. Docker checks validate CLI plugins, not daemon startup; a skipped
Docker installation is optional. Explicitly provisioned editor tools have markers
and are checked independently. Fonts, assistant accounts, and remote connectivity
require appropriate client/manual checks.

## Updates

```sh
just update
just workflow
just security
```

`update` snapshots before an SSH fast-forward source update. Review upgrades to
Homebrew/apt separately; bootstrap does not upgrade the entire system. Tool pins
are intentional: update URL/version/hash together using upstream release metadata,
then regenerate inventory with `just assets`. Test the affected installation path
on a disposable machine before relying on a new runtime archive.

For Neovim, review `:Lazy update` changes to `lazy-lock.json` and pinned specs.
For Mason, explicitly install/upgrade desired packages and check representative
files. VS Code updates its extensions through the application. The trust model
and artifact inventory are documented in [supply chain](SUPPLY-CHAIN.md).
