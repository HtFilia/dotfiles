#!/usr/bin/env bash
# ============================================================================
# install-macos.sh — Install all packages on macOS via Homebrew
# ============================================================================

set -euo pipefail

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  ✓\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }

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
  gh # GitHub CLI
  curl
  wget
  jq
  tree
  htop
  btop

  # Languages
  python@3.12
  uv # Modern Python package manager
  go
  rustup # Rust toolchain installer
  fnm    # Fast node manager

  # Container runtime & CLI
  # (Colima provides the Linux VM that runs the Docker daemon — macOS
  #  cannot run the Docker daemon natively)
  colima         # Docker daemon / container runtime (lightweight, CLI-only)
  docker         # Docker CLI (client only)
  docker-compose # Compose V2 binary (we symlink it into ~/.docker/cli-plugins below)
  docker-buildx  # Buildx builder (also a Docker CLI plugin)
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

# ============================================================================
# DOCKER CLI PLUGIN WIRING (macOS)
# ----------------------------------------------------------------------------
# On macOS without Docker Desktop, `brew install docker-compose` puts the
# binary outside Docker's CLI plugin path, so `docker compose` (V2) can't
# find it and you get "unknown command: compose". Symlinking it into
# ~/.docker/cli-plugins fixes this. Same pattern for buildx.
# ============================================================================
log "Wiring Docker CLI plugins (compose, buildx)..."
mkdir -p "$HOME/.docker/cli-plugins"

brew_prefix="$(brew --prefix)"
for plugin in docker-compose docker-buildx; do
  target="$brew_prefix/opt/${plugin}/bin/${plugin}"
  link="$HOME/.docker/cli-plugins/${plugin}"
  if [[ -x "$target" ]]; then
    ln -sfn "$target" "$link"
    success "Linked $plugin → ~/.docker/cli-plugins/$plugin"
  else
    info "Skipped $plugin (binary not found at $target)"
  fi
done

# ============================================================================
# COLIMA (Docker daemon on macOS)
# ----------------------------------------------------------------------------
# macOS cannot run the Docker daemon natively. Colima spins up a tiny
# Linux VM that hosts the daemon; the `docker` CLI from Homebrew then
# talks to it over a socket. Start it via `brew services` so it comes
# up automatically at login.
# ============================================================================
if command -v colima &>/dev/null; then
  if ! colima status &>/dev/null; then
    log "Starting Colima (Docker daemon VM)..."
    colima start --cpu 2 --memory 4 --disk 60 ||
      info "Colima failed to start; run 'colima start' manually later."
  else
    info "Colima is already running."
  fi

  # Enable auto-start at login (idempotent)
  if ! brew services list | grep -q "^colima .*started"; then
    log "Enabling Colima auto-start at login..."
    brew services start colima || info "Could not enable colima as a service."
  fi
fi

success "macOS setup complete."
