#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" != --help && "${1:-}" != -h ]] || exec bash "$(dirname "${BASH_SOURCE[0]}")/verify.sh" --help
[[ $# == 0 ]] || { printf 'Usage: %s\n' "$0" >&2; exit 1; }
exec bash "$(dirname "${BASH_SOURCE[0]}")/verify.sh" --profile server
