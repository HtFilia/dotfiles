#!/usr/bin/env bash
# Isolated plugin operation so optional failures do not stop the bootstrap.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-plugins.sh
. "$SCRIPT_DIR/pinned-plugins.sh"
case "${1:-}" in -h|--help) printf 'Usage: %s zsh-autosuggestions|zsh-syntax-highlighting|tmux-tpm DIRECTORY\n' "$0"; exit 0;; esac
[[ $# == 2 ]] || exit 2
if [[ "$1" != tmux-tpm ]]; then prepare_zsh_plugin_parents; fi
install_pinned_plugin "$1" "$2"
