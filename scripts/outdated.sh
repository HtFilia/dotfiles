#!/usr/bin/env bash
# List the releases pinned in home/.chezmoiexternal.toml.tmpl, and the editor
# tools pinned in home/.chezmoidata/packages.yaml, next to each project's
# latest release. Read-only; needs gh, npm, curl, jq and yq. To upgrade one,
# follow docs/SUPPLY-CHAIN.md.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stale=0
# report NAME PINNED LATEST
report() {
  if [[ "$3" == "$2" ]]; then
    printf 'ok       %-28s %s\n' "$1" "$2"
  else
    printf 'OUTDATED %-28s %s -> %s\n' "$1" "$2" "$3"
    stale=$((stale + 1))
  fi
}
# Each pinned URL names its repository and tag:
# github.com/OWNER/REPO/releases/download/TAG/… or …/archive/refs/tags/TAG.tar.gz
while read -r repository pinned; do
  report "$repository" "$pinned" "$(gh release view --repo "$repository" --json tagName --jq .tagName 2>/dev/null || echo '?')"
done < <(sed -nE \
  -e 's#.*github\.com/([^/]+/[^/]+)/releases/download/([^/]+)/.*#\1 \2#p' \
  -e 's#.*github\.com/([^/]+/[^/]+)/archive/refs/tags/(.+)\.tar\.gz.*#\1 \2#p' \
  "$root/home/.chezmoiexternal.toml.tmpl" | sort -u)
packages="$root/home/.chezmoidata/packages.yaml"
while IFS='=' read -r name pinned _; do
  report "$name (PyPI)" "$pinned" "$(curl -fsS "https://pypi.org/pypi/$name/json" 2>/dev/null | jq -r .info.version || echo '?')"
done < <(yq -r '.editor.uv[][]' "$packages" | sed 's/==/=/')
while IFS='@' read -r name pinned; do
  # TypeScript stays on the last 6.x: see the comment in packages.yaml.
  [[ "$name" == typescript ]] && range='typescript@6' || range="$name"
  report "$name (npm)" "$pinned" "$(npm view "$range" version --json 2>/dev/null | jq -r 'if type == "array" then .[-1] else . end' || echo '?')"
done < <(yq -r '.editor.npm[][]' "$packages")
printf '%s pinned release(s) behind.\n' "$stale"
