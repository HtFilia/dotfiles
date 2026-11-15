#!/usr/bin/env bash
# List the releases pinned in home/.chezmoiexternal.toml.tmpl next to each
# project's latest release. Read-only; needs gh. To upgrade one, follow
# docs/SUPPLY-CHAIN.md.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stale=0
# Each pinned URL names its repository and tag:
# github.com/OWNER/REPO/releases/download/TAG/… or …/archive/refs/tags/TAG.tar.gz
while read -r repository pinned; do
  latest="$(gh release view --repo "$repository" --json tagName --jq .tagName 2>/dev/null || echo '?')"
  if [[ "$latest" == "$pinned" ]]; then
    printf 'ok       %-22s %s\n' "$repository" "$pinned"
  else
    printf 'OUTDATED %-22s %s -> %s\n' "$repository" "$pinned" "$latest"
    stale=$((stale + 1))
  fi
done < <(sed -nE \
  -e 's#.*github\.com/([^/]+/[^/]+)/releases/download/([^/]+)/.*#\1 \2#p' \
  -e 's#.*github\.com/([^/]+/[^/]+)/archive/refs/tags/(.+)\.tar\.gz.*#\1 \2#p' \
  "$root/home/.chezmoiexternal.toml.tmpl" | sort -u)
printf '%s pinned release(s) behind.\n' "$stale"
