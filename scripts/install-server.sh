#!/usr/bin/env bash
# Debian/Ubuntu SSH environment; user tools stay in ~/.local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"

# shellcheck source=scripts/preflight.sh
. "$SCRIPT_DIR/preflight.sh"
SKIP_PACKAGES=0
SETUP_EDITOR=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) printf 'Usage: %s [--skip-packages] [--setup-editor]\nInstalls SSH shell, terminal tools and Neovim on Debian/Ubuntu x86_64.\n--setup-editor also installs the pinned Go, Node.js and Python build prerequisites used by Mason.\n' "$0"; exit 0 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --setup-editor) SETUP_EDITOR=1 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done
preflight_linux server
ARCH="$(pinned_asset_arch)" || {
  printf 'Server installer currently requires Linux x86_64.\n' >&2; exit 1;
}
GO_ARCH="$(pinned_asset_go_arch)" || {
  printf 'Server installer does not support this architecture: %s\n' "$(uname -m)" >&2; exit 1;
}
[[ "$ARCH" == x86_64 ]] || {
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
  editor_packages=()
  if [[ "$SETUP_EDITOR" == 1 ]]; then
    editor_packages+=(build-essential python3 python3-venv)
  fi
"${admin[@]}" apt-get update
"${admin[@]}" apt-get install -y --no-install-recommends \
  ca-certificates curl git zsh tmux ncurses-bin ncurses-term less man-db \
  bsdextrautils util-linux unzip xz-utils fzf zoxide direnv ripgrep fd-find bat jq \
  shellcheck shfmt bats "${editor_packages[@]}"
fi
mkdir -p "$HOME/.terminfo"
tic -x -o "$HOME/.terminfo" "$SCRIPT_DIR/../assets/terminfo/xterm-ghostty.terminfo"

LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
DOWNLOAD_DIR="${DOTFILES_DOWNLOAD_DIR:-$HOME/.cache/dotfiles/downloads}"
mkdir -p "$LOCAL_BIN" "$DOWNLOAD_DIR"
export PATH="$LOCAL_BIN:$PATH"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

install_tool() {
  local tool="$1" key="$2" member="$3" archive stage
  asset_version_matches "$tool" "$key" && return 0
  archive="$(cached_asset_path "$key" "$DOWNLOAD_DIR")"
  stage="$work_dir/$tool"
  mkdir -p "$stage"
  tar -xzf "$archive" -C "$stage"
  [[ -f "$stage/$member" ]] || { printf 'Missing archive member: %s\n' "$member" >&2; return 1; }
  install -m 755 "$stage/$member" "$LOCAL_BIN/$tool"
}

install_runtime() {
  local tool="$1" key="$2" member="$3" version archive stage destination
  version="$(pinned_asset_field "$key" version)"
  archive="$(cached_asset_path "$key" "$DOWNLOAD_DIR")"
  mkdir -p "$HOME/.local/opt"
  destination="$HOME/.local/opt/$tool-$version"
  if [[ ! -x "$destination/$member" ]]; then
    stage="$(mktemp -d "$HOME/.local/opt/$tool-stage.XXXXXX")"
    if ! tar -xf "$archive" -C "$stage" --strip-components=1 || [[ ! -x "$stage/$member" ]]; then
      rm -rf "$stage"
      printf 'Invalid runtime archive: %s\n' "$key" >&2
      return 1
    fi
    [[ ! -e "$destination" ]] || { rm -rf "$stage"; printf 'Incomplete runtime directory: %s\n' "$destination" >&2; return 1; }
    mv "$stage" "$destination"
  fi
  ln -sfn "$destination/$member" "$LOCAL_BIN/$tool"
}

install_go() {
  install_runtime go "go-linux-$GO_ARCH" bin/go
  ln -sfn "$(dirname "$(readlink "$LOCAL_BIN/go")")/gofmt" "$LOCAL_BIN/gofmt"
}

install_node() {
  install_runtime node "node-linux-$ARCH" bin/node
  local binary directory
  directory="$(dirname "$(readlink "$LOCAL_BIN/node")")"
  for binary in npm npx corepack; do
    [[ ! -x "$directory/$binary" ]] || ln -sfn "$directory/$binary" "$LOCAL_BIN/$binary"
  done
}

command -v fdfind >/dev/null || { printf "fdfind is required\n" >&2; exit 1; }
ln -sfn "$(command -v fdfind)" "$LOCAL_BIN/fd"
command -v batcat >/dev/null || { printf "batcat is required\n" >&2; exit 1; }
ln -sfn "$(command -v batcat)" "$LOCAL_BIN/bat"
install_tool starship starship-linux-x86_64 starship
install_tool eza eza-linux-x86_64 eza
delta_file="$(pinned_asset_field delta-linux-x86_64 file)"
install_tool delta delta-linux-x86_64 "${delta_file%.tar.gz}/delta"
install_tool lazygit lazygit-linux-x86_64 lazygit
install_tool chezmoi chezmoi-linux-amd64 chezmoi
install_tool just just-linux-x86_64 just

# Extract to a versioned user directory; keep any previous version for rollback.
nvim_archive="$(cached_asset_path neovim-linux-x86_64 "$DOWNLOAD_DIR")"
nvim_version="$(pinned_asset_field neovim-linux-x86_64 version)"
nvim_dir="$HOME/.local/opt/nvim-$nvim_version"
if [[ ! -x "$nvim_dir/bin/nvim" ]]; then
  mkdir -p "$HOME/.local/opt"
  stage="$(mktemp -d "$HOME/.local/opt/nvim-stage.XXXXXX")"
  tar -xzf "$nvim_archive" -C "$stage" --strip-components=1
  [[ -x "$stage/bin/nvim" && ! -e "$nvim_dir" ]] || { rm -rf "$stage"; exit 1; }
  mv "$stage" "$nvim_dir"
fi
ln -sfn "$nvim_dir/bin/nvim" "$LOCAL_BIN/nvim"
if [[ "$SETUP_EDITOR" == 1 ]]; then
  if ! asset_version_matches go "go-linux-$GO_ARCH" version; then
    install_go
  fi
  if ! asset_version_matches node "node-linux-$ARCH" --version; then
    install_node
  fi
fi
printf 'Server tools installed for %s. Fonts belong on the SSH client.\n' "$(id -un)"
