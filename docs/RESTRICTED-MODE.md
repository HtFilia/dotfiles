# 🔒 Restricted mode (corporate / locked-down machines)

For machines where only **apt (official Debian repos)** and **github.com** are reachable through the corporate firewall.

## How to bootstrap

```bash
# Clone the repo (only github.com is needed)
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run bootstrap with --restricted flag
./scripts/bootstrap.sh --restricted
```

Or via env var:

```bash
DOTFILES_MODE=restricted ./scripts/bootstrap.sh
```

### Cloning via SSH instead of HTTPS

If your corporate firewall allows GitHub SSH (`git@github.com`) but not HTTPS:

```bash
# Pass --ssh through to the installer
./scripts/install-debian-restricted.sh --ssh

# Or set the base URL yourself
GITHUB_BASE="git@github.com:" ./scripts/bootstrap.sh --restricted
```

### Verify what actually got installed

```bash
./scripts/verify.sh
```

Prints a per-tool status line (✓ installed / ✗ missing / ○ optional).

## What's different from the normal mode

| Tool | Normal mode | Restricted mode |
|---|---|---|
| Zsh, tmux, ripgrep, fd, bat, fzf, Python, Go, Rust, Docker | apt | apt (same) |
| Starship, eza, zoxide, git-delta | custom repo / `curl \| sh` | **built from GitHub with `cargo`** |
| lazygit, chezmoi | custom repo / `curl \| sh` | **built from GitHub with `go`** |
| Neovim | curl GitHub release | **built from GitHub source** |
| uv, fnm | `curl \| sh` from astral.sh / vercel.app | **built from GitHub with `cargo`** |
| FiraCode Nerd Font | GitHub release archive | **sparse git clone of nerd-fonts repo** |
| Ghostty | brew cask / official build | ⊘ **skipped** (uses GNOME Terminal) |
| VS Code | Microsoft apt repo | ⊘ **skipped** (uses nvim only) |
| GitHub CLI (gh) | cli.github.com apt repo | ⊘ skipped (build manually if needed) |
| atuin | `curl \| sh` | ⊘ skipped |
| Claude Code | `claude.ai/install.sh` | ⊘ skipped (install only if npm allowed) |

Everything else works identically — same dotfiles, same theme, same keybindings.

## ⚠️ Registry gotchas

When you run `cargo build` or `go build`, those toolchains will try to download dependencies from **crates.io** and **proxy.golang.org** respectively. If those are blocked too, you need to configure your IT's internal mirror:

### Rust (crates.io)

```bash
# In ~/.cargo/config.toml
[source.crates-io]
replace-with = "corporate"

[source.corporate]
registry = "sparse+https://your-internal-mirror/cargo/"
```

### Go (proxy.golang.org)

```bash
export GOPROXY=https://your-internal-mirror/goproxy,direct
export GOSUMDB=off   # or point to your internal sum DB
```

### Python (PyPI)

```bash
# In ~/.pip/pip.conf
[global]
index-url = https://your-internal-mirror/pypi/simple/
```

### npm (if needed for Claude Code, Copilot, etc.)

```bash
npm config set registry https://your-internal-mirror/npm/
```

Ask your IT / DevOps team whether they have these mirrors — most large companies do. If not, **the restricted bootstrap will fail during `cargo build` / `go build`** because it can't fetch dependencies.

## LazyVim + Mason caveat

LazyVim uses `mason.nvim` to install LSP servers. Mason downloads binaries from various sources (npm, pip, GitHub releases, custom URLs). Many of these will be **blocked** in a corporate environment.

**Two options:**

1. **Install LSPs via apt where possible** (recommended):
   ```bash
   sudo apt install \
     python3-lsp-server \
     gopls \
     rust-analyzer \
     nodejs npm   # for typescript-language-server, via npm
   ```
   Then configure LazyVim to *not* auto-install via Mason (add to `~/.config/nvim/lua/plugins/`):
   ```lua
   return {
     { "williamboman/mason.nvim", enabled = false },
     { "williamboman/mason-lspconfig.nvim", enabled = false },
   }
   ```

2. **Use Mason through an internal mirror** — unlikely unless your company has a GitHub Releases proxy.

## Treesitter parsers

LazyVim bundles `nvim-treesitter`, which downloads parser grammars from GitHub (✅ allowed) and compiles them locally with `gcc`/`cc` (✅ available from `build-essential`). So **treesitter works fine** in restricted mode.

## Font on restricted WSL Windows host

If your Windows host also can't reach GitHub releases directly:

1. On a machine with free access, download `FiraCode.zip` from `github.com/ryanoasis/nerd-fonts/releases/latest`
2. Transfer via corporate file-sharing
3. Double-click each `.ttf` → "Install for all users"

## Verifying the install

After `./scripts/bootstrap.sh --restricted` completes, run:

```bash
./scripts/verify.sh
```

It checks every tool (required + optional) and prints a version per line.

## Troubleshooting

### `cargo build` fails with "failed to fetch crate X"
→ crates.io is blocked. See the "Registry gotchas" section above.

### `go build` fails with "dial tcp: lookup proxy.golang.org: no such host"
→ Set `GOPROXY` (see above) or use `GOFLAGS=-mod=vendor` if the repo vendors its deps.

### Building Neovim fails with "LuaJIT not found"
```bash
sudo apt install luajit libluajit-5.1-dev
```

### `pip install ...` fails
PyPI is blocked. Use your internal mirror or `uv` with a vendored package set.
