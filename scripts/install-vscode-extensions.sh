#!/usr/bin/env bash
# Optional, explicitly selected VSIX provisioning. Never install by Marketplace ID.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  -h|--help) printf 'Usage: %s\nInstall reviewed GitHub VSIXs from DOTFILES_VSIX_MANIFEST or ~/.config/dotfiles/vsix.json.\n' "$0"; exit 0 ;;
  '') [[ $# == 0 ]] || exit 2 ;;
  *) exit 2 ;;
esac
command -v code >/dev/null || { printf 'Selected VS Code integration requires an authorized code installation (AGENTS.md C09).\n' >&2; exit 1; }
python3 "$SCRIPT_DIR/install-vscode-extensions.py"
