#!/usr/bin/env bash
# ============================================================================
# install-macos.sh — Install all packages on macOS via Homebrew
# ============================================================================

set -euo pipefail

log()     { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  ✓\033[0m %s\n" "$*"; }
info()    { printf "\033[0;36m  i\033[0m %s\n" "$*"; }

# ---- Xcode Command Line Tools ----
if ! xcode-select -p &>/dev/null; then
  log "Installing Xcode Command Line Tools..."
  xcode-select --install
  info "Please re-run this script once Xcode CLT installation completes."
  exit 0
fi

# ---- Homebrew ----
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Apple Silicon: add brew to PATH immediately
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  info "Homebrew already installed — updating..."
  brew update
fi

# ---- CLI tools (brew formulae) ----
log "Installing CLI tools..."
brew_formulae=(
  # Shell & prompt
  zsh
  starship

  # Terminal multiplexer
  tmux

  # Editors
  neovim

  # Modern CLI tools
  eza
  bat
  fzf
  ripgrep
  fd
  zoxide
  lazygit
  git-delta
  atuin
  direnv

  # Core
  git
  gh          # GitHub CLI
  curl
  wget
  jq
  tree
  htop
  btop

  # Languages
  python@3.12
  uv          # Modern Python package manager
  go
  rustup      # Rust toolchain installer
  fnm         # Fast node manager

  # Container
  docker
  docker-compose
)

for formula in "${brew_formulae[@]}"; do
  if brew list --formula "$formula" &>/dev/null; then
    info "$formula already installed"
  else
    brew install "$formula"
    success "Installed $formula"
  fi
done

# ---- GUI apps (brew casks) ----
log "Installing GUI applications..."
brew_casks=(
  ghostty
  visual-studio-code
  font-fira-code-nerd-font
)

for cask in "${brew_casks[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    info "$cask already installed"
  else
    brew install --cask "$cask" || info "Skipped $cask (may already be installed via other means)"
  fi
done

# ---- Claude Code ----
if ! command -v claude &>/dev/null; then
  log "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash || info "Claude Code install skipped — install manually from https://claude.com/claude-code"
fi

# ---- Initialize rustup ----
if command -v rustup-init &>/dev/null && [[ ! -d "$HOME/.cargo" ]]; then
  log "Initializing Rust toolchain..."
  rustup-init -y --no-modify-path --default-toolchain stable
fi

# ---- fzf key bindings ----
if command -v fzf &>/dev/null && [[ ! -f "$HOME/.fzf.zsh" ]]; then
  log "Installing fzf key bindings..."
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

success "macOS setup complete."
