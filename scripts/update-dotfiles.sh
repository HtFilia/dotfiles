#!/usr/bin/env bash
# Snapshot live contents before updating a symlink-backed source checkout.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PULL=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      printf 'Usage: %s [--after-pull]\nRequires a clean checkout and SSH origin. Snapshots contents, pulls fast-forward, then applies the saved profile.\nUse --after-pull when git pull was already run manually.\n' "$0"
      exit 0
      ;;
    --after-pull|--no-pull) PULL=0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done
[[ -z "$(git -C "$REPO_ROOT" status --porcelain)" ]] || { printf 'Commit or stash local changes before updating.\n' >&2; exit 1; }
case "$(git -C "$REPO_ROOT" remote get-url origin)" in
  git@github.com:*|ssh://git@github.com/*) ;;
  *) printf 'Configure origin with your GitHub SSH URL first.\n' >&2; exit 1 ;;
esac
"$SCRIPT_DIR/apply-dotfiles.sh" --snapshot-only
if [[ "$PULL" == 1 ]]; then
  git -C "$REPO_ROOT" pull --ff-only
fi
"$SCRIPT_DIR/apply-dotfiles.sh"
