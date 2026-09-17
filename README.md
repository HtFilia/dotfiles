# Personal dotfiles

A practical development environment for macOS, Debian/Ubuntu, WSL, and SSH
servers. Bash installs packages; Chezmoi deploys the files in `home/`. The shell
and terminal use a compact Operator layout with deep green graphite, teal and
amber accents; classic Gruvbox, Studio and two legacy accent profiles remain
available.
Editors and Git diffs retain Gruvbox.

## Supported environments

| Profile | Platform | Installed environment |
|---|---|---|
| Workstation | macOS with Homebrew and Xcode Command Line Tools | Shell/CLI tools, Neovim, VS Code, Ghostty, language runtimes, quality tools, Docker CLI and Colima |
| Workstation | Debian 12/13 or Ubuntu 24.04/26.04, x86_64 | Shell/CLI tools, Neovim, language runtimes, quality tools, optional Docker Engine and fonts |
| Workstation | WSL on a supported Debian/Ubuntu release, x86_64 | Linux development tools; terminal, fonts, VS Code and Docker Desktop belong on Windows |
| Server | Supported Debian/Ubuntu, x86_64 | Shell, CLI navigation, Git/delta/lazygit, tmux, Neovim, Ghostty terminfo; no GUI, fonts, containers or language runtimes |

Linux ARM asset entries are metadata for selected upstream downloads, not a
supported installation profile. Linux Ghostty and VS Code installation are
manual. Homebrew/apt versions follow their repositories; direct Linux downloads
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

Useful workstation choices:

```sh
./scripts/bootstrap.sh --skip-docker --skip-fonts
./scripts/bootstrap.sh --start-colima --configure-shell
./scripts/bootstrap.sh --setup-editor
```

Shell plugins are installed by default. TPM is optional through `--with-tpm`.
`--no-shell-plugins` skips shell plugins; `--skip-vscode-extensions` skips editor
extensions. Docker-group membership is opt-in with `--enable-docker-group` and
grants root-equivalent access. See [installation](docs/INSTALLATION.md).

## Apply and update

```sh
./scripts/apply-dotfiles.sh --dry-run
./scripts/apply-dotfiles.sh
./scripts/update-dotfiles.sh
# or, after deployment, from any directory:
dotfiles-update
# after a manual git pull:
UPDATE
```

The selected profile and materialization mode are saved under
`~/.local/state/dotfiles`. Workstations use file-level symlinks; servers use
independent files. Choose a mode explicitly with `--materialize file` or
`--materialize symlink`. Apply supports isolated `--destination` and `--source`
paths. Dry runs do not create destination files or persistent state.

The update helper requires a clean checkout and GitHub SSH origin. It snapshots
live contents before a fast-forward pull, then applies the saved profile. Use
`dotfiles-update --after-pull` when the pull was already performed manually.
The installed `UPDATE` command is the explicit post-pull form. The saved source
path, profile and materialization mode make repeated updates safe and
predictable. This matters for symlinks: source edits take effect immediately. See
[deployment and recovery](docs/DEPLOYMENT.md).

## Personal settings

| File | Purpose |
|---|---|
| `~/.gitconfig.local` | Identity, credentials, signing, repository-specific includes |
| `~/.zshrc.settings` | Inputs read before integrations, such as command-override flags |
| `~/.zshrc.local` | Final shell aliases, environment overrides, widgets |
| `~/.tmux.conf.local` | Extra tmux bindings/plugins |
| `~/.ssh/config.local` | SSH hosts and identity paths |

Existing managed files are backed up before apply. Git identity is prompted
when appropriate or supplied through `DOTFILES_GIT_NAME`/`DOTFILES_GIT_EMAIL`.
Existing identity files are preserved.

## Repository map

| Path | Responsibility |
|---|---|
| `Brewfile`, `extensions.txt` | macOS packages and VS Code extensions |
| `home/` | Chezmoi source files, templates, and platform exclusions |
| `scripts/` | Installation, deployment, snapshots, updates, editor setup, verification |
| `scripts/pinned-assets.sh`, `scripts/pinned-plugins.sh` | Authoritative download and plugin pins |
| `assets/terminfo/` | Vendored Ghostty terminfo and upstream license |
| `tests/` | Offline behavioral regressions using temporary homes |
| `.github/workflows/ci.yml` | Linux/macOS checks, actionlint, redacted secret scan |

## Guides

- [Shell startup and customization](docs/SHELL.md)
- [Aliases and helper functions](docs/ALIASES.md)
- [Git behavior](docs/GIT.md)
- [SSH hosts and identities](docs/SSH.md)
- [Ghostty and tmux](docs/TERMINALS.md)
- [Neovim and VS Code](docs/EDITORS.md)
- [Runtimes and project environments](docs/RUNTIMES.md)
- [Tools and their roles](docs/TOOLING.md)
- [Keybindings](docs/KEYBINDINGS.md)
- [Mac Ghostty connecting to a VPS](docs/VPS-GHOSTTY.md)
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

MIT licensed; vendored terminfo retains its upstream license.

## Modern tools, terminal layouts and workbooks

```sh
just tools-update        # packages and managed tools, separate from git/config updates
just tools-update --skip-packages
lab                      # nine interactive tool workbooks after deployment
deck                     # shell + live resources + system card
termstyle operator       # control-room layout for active work
```

The workstation includes ouch, zstd, moreutils, ov, hexyl, dua, broot,
Czkawka CLI, xcp, chafa, viu, vivid, pastel, GNU Parallel, tealdeer (`tldr`),
jc and jless. Fastfetch, cmatrix and cava provide explicit visual modes.
See [workbooks](docs/WORKBOOKS.md), [visual styles](docs/VISUALS.md), and
[tool upgrades](docs/UPGRADES.md). Run `dotfiles-style operator` after first deployment
and `tldr --update` once to populate the help cache.
