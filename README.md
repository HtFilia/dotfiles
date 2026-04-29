# 🚀 Dotfiles

Modern, cross-platform development environment configuration.

Supports **macOS**, **Debian 12/13**, and **Debian 13 on WSL**.

## ✨ What's inside

| Category | Tool |
|---|---|
| **Shell** | Zsh + [Starship](https://starship.rs/) prompt |
| **Terminal** | [Ghostty](https://ghostty.org/) |
| **Multiplexer** | [tmux](https://github.com/tmux/tmux) + [TPM](https://github.com/tmux-plugins/tpm) |
| **Editors** | [Neovim](https://neovim.io/) + [LazyVim](https://www.lazyvim.org/), VS Code |
| **Theme** | Tokyo Night (everywhere) |
| **Font** | FiraCode Nerd Font |
| **AI** | Claude Code |
| **Languages** | Python (uv), Go, Rust (rustup) |
| **Container** | Docker / Podman aliases |

### Modern CLI tools

- [`eza`](https://github.com/eza-community/eza) — modern `ls`
- [`bat`](https://github.com/sharkdp/bat) — `cat` with syntax highlighting
- [`fzf`](https://github.com/junegunn/fzf) — fuzzy finder
- [`ripgrep`](https://github.com/BurntSushi/ripgrep) — fast grep
- [`fd`](https://github.com/sharkdp/fd) — modern `find`
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) — smart `cd`
- [`lazygit`](https://github.com/jesseduffield/lazygit) — git TUI
- [`delta`](https://github.com/dandavison/delta) — better git diffs
- [`direnv`](https://direnv.net/) — per-project environments

## 🚀 Quick start

On a fresh machine, run:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh
```

The bootstrap script will:

1. Detect your OS (macOS / Debian / WSL)
2. Install [Homebrew](https://brew.sh/) (macOS) or set up `apt` (Debian/WSL)
3. Install all the CLI tools listed above
4. Render and symlink the dotfiles via `scripts/render-dotfiles.py`
5. Install the FiraCode Nerd Font
6. Install Neovim + LazyVim bootstrap
7. Install tmux plugin manager (TPM)
8. Set Zsh as your default shell

### 🔒 Corporate / locked-down machines (Debian only)

If you're on a work machine where only `apt` (official Debian repos) and `github.com` are reachable:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh --restricted
```

Pre-built binaries for tools not in apt must be placed in `~/dotfiles-offline-assets/` beforehand.
See [`docs/RESTRICTED-MODE.md`](docs/RESTRICTED-MODE.md) for the full workflow and download manifest.

### ✅ Verify your install

```bash
./scripts/verify.sh
```

## 📁 Repository structure

```
.
├── home/                      # Dotfiles source (dot_ prefix → . in $HOME)
│   ├── dot_config/
│   │   ├── Code/User/        # VS Code settings + keybindings
│   │   ├── ghostty/          # Terminal config
│   │   ├── git/              # Git config + global ignore
│   │   ├── nvim/             # Neovim + LazyVim
│   │   ├── ripgrep/          # Ripgrep defaults
│   │   └── starship.toml     # Prompt config
│   ├── dot_gitconfig.tmpl    # Git config (templated per machine)
│   ├── dot_tmux.conf         # Tmux config
│   └── dot_zshrc.tmpl        # Main Zsh config (templated per OS)
├── scripts/
│   ├── bootstrap.sh          # One-command installer
│   ├── render-dotfiles.py    # Template renderer + symlinker
│   ├── install-macos.sh      # macOS-specific installs
│   ├── install-debian.sh     # Debian/WSL installs
│   ├── install-debian-restricted.sh  # Locked-down Debian installs
│   ├── offline-manifest.md   # Download links for restricted mode
│   └── install-fonts.sh      # Nerd Font installer
└── docs/                     # Extended documentation
```

## 🎨 Templating

Files ending in `.tmpl` are rendered by `scripts/render-dotfiles.py` using a
Go-template subset. This lets the same repo produce different output per OS and
machine type:

- Different paths (e.g. Homebrew at `/opt/homebrew` vs `/home/linuxbrew`)
- Different aliases (macOS `pbcopy` vs WSL `clip.exe`)
- Per-machine values (`name`, `email`, `machineType`, `hostname`) stored in
  `~/.config/dotfiles/machine.yaml` (created interactively on first run)

## 🔄 Daily workflow

```bash
# Go to the dotfiles repo
dotfiles        # alias → cd ~/.dotfiles

# Edit a template
$EDITOR home/dot_zshrc.tmpl

# Re-apply (re-renders templates + refreshes symlinks)
python3 scripts/render-dotfiles.py apply

# Commit and push
git add -p && git commit -m "feat: ..." && git push
```

## 🖥️ Per-machine config

On first run, `render-dotfiles.py` prompts for:

- Your name & email (for git)
- Machine type: `personal` or `work`
- Hostname identifier

Answers are saved to `~/.config/dotfiles/machine.yaml` and injected into templates.

## 📚 Further reading

- [`docs/KEYBINDINGS.md`](docs/KEYBINDINGS.md) — shortcuts cheat sheet
- [`docs/RESTRICTED-MODE.md`](docs/RESTRICTED-MODE.md) — locked-down machine workflow
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — common issues
