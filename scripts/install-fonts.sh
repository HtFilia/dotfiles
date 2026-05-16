#!/usr/bin/env bash
# Install FiraCode Nerd Font. Linux uses pinned SHA256 verification.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  +\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
fatal() { printf "\033[0;31m  x\033[0m %s\n" "$*" >&2; exit 1; }

install_font_linux() {
  local font_dir="$HOME/.local/share/fonts" cache_dir="${DOTFILES_DOWNLOAD_DIR:-$HOME/.cache/dotfiles/downloads}"
  local key="firacode" file archive tmpdir
  file="$(pinned_asset_field "$key" file)"
  archive="$cache_dir/$file"

  if fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
    info "FiraCode Nerd Font already installed."
    return 0
  fi

  mkdir -p "$font_dir" "$cache_dir"
  if [[ ! -f "$archive" ]]; then
    log "Downloading pinned FiraCode Nerd Font..."
    download_pinned_asset "$key" "$cache_dir" || fatal "Checksum failed for $file"
  elif ! require_pinned_file "$key" "$cache_dir"; then
    fatal "Checksum failed for cached file: $archive"
  fi

  tmpdir="$(mktemp -d)"
  unzip -oq "$archive" -d "$tmpdir/FiraCode"
  find "$tmpdir/FiraCode" -name "*.ttf" ! -name "*Windows*" -exec cp {} "$font_dir/" \;
  fc-cache -f "$font_dir"
  rm -rf "$tmpdir"
  success "FiraCode Nerd Font installed to $font_dir"
}

install_font_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    fatal "Homebrew is required to install the macOS font cask."
  fi
  if brew list --cask font-fira-code-nerd-font >/dev/null 2>&1; then
    info "FiraCode Nerd Font already installed via Homebrew."
  else
    log "Installing FiraCode Nerd Font via Homebrew..."
    brew install --cask font-fira-code-nerd-font
  fi
}

case "$(uname -s)" in
  Darwin) install_font_macos ;;
  Linux) install_font_linux ;;
  *) info "Skipping font install on $(uname -s)" ;;
esac
