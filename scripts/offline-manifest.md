# Offline assets manifest

Canonical list of pre-built binaries that `install-debian-restricted.sh` expects
to find in `$OFFLINE_ASSETS_DIR` (default `~/dotfiles-offline-assets/`) on the
restricted Debian 12 workstation.

These come from GitHub Releases. On the restricted machine those downloads are
blocked (`objects.githubusercontent.com` is firewalled), so fetch them from a
machine with free internet — typically your Windows laptop — and transfer the
resulting directory to the workstation over SCP / WinSCP / any file-transfer
channel IT allows.

## Workflow

1. On Windows (or any connected machine), create a folder `dotfiles-offline-assets/`.
2. Download the 7 files listed below into that folder — right-click the URL and
   **Save As**, or use the PowerShell snippet at the end of this file.
3. Transfer the folder to the workstation at `~/dotfiles-offline-assets/`:
   - **WinSCP / FileZilla / VS Code Remote** — drag and drop.
   - **scp from WSL** — `scp -r dotfiles-offline-assets/ user@workstation:~/`
   - **Anything else your IT allows** — USB, internal share, etc.
4. On the workstation, run `./scripts/install-debian-restricted.sh`.

The installer is idempotent — missing assets are reported clearly at the end of
each run. Drop in the missing files and re-run; it picks up where it left off.

## Pins

Defaults match the `_REF` values in `install-debian-restricted.sh`. Override at
runtime with env vars if you bump them; keep this file in sync.

| Tool | Version | Env var |
|---|---|---|
| starship | `v1.23.0` | `STARSHIP_REF` |
| eza | `v0.21.5` | `EZA_REF` |
| uv | `0.6.17` | `UV_REF` |
| lazygit | `v0.48.0` | `LAZYGIT_REF` |
| git-delta | `0.18.2` | `DELTA_REF` |
| FiraCode Nerd Font | `v3.3.0` | `FONT_REF` |
| neovim *(fallback)* | `stable` | `NVIM_REF` |

## Download links

Each entry lists the URL to fetch and the exact filename the installer looks
for in `~/dotfiles-offline-assets/`. Preserve the filenames — the installer
pattern-matches on them.

### starship

- **URL** : https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz
- **Save as** : `starship-x86_64-unknown-linux-gnu.tar.gz`
- **Installs to** : `~/.local/bin/starship`

### eza

- **URL** : https://github.com/eza-community/eza/releases/download/v0.21.5/eza_x86_64-unknown-linux-gnu.tar.gz
- **Save as** : `eza_x86_64-unknown-linux-gnu.tar.gz`
- **Installs to** : `~/.local/bin/eza`

### uv

- **URL** : https://github.com/astral-sh/uv/releases/download/0.6.17/uv-x86_64-unknown-linux-gnu.tar.gz
- **Save as** : `uv-x86_64-unknown-linux-gnu.tar.gz`
- **Installs to** : `~/.local/bin/uv` + symlink `~/.local/bin/uvx → uv`

### lazygit

- **URL** : https://github.com/jesseduffield/lazygit/releases/download/v0.48.0/lazygit_0.48.0_Linux_x86_64.tar.gz
- **Save as** : `lazygit_0.48.0_Linux_x86_64.tar.gz`
- **Installs to** : `~/.local/bin/lazygit`

### git-delta

Used by git as pager/diff filter (configured in `~/.gitconfig`). Not available
in the corporate apt mirror.

- **URL** : https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz
- **Save as** : `delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz`
- **Installs to** : `~/.local/bin/delta`

### FiraCode Nerd Font

- **URL** : https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip
- **Save as** : `FiraCode.zip`
- **Installs to** : `*.ttf` (non-Windows variants) in `~/.local/share/fonts/`, then `fc-cache -f`

### Neovim (fallback)

Only needed if `bookworm-backports` isn't enabled or doesn't ship a
a recent Neovim (≥ 0.8). The preferred path is
`./scripts/install-debian-restricted.sh --enable-backports`, which pulls it
from apt. If that fails, the installer falls back to this tarball.

- **URL** : https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
- **Save as** : `nvim-linux-x86_64.tar.gz`
- **Installs to** : `~/.local/share/nvim-linux-x86_64/` + symlink `~/.local/bin/nvim`

## PowerShell one-liner (Windows)

Open PowerShell in an empty folder and paste:

```powershell
$urls = @(
  "https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz",
  "https://github.com/eza-community/eza/releases/download/v0.21.5/eza_x86_64-unknown-linux-gnu.tar.gz",
  "https://github.com/astral-sh/uv/releases/download/0.6.17/uv-x86_64-unknown-linux-gnu.tar.gz",
  "https://github.com/jesseduffield/lazygit/releases/download/v0.48.0/lazygit_0.48.0_Linux_x86_64.tar.gz",
  "https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz",
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip",
  "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"
)
New-Item -ItemType Directory -Force -Path .\dotfiles-offline-assets | Out-Null
foreach ($u in $urls) {
  $f = Split-Path $u -Leaf
  Write-Host "→ $f"
  Invoke-WebRequest -Uri $u -OutFile ".\dotfiles-offline-assets\$f"
}
```

Result: a `dotfiles-offline-assets/` folder with all 7 files, ready to transfer.

## Coming from apt (no asset needed)

Everything else is installed by the installer from Debian repositories — no
SCP transfer required:

- **main** : zsh, tmux, git, git-lfs, ripgrep, fd-find, bat, fzf, **zoxide**,
  jq, tree, htop, direnv, python3, python3-pip, python3-venv,
  python3-jinja2, python3-yaml, docker.io, build-essential, pkg-config,
  fontconfig, xclip, xsel, curl, wget, unzip, rust-analyzer, gopls,
  python3-pylsp, shellcheck
- **backports** : neovim (≥ 0.9)

## Not supported in restricted mode

These are intentionally excluded — they rely on unreachable registries or
proprietary distribution channels:

- **VS Code** — Microsoft apt repo unreachable; use `nvim`
- **GitHub CLI (gh)** — `cli.github.com` apt repo unreachable
- **atuin** — requires an external sync server
- **Claude Code** — npm registry unreachable
- **Ghostty** — no Debian package, requires Zig

If IT allows a workaround (internal mirror, vendored `.deb`, etc.), install
those manually — they're not in this manifest.

## Bumping a pin

1. Edit the `*_REF` default in `scripts/install-debian-restricted.sh`.
2. Update the URL and **Save as** filename in the relevant section above.
3. If the upstream project changes its release asset naming, update the
   per-tool block in the installer (search for `handle_tool` calls).
4. Re-download on Windows, transfer, re-run the installer.
