#!/usr/bin/env bash
# Explicit provisioning; package downloads happen only on this command.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$PATH"
case "${1:-}" in
  -h|--help) printf 'Usage: %s [lua|python|go|rust|node|shell ...]\nDefault: lua python go rust node shell. Python setup requires python3 with venv support; Node/npm and a C compiler are also required.\n' "$0"; exit 0 ;;
esac
[[ $# -gt 0 ]] || set -- lua python go rust node shell
for language in "$@"; do
  case "$language" in lua|python|go|rust|node|shell) ;; *) printf 'Unknown language: %s\n' "$language" >&2; exit 1 ;; esac
done
needs_python=0
for language in "$@"; do
  [[ "$language" == python ]] && needs_python=1
done
required_tools=(nvim git node npm cc)
(( needs_python == 1 )) && required_tools+=(python3)
for tool in "${required_tools[@]}"; do
  command -v "$tool" >/dev/null || { printf 'Required tool missing: %s\n' "$tool" >&2; exit 1; }
done
if (( needs_python == 1 )); then
  python_probe="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-editor-python.XXXXXX")"
  if ! python3 -m venv "$python_probe" >/dev/null 2>&1; then
    rm -rf "$python_probe"
    printf 'Python venv support is required for basedpyright and Ruff. Install python3-venv, then rerun this command.\n' >&2
    exit 1
  fi
  rm -rf "$python_probe"
fi
export DOTFILES_EDITOR_LANGUAGES="$*"
export DOTFILES_EDITOR_SETUP="$SCRIPT_DIR/editor-setup.lua"
nvim --headless '+Lazy! restore' '+qa'
nvim --headless '+lua dofile(vim.env.DOTFILES_EDITOR_SETUP)'
