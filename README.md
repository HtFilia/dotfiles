# Dotfiles

Modern cross-platform development environment configuration.

Supports macOS, Debian/Ubuntu, WSL, and a restricted Debian 12 mode.

## What's inside

| Category | Tool |
|---|---|
| Shell | Zsh + Starship |
| Terminal | Ghostty |
| Multiplexer | tmux + TPM |
| Editors | LazyVim in full mode, local no-plugin Neovim in restricted mode, VS Code |
| Theme | Tokyo Night |
| Font | FiraCode Nerd Font |
| Languages | Python with uv, Go, Rust |
| Container | Docker / Podman aliases |

## Quick start

```bash
git clone https://github.com/HtFilia/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh
```

Restricted Debian 12 workstation:

```bash
git clone https://github.com/HtFilia/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh --restricted --enable-backports
```

Pre-download the pinned offline assets listed in
[`scripts/offline-manifest.md`](scripts/offline-manifest.md) before running
restricted mode.

## Repository structure

```text
home/                         dotfiles source (dot_ prefix maps to . in $HOME)
  dot_config/
    nvim-lazyvim/             full-mode LazyVim profile
    nvim-restricted/          restricted no-plugin Neovim profile
    Code/User/                VS Code settings
    ghostty/                  Ghostty config
    git/                      global ignore and attributes
    ripgrep/                  ripgrep defaults
  dot_gitconfig               generic Git config; includes ~/.gitconfig.local
  dot_tmux.conf               tmux config
  dot_zshrc                   runtime OS-aware Zsh config
scripts/
  apply-dotfiles.sh           static symlink deployer
  bootstrap.sh                one-command installer
  pinned-assets.sh            pinned URLs and SHA256 values
  install-*.sh                platform installers
  offline-manifest.md         restricted-mode download manifest
```

## Dotfile deployment

This repo does not use Chezmoi or a template engine. `scripts/apply-dotfiles.sh`
creates symlinks from `home/` into `$HOME`.

```bash
./scripts/apply-dotfiles.sh --mode full
./scripts/apply-dotfiles.sh --mode restricted
./scripts/apply-dotfiles.sh --dry-run --mode full
```

If `~/.gitconfig.local` does not exist, the script prompts for Git name/email
and writes that local untracked file.

The default prompt shows the local username and hides the hostname unless the
session is SSH. The dotfiles do not set macOS `ComputerName`, `LocalHostName`, or
`HostName`; if a hostname looks wrong, it is existing system state being
displayed.

## Security model

Direct downloads are pinned in `scripts/pinned-assets.sh` with exact URLs and
SHA256 checksums. Installers refuse cached or offline assets whose checksum does
not match.

Zsh plugins and tmux TPM are pinned in `scripts/pinned-plugins.sh` and checked
out to exact commits. Shell startup refuses to source plugin files that are not
owned by the current user or are group/world writable.

LazyVim is used only in full mode. Its plugin graph is captured in
`home/dot_config/nvim-lazyvim/lazy-lock.json`, and the local config disables
automatic Mason tool installation. Restricted mode has no plugin manager.

`apt` and Homebrew remain trusted through their native signing and repository
mechanisms. Homebrew installs are mutable and not pinned by this repo; use the
verification output to record what was installed. Upstream shell installers are
not run automatically.

## Verify

```bash
./scripts/verify.sh
```
