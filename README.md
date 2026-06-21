# Dotfiles

[![CI](https://github.com/HtFilia/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/HtFilia/dotfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Opinionated, cross-platform workstation bootstrap for software development.

This repository is designed to be both my daily environment and a readable
example of how I approach developer tooling: reproducible where it matters,
auditable by default, and practical enough to run on real machines.

## What it installs

| Category | Tools |
|---|---|
| Dotfile engine | Chezmoi with this repo's `home/` source state |
| Shell | Zsh, Starship, fzf, zoxide, atuin, direnv |
| Terminal | Ghostty, tmux, TPM |
| Editors | Neovim/LazyVim, VS Code settings and extensions |
| CLI | eza, bat, ripgrep, fd, lazygit, git-delta, gh, jq |
| Languages | Python with uv, Go, Rust, Node.js LTS with pnpm/Corepack |
| Containers | Docker CLI, Docker Compose, Colima on macOS |
| Quality | ShellCheck, shfmt, Bats, Biome |

No Nix, devbox, or mise are required. Platform package managers remain the
base layer: Homebrew on macOS, apt plus pinned direct downloads on Linux.

## Quick start

```bash
git clone https://github.com/HtFilia/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh
```

Useful flags:

```bash
./scripts/bootstrap.sh --start-colima
./scripts/bootstrap.sh --skip-docker
./scripts/bootstrap.sh --skip-fonts
./scripts/bootstrap.sh --skip-vscode-extensions
./scripts/bootstrap.sh --configure-shell
```

Apply only the dotfiles:

```bash
./scripts/apply-dotfiles.sh
./scripts/apply-dotfiles.sh --dry-run
./scripts/apply-dotfiles.sh --dry-run --destination "$(mktemp -d)"
```

## Repository structure

```text
Brewfile                      macOS package manifest
extensions.txt                VS Code extension manifest
home/                         Chezmoi source state
  dot_config/nvim/            LazyVim-based Neovim profile
  dot_config/Code/User/       VS Code settings and keybindings
  dot_config/ghostty/         Ghostty config
  dot_config/git/             global Git ignore and attributes
  dot_zshrc                   portable runtime shell config
scripts/
  bootstrap.sh                one-command installer
  apply-dotfiles.sh           Chezmoi wrapper
  install-debian.sh           Debian/Ubuntu/WSL packages and pinned assets
  install-macos.sh            Homebrew bundle orchestration
  pinned-assets.sh            direct-download URLs and SHA256 checksums
  pinned-plugins.sh           zsh/tmux plugin commits
docs/
  ASSET-MANIFEST.md           downloadable asset inventory
  SUPPLY-CHAIN.md             trust model and update process
tests/
  script-contracts.sh         public CLI contract tests
```

## Design choices

Chezmoi manages target state, while Bash keeps the bootstrap easy to audit.
The repo uses Chezmoi's `dot_` naming convention directly from `home/`, so the
source tree stays readable without an extra generated layer.

Direct Linux downloads are pinned by exact URL and SHA256 in
[`scripts/pinned-assets.sh`](scripts/pinned-assets.sh). Zsh and tmux plugins are
checked out to exact commits in [`scripts/pinned-plugins.sh`](scripts/pinned-plugins.sh).
Homebrew and apt are trusted through their own signing and repository models.

The shell startup path is defensive: plugin files are sourced only when they are
owned by the current user and are not group/world writable.

## Verification

```bash
bash -n scripts/*.sh
shellcheck scripts/*.sh
bash tests/script-contracts.sh
./scripts/apply-dotfiles.sh --dry-run --destination "$(mktemp -d)"
./scripts/verify.sh
```

`./scripts/verify.sh` reports installed versions, active dotfile links, pinned
plugin commits, editor tooling, language runtimes, and quality tools.
