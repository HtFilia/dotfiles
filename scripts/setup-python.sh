#!/usr/bin/env bash
# Explicit optional managed interpreter, pinned to a verified GitHub release.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  -h|--help) printf 'Usage: %s\nInstall pinned Python 3.14.7 as ~/.local/bin/python3.14; leave system Python unchanged.\n' "$0"; exit 0 ;;
  '') [[ $# == 0 ]] || exit 2 ;;
  *) exit 2 ;;
esac
# shellcheck source=scripts/corporate-preflight.sh
. "$SCRIPT_DIR/corporate-preflight.sh"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"
corporate_platform workstation
corporate_repository "$(cd "$SCRIPT_DIR/.." && pwd)"
key=python-linux-x86_64
version="$(pinned_asset_field "$key" version)"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
mkdir -p "$HOME/.local/opt" "$LOCAL_BIN"
destination="$HOME/.local/opt/python-$version"
if [[ ! -x "$destination/bin/python3.14" ]]; then
  archive="$(cached_asset_path "$key" "${DOTFILES_DOWNLOAD_DIR:-$HOME/.cache/dotfiles/downloads}")"
  stage="$(mktemp -d "$HOME/.local/opt/python-stage.XXXXXX")"
  trap 'rm -rf "$stage"' EXIT
  extract_pinned_archive "$archive" "$stage"
  "$stage/python/bin/python3.14" --version | grep -Fx "Python $version"
  [[ ! -e "$destination" ]] || { printf 'Incomplete Python prefix; inspect it before retrying.\n' >&2; exit 1; }
  mv "$stage/python" "$destination"
fi
"$destination/bin/python3.14" --version | grep -Fx "Python $version"
ln -sfnT "$destination/bin/python3.14" "$LOCAL_BIN/python3.14"
printf 'Managed Python installed; use uv venv --python %s explicitly.\n' "$LOCAL_BIN/python3.14"
