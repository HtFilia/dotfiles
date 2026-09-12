#!/usr/bin/env bash
# Configure only Ghostty and its font on the Mac used as an SSH client.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE="$SCRIPT_DIR/../home/dot_config/ghostty/config.ghostty"
[[ ! -f "$SCRIPT_DIR/config.ghostty" ]] || CONFIG_SOURCE="$SCRIPT_DIR/config.ghostty"
case "${1:-}" in
  --config) [[ $# == 2 ]] || { printf 'Expected --config PATH\n' >&2; exit 1; }; CONFIG_SOURCE="$2" ;;
  -h|--help) printf 'Usage: %s [--config PATH]\nInstalls/updates Ghostty and FiraCode Nerd Font, backs up and applies Ghostty settings.\n' "$0"; exit 0 ;;
  '') ;;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
esac
[[ "$(uname -s)" == Darwin ]] || { printf 'Run this script on your Mac.\n' >&2; exit 1; }
[[ -f "$CONFIG_SOURCE" ]] || { printf 'Missing config: %s\n' "$CONFIG_SOURCE" >&2; exit 1; }
if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Install Homebrew from https://brew.sh then run this script again.\n' >&2
    exit 1
  fi
fi
brew install --cask ghostty font-fira-code-nerd-font
if [[ -n "$(brew outdated --cask ghostty)" ]]; then
  brew upgrade --cask ghostty
fi
GHOSTTY_BIN="$(command -v ghostty || true)"
[[ -n "$GHOSTTY_BIN" ]] || GHOSTTY_BIN=/Applications/Ghostty.app/Contents/MacOS/ghostty
[[ -x "$GHOSTTY_BIN" ]] || { printf 'Ghostty executable not found.\n' >&2; exit 1; }
"$GHOSTTY_BIN" +validate-config --config-default-files=false --config-file="$CONFIG_SOURCE"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
legacy_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
backup_root="$HOME/.local/state/dotfiles/backups"
mkdir -p "$config_dir" "$legacy_dir" "$backup_root"
backup_dir="$(mktemp -d "$backup_root/ghostty-$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")"
chmod 700 "$backup_root" "$backup_dir"
for target in "$config_dir/config.ghostty" "$config_dir/config" "$legacy_dir/config" "$legacy_dir/config.ghostty"; do
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ "$target" == "$config_dir/"* ]]; then label=xdg; else label=macos; fi
    cp -pP "$target" "$backup_dir/$label-$(basename "$target")"
    [[ ! -f "$target" ]] || cp -pL "$target" "$backup_dir/$label-$(basename "$target").contents"
  fi
done
# One canonical config with compatibility includes for earlier Ghostty versions.
# Replace links rather than writing through them into a previous dotfiles repo.
stage="$(mktemp "$config_dir/config.ghostty.XXXXXX")"
cp "$CONFIG_SOURCE" "$stage"
chmod 600 "$stage"
mv -f "$stage" "$config_dir/config.ghostty"
for target in "$config_dir/config" "$legacy_dir/config" "$legacy_dir/config.ghostty"; do
  stage="$(mktemp "$(dirname "$target")/ghostty-config.XXXXXX")"
  printf 'config-file = "%s"\n' "$config_dir/config.ghostty" >"$stage"
  chmod 600 "$stage"
  mv -f "$stage" "$target"
done
"$GHOSTTY_BIN" +validate-config
printf '\nGhostty configured. Backup: %s\nQuit and reopen Ghostty, then reconnect to the VPS.\n' "$backup_dir"
