#!/usr/bin/env bash
# Install macOS packages via Homebrew. Direct upstream shell installers are not run.

set -euo pipefail

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  +\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
warn() { printf "\033[0;33m  !\033[0m %s\n" "$*" >&2; }
fatal() { printf "\033[0;31m  x\033[0m %s\n" "$*" >&2; exit 1; }

START_COLIMA=0
usage() {
  cat <<EOF
Usage: $0 [--start-colima]

Options:
  --start-colima   start Colima and enable its Homebrew service
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start-colima) START_COLIMA=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done

if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools..."
  xcode-select --install
  info "Re-run this script once Xcode CLT installation completes."
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  fatal "Homebrew is required. Install it manually from https://brew.sh, then re-run."
fi

info "Homebrew already installed; updating..."
brew update

log "Installing CLI tools..."
brew_formulae=(
  zsh starship tmux neovim eza bat fzf ripgrep fd zoxide lazygit git-delta
  atuin direnv git gh curl wget jq tree htop btop python@3.12 uv go rustup
  colima docker docker-compose docker-buildx
)

for formula in "${brew_formulae[@]}"; do
  if brew list --formula "$formula" >/dev/null 2>&1; then
    info "$formula already installed"
  else
    brew install "$formula"
    success "installed $formula"
  fi
done

log "Installing GUI applications..."
brew_casks=(ghostty visual-studio-code font-fira-code-nerd-font)
for cask in "${brew_casks[@]}"; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    info "$cask already installed"
  else
    brew install --cask "$cask" || warn "Skipped $cask"
  fi
done

if command -v rustup-init >/dev/null 2>&1 && [[ ! -d "$HOME/.cargo" ]]; then
  log "Initializing Rust toolchain..."
  rustup-init -y --no-modify-path --default-toolchain stable
fi

if command -v fzf >/dev/null 2>&1 && [[ ! -f "$HOME/.fzf.zsh" ]]; then
  log "Installing fzf key bindings..."
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

log "Wiring Docker CLI plugins..."
mkdir -p "$HOME/.docker/cli-plugins"
brew_prefix="$(brew --prefix)"
for plugin in docker-compose docker-buildx; do
  target="$brew_prefix/opt/${plugin}/bin/${plugin}"
  link="$HOME/.docker/cli-plugins/${plugin}"
  if [[ -x "$target" ]]; then
    ln -sfn "$target" "$link"
    success "linked $plugin"
  else
    warn "Skipped $plugin; binary not found at $target"
  fi
done

if [[ "$START_COLIMA" == "1" ]] && command -v colima >/dev/null 2>&1; then
  if ! colima status >/dev/null 2>&1; then
    log "Starting Colima..."
    colima start --cpu 2 --memory 4 --disk 60 || warn "Colima failed to start."
  fi
  if ! brew services list | grep -q "^colima .*started"; then
    brew services start colima || warn "Could not enable colima as a service."
  fi
elif command -v colima >/dev/null 2>&1; then
  warn "Colima installed but not started. Re-run with --start-colima to enable it."
fi

warn "Claude Code is not installed automatically; install it manually if you accept its upstream installer."
success "macOS setup complete."
