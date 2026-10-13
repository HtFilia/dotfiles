#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  -h|--help) printf 'Usage: %s [--methods github,native,source] [--skip-packages] [--dry-run]\n' "$0"; exit 0 ;;
esac
exec python3 "$SCRIPT_DIR/install-tools.py" --group extra "$@"
