#!/usr/bin/env bash
# Snapshot live contents before updating a symlink-backed source checkout.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PULL=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      printf 'Usage: %s [--after-pull]\nRequires a clean checkout and approved GitHub origin. Snapshots contents, pulls fast-forward, then applies the saved profile.\nUse --after-pull when git pull was already run manually.\n' "$0"
      exit 0
      ;;
    --after-pull|--no-pull) PULL=0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done
[[ -z "$(git -C "$REPO_ROOT" status --porcelain)" ]] || { printf 'Commit or stash local changes before updating.\n' >&2; exit 1; }
# shellcheck source=scripts/corporate-preflight.sh
. "$SCRIPT_DIR/corporate-preflight.sh"
corporate_repository "$REPO_ROOT"
case "$(git -C "$REPO_ROOT" remote get-url origin)" in
  https://github.com/HtFilia/dotfiles.git|git@github.com:HtFilia/dotfiles.git|ssh://git@github.com/HtFilia/dotfiles.git) ;;
  *) printf 'Use an approved GitHub origin for this repository.\n' >&2; exit 1 ;;
esac
if [[ "$PULL" == 1 ]]; then
  upstream="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')" || {
    printf 'Set upstream to origin/environment/corporate before pulling.\n' >&2; exit 1;
  }
  [[ "$upstream" == origin/environment/corporate ]] || {
    printf 'Corporate updater refuses a different upstream branch.\n' >&2; exit 1;
  }
fi
"$SCRIPT_DIR/apply-dotfiles.sh" --snapshot-only
if [[ "$PULL" == 1 ]]; then
  git -C "$REPO_ROOT" pull --ff-only
fi
"$SCRIPT_DIR/apply-dotfiles.sh"
