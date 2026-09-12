#!/usr/bin/env bash
# Explicit provisioning; package downloads happen only on this command.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$PATH"
case "${1:-}" in
  -h|--help) printf 'Usage: %s [lua|python|go|rust|node|shell ...]\nDefault: lua python go rust node shell. Requires Node/npm and a C compiler.\n' "$0"; exit 0 ;;
esac
[[ $# -gt 0 ]] || set -- lua python go rust node shell
for language in "$@"; do
  case "$language" in lua|python|go|rust|node|shell) ;; *) printf 'Unknown language: %s\n' "$language" >&2; exit 1 ;; esac
done
for tool in nvim git node npm cc; do
  command -v "$tool" >/dev/null || { printf 'Required tool missing: %s\n' "$tool" >&2; exit 1; }
done
export DOTFILES_EDITOR_LANGUAGES="$*"
export DOTFILES_EDITOR_SETUP="$SCRIPT_DIR/editor-setup.lua"
nvim --headless '+Lazy! restore' '+qa'
nvim --headless '+lua dofile(vim.env.DOTFILES_EDITOR_SETUP)'
