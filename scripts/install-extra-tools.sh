#!/usr/bin/env bash
# Verified standalone workstation tools. Does not run sudo or upstream installers.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"
case "${1:-}" in
  -h|--help) printf 'Usage: %s\nInstall pinned Linux x86_64 workstation tools in ~/.local/bin.\n' "$0"; exit 0 ;;
  '') [[ $# == 0 ]] || exit 1 ;;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
esac
[[ "$(uname -s):$(uname -m)" == Linux:x86_64 ]] || exit 1
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
DOWNLOAD_DIR="${DOTFILES_DOWNLOAD_DIR:-$HOME/.cache/dotfiles/downloads}"
mkdir -p "$LOCAL_BIN" "$DOWNLOAD_DIR"
export PATH="$LOCAL_BIN:$PATH"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
while IFS=$'\t' read -r tool key member; do
  [[ -n "$tool" && "$tool" != \#* ]] || continue
  argument=--version
  [[ "$tool" != tmux ]] || argument=-V
  if asset_version_matches "$tool" "$key" "$argument"; then continue; fi
  printf 'Installing %s %s\n' "$tool" "$(pinned_asset_field "$key" version)"
  archive="$(cached_asset_path "$key" "$DOWNLOAD_DIR")"
  stage="$work_dir/$tool"
  mkdir -p "$stage"
  if [[ "$member" == @binary ]]; then
    atomic_install_binary "$archive" "$LOCAL_BIN/$tool"
  elif [[ "$member" == @tmux ]]; then
    pkg-config --exists libevent ncursesw || {
      printf 'tmux build needs libevent-dev, libncurses-dev, pkg-config and a compiler.\n' >&2
      exit 1
    }
    tar -xf "$archive" -C "$stage" --strip-components=1
    (cd "$stage" && ./configure --prefix="$HOME/.local" && make -j2)
    atomic_install_binary "$stage/tmux" "$LOCAL_BIN/tmux"
  else
    extract_pinned_archive "$archive" "$stage"
    matches=()
    while IFS= read -r -d '' found; do matches+=("$found"); done < <(find "$stage" -type f -path "*/$member" -print0)
    [[ ${#matches[@]} == 1 ]] || { printf 'Expected one %s in %s; found %s\n' "$member" "$archive" "${#matches[@]}" >&2; exit 1; }
    atomic_install_binary "${matches[0]}" "$LOCAL_BIN/$tool"
  fi
  asset_version_matches "$tool" "$key" "$argument" || { printf '%s did not execute at the expected version\n' "$tool" >&2; exit 1; }
done < "$SCRIPT_DIR/extra-tools.tsv"
