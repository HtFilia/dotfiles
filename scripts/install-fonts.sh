#!/usr/bin/env bash
# ============================================================================
# install-fonts.sh — Install FiraCode Nerd Font on macOS or Linux
# ============================================================================

set -euo pipefail

log()     { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  ✓\033[0m %s\n" "$*"; }
info()    { printf "\033[0;36m  i\033[0m %s\n" "$*"; }

OS="$(uname -s)"

install_font_linux() {
  local font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"

  # Skip if already installed
  if fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
    info "FiraCode Nerd Font already installed."
    return 0
  fi

  log "Downloading FiraCode Nerd Font..."
  local tmpdir
  tmpdir=$(mktemp -d)
  curl -fL -o "$tmpdir/FiraCode.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"

  log "Extracting..."
  unzip -oq "$tmpdir/FiraCode.zip" -d "$tmpdir/FiraCode"

  # Install only TTF files, skip Windows variants
  find "$tmpdir/FiraCode" -name "*.ttf" ! -name "*Windows*" \
    -exec cp {} "$font_dir/" \;

  log "Rebuilding font cache..."
  fc-cache -f "$font_dir"

  rm -rf "$tmpdir"
  success "FiraCode Nerd Font installed to $font_dir"
}

install_font_macos() {
  # On macOS, the brew cask is the cleanest path — done in install-macos.sh.
  if brew list --cask font-fira-code-nerd-font &>/dev/null; then
    info "FiraCode Nerd Font already installed via Homebrew."
  else
    log "Installing FiraCode Nerd Font via Homebrew..."
    brew install --cask font-fira-code-nerd-font
  fi
}

case "$OS" in
  Darwin) install_font_macos ;;
  Linux)  install_font_linux ;;
  *)      info "Skipping font install on $OS" ;;
esac
