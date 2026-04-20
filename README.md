# 🚀 Dotfiles

Modern, cross-platform development environment configuration, managed with [chezmoi](https://www.chezmoi.io/).

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
| **Dotfiles manager** | [chezmoi](https://www.chezmoi.io/) |

### Modern CLI tools

- [`eza`](https://github.com/eza-community/eza) — modern `ls`
- [`bat`](https://github.com/sharkdp/bat) — `cat` with syntax highlighting
- [`fzf`](https://github.com/junegunn/fzf) — fuzzy finder
- [`ripgrep`](https://github.com/BurntSushi/ripgrep) — fast grep
- [`fd`](https://github.com/sharkdp/fd) — modern `find`
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) — smart `cd`
- [`lazygit`](https://github.com/jesseduffield/lazygit) — git TUI
- [`delta`](https://github.com/dandavison/delta) — better git diffs
- [`atuin`](https://github.com/atuinsh/atuin) — synced shell history
- [`direnv`](https://direnv.net/) — per-project environments

## 🚀 Quick start

On a fresh machine, run:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/scripts/bootstrap.sh | bash
```

Or manually:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh
```

### 🔒 Corporate / locked-down machines (Debian only)

If you're on a work machine where only `apt` (official Debian repos) and `github.com` are reachable:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh --restricted
```

This mode builds all non-apt tools from GitHub sources instead of fetching binaries from third-party domains. See [`docs/RESTRICTED-MODE.md`](docs/RESTRICTED-MODE.md) for details and caveats.

### ✅ Verify your install

After bootstrap, run:

```bash
./scripts/verify.sh
```

to see which tools are installed and their versions (works in both full and restricted modes).

The bootstrap script will:

1. Detect your OS (macOS / Debian / WSL)
2. Install [Homebrew](https://brew.sh/) (macOS) or set up `apt` (Debian/WSL)
3. Install all the CLI tools listed above
4. Install chezmoi and apply the dotfiles
5. Install the FiraCode Nerd Font
6. Install Neovim + LazyVim bootstrap
7. Install tmux plugin manager (TPM)
8. Set Zsh as your default shell

## 📁 Repository structure

```
.
├── home/                      # Files managed by chezmoi (source state)
│   ├── dot_config/
│   │   ├── Code/User/        # VS Code settings + keybindings
│   │   ├── ghostty/          # Terminal config
│   │   ├── git/              # Git config + global ignore
│   │   ├── nvim/             # Neovim + LazyVim
│   │   └── starship.toml     # Prompt config
│   ├── dot_gitconfig.tmpl    # Git config (templated)
│   ├── dot_tmux.conf         # Tmux config
│   └── dot_zshrc.tmpl        # Main Zsh config (templated per OS)
├── scripts/
│   ├── bootstrap.sh          # One-command installer
│   ├── install-macos.sh      # macOS-specific installs
│   ├── install-debian.sh     # Debian/WSL installs
│   └── install-fonts.sh      # Nerd Font installer
├── docs/                      # Extended documentation
└── .chezmoi.toml.tmpl        # chezmoi config template
```

## 🎨 Chezmoi templating

Files ending in `.tmpl` are templated. This lets the same repo work differently on each OS:

- Different paths (e.g. Homebrew at `/opt/homebrew` vs `/home/linuxbrew`)
- Different aliases (macOS `pbcopy` vs WSL `clip.exe`)
- Per-machine overrides via `~/.config/chezmoi/chezmoi.toml`

See `docs/CHEZMOI.md` for details.

## 🔄 Daily workflow

```bash
# Edit a config
chezmoi edit ~/.zshrc

# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Commit changes
chezmoi cd
git add . && git commit -m "feat: update zshrc" && git push
```

## 🖥️ Per-machine differences

During `chezmoi init`, you'll be asked a few questions:

- Your name & email (for git)
- Whether this is a "work" or "personal" machine
- Hostname identifier

Your answers are stored in `~/.config/chezmoi/chezmoi.toml` and used by templates.

## 📚 Further reading

- [`docs/KEYBINDINGS.md`](docs/KEYBINDINGS.md) — shortcuts cheat sheet
- [`docs/CHEZMOI.md`](docs/CHEZMOI.md) — chezmoi workflow
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — common issues

## 📄 License

MIT
