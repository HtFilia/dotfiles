#!/usr/bin/env bash
# Restore independent contents; never extract through active managed symlinks.
set -euo pipefail
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  printf 'Usage: %s BACKUP_DIRECTORY [DESTINATION]\nRestores trusted independent content snapshots.\n' "$0"
  exit 0
fi
[[ $# -ge 1 && $# -le 2 ]] || { printf 'Usage: %s BACKUP_DIRECTORY [DESTINATION]\n' "$0" >&2; exit 1; }
backup="$(cd "$1" && pwd)"
destination="${2:-$HOME}"
[[ -f "$backup/contents.tar" ]] || { printf 'No independent content archive: %s\n' "$backup" >&2; exit 1; }
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
tar -xf "$backup/contents.tar" -C "$stage"
# Only move archived targets. Keep newly created files for explicit review.
while IFS= read -r target; do
  [[ "$target" != /* && "$target" != *..* ]] || { printf 'Unsafe archive path\n' >&2; exit 1; }
  [[ -f "$stage/$target" ]] || continue
  # Refuse symlinked parents; moving an entire managed directory is explicit.
  parent="$(dirname "$target")"
  while [[ "$parent" != . ]]; do
    [[ ! -L "$destination/$parent" ]] || { printf 'Move symlinked parent aside first: %s\n' "$destination/$parent" >&2; exit 1; }
    parent="$(dirname "$parent")"
  done
  mkdir -p "$destination/$(dirname "$target")"
  rm -f "$destination/$target"
  cp -p "$stage/$target" "$destination/$target"
done < <(tar -tf "$backup/contents.tar")
printf 'Restored contents. Review files absent from the backup separately.\n'
