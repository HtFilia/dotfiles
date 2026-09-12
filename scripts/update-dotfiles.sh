#!/usr/bin/env bash
# Snapshot live contents before updating a symlink-backed source checkout.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
case "${1:-}" in
  -h|--help) printf 'Usage: %s\nRequires a clean checkout and SSH origin. Snapshots contents, pulls fast-forward, then applies saved profile.\n' "$0"; exit 0 ;;
  '') [[ $# == 0 ]] || exit 1 ;;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
esac
[[ -z "$(git -C "$REPO_ROOT" status --porcelain)" ]] || { printf 'Commit or stash local changes before updating.\n' >&2; exit 1; }
case "$(git -C "$REPO_ROOT" remote get-url origin)" in
  git@github.com:*|ssh://git@github.com/*) ;;
  *) printf 'Configure origin with your GitHub SSH URL first.\n' >&2; exit 1 ;;
esac
"$SCRIPT_DIR/apply-dotfiles.sh" --snapshot-only
git -C "$REPO_ROOT" pull --ff-only
"$SCRIPT_DIR/apply-dotfiles.sh"
