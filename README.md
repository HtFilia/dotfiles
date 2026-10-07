# Dotfiles

![Project overview — Lucas Lebihan, Quantitative Engineer](docs/assets/project-header.png)

[![CI](https://github.com/HtFilia/dotfiles/actions/workflows/ci.yml/badge.svg?branch=environment%2Fcorporate)](https://github.com/HtFilia/dotfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

This is the **corporate derivative**, on `environment/corporate`. Personal
configuration and its macOS/server installers remain on `master`. The initial
corporate target is Debian 12/13 x86_64 workstation, including Debian on WSL.

Start with [Corporate installation and maintenance](docs/CORPORATE.md).
[AGENTS.md](AGENTS.md) tracks the unresolved infrastructure questions for the
agent operating inside the corporation. Corporate network acceptance is pending.

## Acquisition

Existing authorized APT supplies the distro runtimes and system packages. Reviewed
GitHub releases/source retain the standalone tools and plugin pins. Editor npm and
Python packages require complete, hashed internal Artifactory inputs. No vendor APT
repositories, Cargo registry builds, Go toolchain downloads or Marketplace fallback
are added. Themes, shell workflows, keybindings and workbooks remain shared.

## Install

After this branch has been published, use an approved GitHub transport:

```sh
git clone --branch environment/corporate https://github.com/HtFilia/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/corporate-preflight.sh
./scripts/bootstrap.sh --dry-run --skip-docker
# Prepare corporate.env and Git identity as described in docs/CORPORATE.md:
./scripts/bootstrap.sh --yes --skip-docker
# Or use --skip-packages after administrator provisioning.
```

Editor languages and reviewed VSIXs are explicit setup choices. Default
configuration materialization uses independent files, with deployment snapshots.
GitHub-hosted CI checks corporate contracts and repeats workstation installation
in clean Debian fixtures; infrastructure acceptance remains a separate step.

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
`~/.local/state/dotfiles`. Corporate workstations default to independent files;
an existing saved mode is preserved. Choose a mode explicitly with `--materialize file` or
`--materialize symlink`. Apply supports isolated `--destination` and `--source`
paths. Dry runs do not create destination files or persistent state.

The update helper requires a clean corporate checkout, an approved GitHub origin
and upstream `origin/environment/corporate`. It snapshots
live contents before a fast-forward pull, then applies the saved profile. Use
`dotfiles-update --after-pull` when the pull was already performed manually.
The installed `UPDATE` command is the explicit post-pull form. The saved source
path, profile and materialization mode make repeated updates safe and
predictable. This matters for symlinks: source edits take effect immediately. See
[deployment and recovery](docs/DEPLOYMENT.md).

## Host-local settings

| File | Purpose |
|---|---|
| `~/.gitconfig.local` | Identity, credentials, signing, repository-specific includes |
| `~/.zshrc.settings` | Inputs read before integrations, such as command-override flags |
| `~/.zshrc.local` | Final shell aliases, environment overrides, widgets |
| `~/.tmux.conf.local` | Extra tmux bindings/plugins |
| `~/.ssh/config.local` | SSH hosts and identity paths |
| `~/.config/dotfiles/corporate.env` | Approved registry/trust/proxy environment settings |

Existing managed files are backed up before apply. Git identity is prompted
when appropriate or supplied through `DOTFILES_GIT_NAME`/`DOTFILES_GIT_EMAIL`.
Existing identity files are preserved.

## Repository map

| Path | Responsibility |
|---|---|
| `Brewfile`, `extensions.txt` | Retained personal package/extension selection references |
| `home/` | Chezmoi source files, templates, and platform exclusions |
| `scripts/` | Installation, deployment, snapshots, updates, editor setup, verification |
| `AGENTS.md`, `docs/CORPORATE.md` | Corporate infrastructure handoff and operating guide |
| `scripts/pinned-assets.sh`, `scripts/pinned-plugins.sh` | Authoritative download and plugin pins |
| `assets/terminfo/` | Vendored Ghostty terminfo and upstream license |
| `tests/` | Offline behavioral regressions using temporary homes |
| `.github/workflows/ci.yml` | Debian 12/13 workstation smoke, offline tests, actionlint and secret scan |

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
- [Mac Ghostty connecting to a VPS (personal master)](docs/VPS-GHOSTTY.md)
- [Debian VPS bootstrap and ownership (personal master)](docs/VPS-SERVER.md)
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

## Optional workstation tools and layouts

```sh
just tools-update        # packages and managed tools, separate from git/config updates
just tools-update --skip-packages
lab                      # nine interactive tool workbooks after deployment
deck                     # shell + live resources + system card
termstyle operator       # control-room layout for active work
```

The default Operator shell layout uses graphite, teal and amber; editor and
diff views use Gruvbox. Styles are selected explicitly and do not add startup
animations or network calls.

The workstation includes ouch, zstd, moreutils, ov, hexyl, dua, broot,
Czkawka CLI, xcp, chafa, viu, vivid, pastel, GNU Parallel, tealdeer (`tldr`),
jc and jless. Fastfetch, cmatrix and cava provide explicit visual modes.
See [workbooks](docs/WORKBOOKS.md), [visual styles](docs/VISUALS.md), and
[tool upgrades](docs/UPGRADES.md). Run `dotfiles-style operator` after first deployment
and `tldr --update` once to populate the help cache.
