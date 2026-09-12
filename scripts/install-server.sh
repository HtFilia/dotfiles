#!/usr/bin/env bash
# Debian/Ubuntu SSH environment; user tools stay in ~/.local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"

SKIP_PACKAGES=0
case "${1:-}" in
  -h|--help) printf 'Usage: %s [--skip-packages]\nInstalls SSH shell, terminal tools and Neovim on Debian/Ubuntu x86_64.\n' "$0"; exit 0 ;;
  --skip-packages) SKIP_PACKAGES=1 ;;
  '') ;;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
esac
[[ "$(uname -s)" == Linux && "$(pinned_asset_arch)" == x86_64 ]] || {
  printf 'Server installer currently requires Linux x86_64.\n' >&2; exit 1;
}
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}:${ID_LIKE:-}" in
  debian:*|ubuntu:*|*:debian*) ;;
  *) printf 'Server installer requires Debian/Ubuntu.\n' >&2; exit 1 ;;
esac
admin=()
if (( EUID != 0 )) && [[ "$SKIP_PACKAGES" == 0 ]]; then
  command -v sudo >/dev/null || { printf 'sudo is required for apt packages.\n' >&2; exit 1; }
  admin=(sudo)
fi
if [[ "$SKIP_PACKAGES" == 0 ]]; then
"${admin[@]}" apt-get update
"${admin[@]}" apt-get install -y --no-install-recommends \
  ca-certificates curl git zsh tmux ncurses-bin ncurses-term less man-db \
  bsdextrautils util-linux unzip xz-utils fzf zoxide direnv ripgrep fd-find bat jq \
  shellcheck shfmt bats
fi
mkdir -p "$HOME/.terminfo"
tic -x -o "$HOME/.terminfo" "$SCRIPT_DIR/../assets/terminfo/xterm-ghostty.terminfo"

LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
DOWNLOAD_DIR="${DOTFILES_DOWNLOAD_DIR:-$HOME/.cache/dotfiles/downloads}"
mkdir -p "$LOCAL_BIN" "$DOWNLOAD_DIR"
export PATH="$LOCAL_BIN:$PATH"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

asset_archive() {
  local key="$1" file
  file="$(pinned_asset_field "$key" file)"
  if [[ -f "$DOWNLOAD_DIR/$file" ]]; then
    require_pinned_file "$key" "$DOWNLOAD_DIR" || { printf 'Invalid cached checksum: %s\n' "$file" >&2; return 1; }
  else
    download_pinned_asset "$key" "$DOWNLOAD_DIR" || { printf 'Download/checksum failed: %s\n' "$key" >&2; return 1; }
  fi
  printf '%s\n' "$DOWNLOAD_DIR/$file"
}

install_tool() {
  local tool="$1" key="$2" member="$3" archive stage
  archive="$(asset_archive "$key")"
  stage="$work_dir/$tool"
  mkdir -p "$stage"
  tar -xzf "$archive" -C "$stage"
  [[ -f "$stage/$member" ]] || { printf 'Missing archive member: %s\n' "$member" >&2; return 1; }
  install -m 755 "$stage/$member" "$LOCAL_BIN/$tool"
}

ln -sfn /usr/bin/fdfind "$LOCAL_BIN/fd"
ln -sfn /usr/bin/batcat "$LOCAL_BIN/bat"
install_tool starship starship-linux-x86_64 starship
install_tool eza eza-linux-x86_64 eza
delta_file="$(pinned_asset_field delta-linux-x86_64 file)"
install_tool delta delta-linux-x86_64 "${delta_file%.tar.gz}/delta"
install_tool lazygit lazygit-linux-x86_64 lazygit
install_tool chezmoi chezmoi-linux-amd64 chezmoi
install_tool just just-linux-x86_64 just

# Extract to a versioned user directory; keep any previous version for rollback.
nvim_archive="$(asset_archive neovim-linux-x86_64)"
nvim_version="$(pinned_asset_field neovim-linux-x86_64 version)"
nvim_dir="$HOME/.local/opt/nvim-$nvim_version"
mkdir -p "$nvim_dir"
tar -xzf "$nvim_archive" -C "$nvim_dir" --strip-components=1
ln -sfn "$nvim_dir/bin/nvim" "$LOCAL_BIN/nvim"
printf 'Server tools installed for %s. Fonts belong on the SSH client.\n' "$(id -un)"
