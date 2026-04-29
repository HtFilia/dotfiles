# 🔒 Restricted mode (locked-down corporate workstation)

This mode targets a **Debian 12 (bookworm)** machine where the corporate
firewall only lets you reach:

- official Debian apt repositories (`deb.debian.org`) + `bookworm-backports`
- `github.com` for `git clone` (https or ssh)

Every other egress is blocked — GitHub Release downloads
(`objects.githubusercontent.com`), crates.io, proxy.golang.org, PyPI, npm,
Docker Hub, Microsoft apt repo, Ghostty builds, etc.

## Two-step workflow

Because you can't fetch pre-built binaries directly, a few tools must come
from an internet-connected machine (typically your Windows laptop).

### 1. On a machine with internet access (e.g. Windows)

Follow [`scripts/offline-manifest.md`](../scripts/offline-manifest.md) — it
lists the 7 URLs to download, plus a PowerShell one-liner that fetches them
all into `.\dotfiles-offline-assets\`.

Transfer the resulting folder to the workstation at `~/dotfiles-offline-assets/`
via WinSCP, scp from WSL, or whatever file-transfer channel IT allows.

### 2. On the restricted workstation

Clone the dotfiles repo (`git clone` is reachable) and run the installer:

```bash
git clone https://github.com/HtFilia/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/install-debian-restricted.sh --enable-backports
```

First run: everything that can be installed from apt and offline assets
lands immediately. If any offline archive is missing, the script prints a
clear manifest at the end telling you exactly what to download and where
to put it.

Re-run the script after placing any missing archive — it's idempotent.

## Flags

```text
--enable-backports    Add bookworm-backports sources, install Neovim from them
--assets-dir PATH     Override $OFFLINE_ASSETS_DIR (default ~/dotfiles-offline-assets)
--skip-docker         Don't install docker.io
--skip-fonts          Don't install FiraCode Nerd Font
--pull-latest         Re-install even if a binary already exists
--dry-run             Print actions, don't execute them
-h, --help            Show the header
```

## What lands from where

| Tool | Source on the restricted machine |
|---|---|
| zsh, tmux, git, ripgrep, fd-find, bat, fzf, direnv, docker.io | **apt (main)** |
| **zoxide**, **git-delta** | **apt (main)** (used to be built from source) |
| **rust-analyzer, gopls, python3-pylsp, shellcheck** | **apt (main)** — LSPs for LazyVim |
| python3, python3-jinja2, python3-yaml | **apt (main)** — used by `render-dotfiles.py` |
| Neovim | **apt (bookworm-backports)** with `--enable-backports`, else offline tarball |
| starship, eza, fnm, uv, lazygit, FiraCode Nerd Font | **offline SCP** (`~/dotfiles-offline-assets/`) |
| zsh-autosuggestions, zsh-syntax-highlighting, tmux TPM | **git clone** |
| Dotfiles (zshrc, tmux, nvim, starship.toml, …) | rendered by `scripts/render-dotfiles.py` and symlinked |

## Intentionally excluded

These don't work in restricted mode and are not in the manifest:

- **VS Code** — Microsoft apt repo unreachable (use `nvim`).
- **GitHub CLI** — `cli.github.com` apt repo unreachable.
- **atuin** — needs an external sync server.
- **Claude Code** — npm registry unreachable.
- **Ghostty** — no Debian package, requires Zig.

## Dotfile rendering

`scripts/render-dotfiles.py` is a ~350-line Python script using only the
stdlib plus `python3-yaml` (apt). It implements the small subset of Go
template syntax used by the dotfiles (`{{ .chezmoi.os }}`,
`{{- if eq … }}`, `{{- else if … }}`, `{{- end }}`, `contains`, `lower`,
plus the `{{` `...` `}}` raw-string escape for Docker alias formatting).

On first run it prompts for:

- `name`, `email` — written to `[user]` in `~/.gitconfig`
- `machineType` — `work` or `personal`
- `hostname` — free-form label

These are persisted in `~/.config/dotfiles/machine.yaml`. Re-runs are
non-interactive and idempotent.

Rendered files live at `~/.config/dotfiles/rendered/`; `$HOME` contains
symlinks pointing at them (for templated files) or directly at the repo
(for non-templated ones). Check `./scripts/verify.sh` after every install.

## LazyVim / Mason caveat

Mason downloads LSP binaries from many upstreams (npm, pip, GitHub
Releases) that are blocked here. The installer copies
`home/dot_config/nvim/lua/plugins/mason-disabled.lua.example` →
`~/.config/nvim/lua/plugins/mason-disabled.lua`, which disables Mason and
`mason-lspconfig`.

LSPs already installed via apt cover the main languages:

- Rust: `rust-analyzer`
- Go: `gopls`
- Python: `python3-pylsp`
- Shell: `shellcheck`

TypeScript / Lua / other LSPs aren't covered — add them manually if you
need them (not in the manifest).

## Treesitter

`nvim-treesitter` clones parser grammars from GitHub (`git` — allowed)
and compiles them locally with `cc` (from `build-essential`). No network
beyond `github.com` is needed, so treesitter works fine.

## Verifying the install

```bash
./scripts/verify.sh
```

Prints per-tool status. After SCP'ing all assets, every required tool
should be `✓`. `atuin`, `claude`, and `code` are optional (`○` if missing).

## Re-running

The installer is idempotent:

- apt is a no-op once packages are up to date.
- Offline assets are skipped if the binary already exists on `$PATH`;
  pass `--pull-latest` to force reinstall.
- Zsh plugins and TPM are checked for `.git` and skipped if already cloned.
- The dotfiles renderer recreates symlinks only when their targets differ.

## Bumping pins

Edit the `*_REF` defaults at the top of `scripts/install-debian-restricted.sh`
and update the URLs/filenames in `scripts/offline-manifest.md` to match.
Re-download on the connected machine, transfer across, re-run. Done.
