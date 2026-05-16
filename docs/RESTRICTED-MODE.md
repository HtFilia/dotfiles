# Restricted mode

Restricted mode targets Debian 12 bookworm workstations where only Debian apt
repositories and `github.com` git clones are allowed.

## Workflow

1. Download the pinned files listed in `scripts/offline-manifest.md` on a
   machine with internet access.
2. Transfer them to `~/dotfiles-offline-assets/` on the workstation.
3. Run:

```bash
./scripts/bootstrap.sh --restricted --enable-backports
```

## What is installed

| Source | Tools |
|---|---|
| Debian apt | zsh, tmux, git, ripgrep, fd-find, bat, fzf, zoxide, direnv, docker.io, LSP binaries |
| bookworm-backports | Neovim when available |
| offline pinned assets | starship, eza, uv, lazygit, git-delta, FiraCode Nerd Font, Neovim fallback |
| git clone | zsh-autosuggestions, zsh-syntax-highlighting, tmux TPM |

The restricted Neovim profile is local and does not use LazyVim or plugins.

## Flags

```text
--enable-backports    add bookworm-backports and try Neovim from apt
--assets-dir PATH     override ~/dotfiles-offline-assets
--skip-docker         do not install docker.io
--skip-fonts          do not install FiraCode Nerd Font
--pull-latest         reinstall offline assets from the local folder
--dry-run             print actions without executing them
```

## Security

Each offline asset is verified against the SHA256 in `scripts/pinned-assets.sh`
before extraction. A mismatch is treated as a failure.

VS Code, GitHub CLI, atuin, Claude Code and Ghostty are intentionally excluded
from restricted mode because they require unreachable repositories or upstream
installers.
