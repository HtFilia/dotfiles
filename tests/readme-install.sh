#!/usr/bin/env bash
# Print the README install commands for one operating system, answering
# chezmoi's questions and pointing it at another repository URL.
# Usage: tests/readme-install.sh fedora|debian URL [CHEZMOI-INIT-FLAGS...]
# An empty URL keeps chezmoi on an existing source directory.
set -euo pipefail
os="${1:?operating system}"
url="${2?repository URL}"
shift 2
readme="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/README.md"
commands="$(awk -v marker="<!-- install:$os -->" '
  $0 == marker { found = 1; next }
  found && /^```sh$/ { inside = 1; next }
  inside && /^```$/ { exit }
  inside { print }' "$readme")"
init='chezmoi init --apply HtFilia'
if [[ "$commands" != *"$init" ]]; then
  printf 'README.md: the %s install block must end with: %s\n' "$os" "$init" >&2
  exit 1
fi
replacement="chezmoi init --apply${*:+ $*}${url:+ $url}"
printf '%s\n' "${commands//"$init"/$replacement}"
