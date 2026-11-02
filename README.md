# Dotfiles

![Project overview — Lucas Lebihan, Quantitative Engineer](docs/assets/project-header.png)

[![CI](https://github.com/HtFilia/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/HtFilia/dotfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A reproducible development and SSH administration environment for macOS and
Debian 13. Bash handles installation; Chezmoi manages user
configuration. Workstations and servers share shell, Git, tmux and Neovim
configuration, with explicit profile differences and host-local overrides.

## Design decisions

- **Separate user and system configuration.** `home/` contains Chezmoi source;
  the optional Debian 13 baseline in `system/debian/` owns update policy and
  journal retention. Application deployment and network policy belong elsewhere.
- **Use chezmoi natively.** Machine answers live in chezmoi's own config;
  `chezmoi diff`, `apply`, `update` and `re-add` work without a wrapper, and
  deployed files are copies, so pulling Git does not activate edits.
- **Verify downloaded code.** Direct Linux binaries have version/checksum pins;
  shell and editor plugin revisions are recorded. Debian and Homebrew packages
  follow their repositories. [Supply-chain details](docs/SUPPLY-CHAIN.md).
- **Test behavior across platforms.** CI checks Linux and macOS, and installs,
  applies and verifies the server profile twice in a clean Debian 13 container.
  Regressions cover profile selection, drift, local overrides and recovery.

For a code review, start with [machine answers](home/.chezmoi.toml.tmpl),
[verification](scripts/verify.sh), and [behavioral tests](tests/regressions.py).
The [VPS guide](docs/VPS-SERVER.md) documents the system ownership boundary and
rebuild procedure. CI does not test boot, remote connectivity or a full machine
restore.

## Supported environments

| Profile | Platform | Installed environment |
|---|---|---|
| Workstation | macOS with Homebrew and Xcode Command Line Tools | Shell/CLI tools, Neovim, VS Code, Kitty, language runtimes, quality tools, Docker CLI and Colima |
| Workstation | Debian 13, x86_64 | Shell/CLI tools, Kitty, Neovim, language runtimes, quality tools, optional Docker Engine and fonts |
| Server | Debian 13, x86_64 | Shell, CLI navigation, Git/delta/lazygit, tmux, Neovim, Kitty terminfo; no GUI, fonts or containers; optional language runtimes for selected editor tools |

Linux profiles support x86_64 only. Linux VS Code installation is manual. Homebrew/apt versions follow their repositories; direct Linux downloads
and plugin checkouts are pinned. See [supply chain](docs/SUPPLY-CHAIN.md).

## Install

Configure your GitHub SSH key first, then clone through SSH:

```sh
git clone git@github.com:HtFilia/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh
```

Run as your regular development/SSH account. Linux package installation needs
sudo. macOS requires Homebrew; if Command Line Tools installation is started,
finish it and rerun bootstrap.

For a server:

```sh
./scripts/bootstrap.sh --profile server --configure-shell --yes
./scripts/verify.sh --profile server
```

For a Debian 13 administrator host with Python/shell editor tools:

```sh
./scripts/bootstrap.sh --profile server --editor-languages python,shell --system-baseline --dry-run
# Review the preview, then repeat without --dry-run.
```
See [the VPS guide](docs/VPS-SERVER.md) for the system ownership boundary.

Useful workstation choices:

```sh
./scripts/bootstrap.sh --skip-docker --skip-fonts
./scripts/bootstrap.sh --start-colima --configure-shell
./scripts/bootstrap.sh --setup-editor
```

Shell plugins are installed by default.
`--no-shell-plugins` skips shell plugins; `--skip-vscode-extensions` skips editor
extensions. Docker-group membership is opt-in with `--enable-docker-group` and
grants root-equivalent access. See [installation](docs/INSTALLATION.md).

## Apply and update

```sh
chezmoi init --apply HtFilia   # once, after the packages are installed
chezmoi diff                   # preview
chezmoi apply                  # deploy
chezmoi update                 # git pull, then apply
chezmoi re-add ~/.config/nvim/lazy-lock.json   # bring a changed file back
```

`chezmoi init` asks for the machine's profile (`workstation` or `server`) and
context (`perso` or `travail`) once and keeps the answers in
`~/.config/chezmoi/chezmoi.toml`. Files are deployed as copies; applications
that rewrite their config change only the deployed copy.

## Personal settings

| File | Purpose |
|---|---|
| `~/.gitconfig.local` | Identity, credentials, signing, repository-specific includes |
| `~/.zshrc.settings` | Inputs read before integrations, such as command-override flags |
| `~/.zshrc.local` | Final shell aliases, environment overrides, widgets |
| `~/.tmux.conf.local` | Extra tmux bindings/plugins |
| `~/.ssh/config.local` | SSH hosts and identity paths |

chezmoi never creates or changes these files. Create `~/.gitconfig.local` with
your identity before your first commit.

## Repository map

| Path | Responsibility |
|---|---|
| `Brewfile`, `extensions.txt` | macOS packages and VS Code extensions |
| `home/` | Chezmoi source files, templates, and platform exclusions |
| `scripts/` | Package installation, tool updates, editor setup, verification |
| `system/debian/` | Opt-in Debian 13 APT and journald baseline |
| `scripts/pinned-assets.sh`, `scripts/pinned-plugins.sh` | Authoritative download and plugin pins |
| `tests/` | Offline behavioral regressions using temporary homes |
| `.github/workflows/ci.yml` | Linux/macOS checks, Debian 13 install/verify smoke test, actionlint and secret scan |

## Guides

- [Shell startup and customization](docs/SHELL.md)
- [Aliases and helper functions](docs/ALIASES.md)
- [Git behavior](docs/GIT.md)
- [SSH hosts and identities](docs/SSH.md)
- [Kitty and tmux](docs/TERMINALS.md)
- [Neovim and VS Code](docs/EDITORS.md)
- [Runtimes and project environments](docs/RUNTIMES.md)
- [Tools and their roles](docs/TOOLING.md)
- [Keybindings](docs/KEYBINDINGS.md)
- [Debian VPS bootstrap and ownership](docs/VPS-SERVER.md)
- [Verification and maintenance](docs/VERIFICATION.md)

## Check the repository

```sh
just check        # syntax, ShellCheck, offline regressions
just dry-run      # isolated deployment preview
just verify       # acceptance checks for this machine
just workflow     # actionlint, when installed
just security     # redacted Git-history secret scan, when installed
```

Checks do not install packages or alter active dotfiles. Full package
installation and language-tool downloads are separate from offline tests.

MIT licensed.

## Tool updates

```sh
just tools-update
just tools-update --skip-packages --skip-docker
```

Tool provisioning is separate from configuration updates. See
[tool upgrades](docs/UPGRADES.md) and [Operator appearance](docs/VISUALS.md).
Run `tldr --update` once to populate the help cache.
