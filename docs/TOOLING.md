# Tooling Audit

This document is the current inventory for the managed workstation profile.

## Theme model

The managed UI theme is Gruvbox Material Dark.

| Surface | Managed by | Theme behavior |
|---|---|---|
| VS Code | `home/dot_config/Code/User/settings.json`, `extensions.txt` | `sainnhe.gruvbox-material`, dark medium/material variant |
| Neovim | `home/dot_config/nvim/` | `sainnhe/gruvbox-material`, dark medium/material variant |
| Ghostty | `home/dot_config/ghostty/config` | Custom Gruvbox Material Dark 16-color palette |
| tmux | `home/dot_tmux.conf` | Custom Gruvbox Material Dark status and border colors |
| Starship | `home/dot_config/starship.toml` | Custom Gruvbox Material Dark palette |
| bat and delta | `home/dot_zshrc`, `home/dot_gitconfig` | Built-in `gruvbox-dark` syntax theme |
| fzf | `home/dot_zshrc` | Inline Gruvbox Material Dark color options |

The shared palette is centered on `#1d2021`, `#282828`, `#3c3836`,
`#d4be98`, `#928374`, `#ea6962`, `#e78a4e`, `#d8a657`, `#a9b665`,
`#89b482`, `#7daea3`, and `#d3869b`.

## Installed tools

| Category | Tools | macOS source | Linux source |
|---|---|---|---|
| Dotfile engine | chezmoi | Homebrew | pinned asset |
| Shell and prompt | zsh, starship, fzf, zoxide, atuin, direnv, mise | Homebrew | apt plus pinned assets where needed |
| Terminal | Ghostty, tmux, TPM | Homebrew cask/formula plus pinned plugin commit | manual Ghostty, apt tmux, pinned TPM commit |
| Editors | Neovim/LazyVim, VS Code | Homebrew cask/formula | pinned Neovim asset, manual VS Code on WSL |
| CLI navigation | eza, bat, ripgrep, fd, yazi | Homebrew | apt plus pinned assets where needed |
| Git and diffs | git, gh, lazygit, git-delta | Homebrew | apt, GitHub apt repo, pinned assets |
| HTTP and data | xh, jq, yq, sd | Homebrew | apt plus pinned assets |
| Disk and metrics | dust, duf, hyperfine, tokei, watchexec | Homebrew | pinned assets, except tokei via Cargo |
| Containers | Docker CLI, Docker Compose, Docker Buildx, lazydocker, Colima on macOS | Homebrew | Docker official apt repo plus pinned lazydocker |
| Languages | Python, uv, Go, Rust, Node.js LTS, pnpm/Corepack | Homebrew | apt plus pinned uv, Go, and Node LTS assets |
| Quality and security | ShellCheck, actionlint, gitleaks; optional shfmt, Bats, Biome | Homebrew | apt plus pinned actionlint/gitleaks |
| AI assistants | Claude Code | manual | manual |

## Version policy

CLI tools track the latest stable upstream release when the install source is
manageable and verifiable. Language runtimes stay on pragmatic stable lines:
Node.js follows the active LTS line, Go follows the latest stable Go release,
and Python follows the platform package manager.

Linux direct downloads are listed in `docs/ASSET-MANIFEST.md` and pinned in
`scripts/pinned-assets.sh` by exact URL, filename, version, and SHA256.

## Verification

Use the root `justfile` when `just` is installed:

```bash
just check
just dry-run
just verify
just audit
```

The equivalent raw commands are:

```bash
bash -n scripts/*.sh
zsh -n home/dot_zshrc
shellcheck scripts/*.sh
bash tests/script-contracts.sh
./scripts/apply-dotfiles.sh --dry-run --destination "$(mktemp -d)"
./scripts/verify.sh
```

`./scripts/verify.sh` prints the current machine state. It may report the active
Neovim profile as missing until the dotfiles have been applied with Chezmoi.

## Manual exceptions

This repository does not run upstream shell installers automatically. Claude
Code and other assistant tools should be installed manually from their official
channels when the user accepts their trust model.

Ghostty has no official Debian package in this setup; Linux users should install
it manually from a trusted channel.
