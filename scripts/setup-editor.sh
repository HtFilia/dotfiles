#!/usr/bin/env bash
# Explicit provisioning; package downloads happen only on this command.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$PATH"
case "${1:-}" in
  -h|--help) printf 'Usage: %s [lua|python|go|rust|node|shell ...]\nDefault: lua python go rust node shell. Python requires python3 with venv support; Go requires Go; Node or shell requires Node/npm; Treesitter requires a C compiler and tree-sitter CLI >=0.26.1. Reviewed language manifests are required; see docs/CORPORATE.md.\n' "$0"; exit 0 ;;
esac
[[ $# -gt 0 ]] || set -- lua python go rust node shell
for language in "$@"; do
  case "$language" in lua|python|go|rust|node|shell) ;; *) printf 'Unknown language: %s\n' "$language" >&2; exit 1 ;; esac
done
# shellcheck source=scripts/corporate-preflight.sh
. "$SCRIPT_DIR/corporate-preflight.sh"
corporate_platform workstation
corporate_repository "$(cd "$SCRIPT_DIR/.." && pwd)"
corporate_settings
needs_python=0
needs_go=0
needs_node=0
for language in "$@"; do
  [[ "$language" == python ]] && { needs_python=1; needs_node=1; }
  [[ "$language" == go ]] && needs_go=1
  [[ "$language" == node || "$language" == shell ]] && needs_node=1
done
required_tools=(nvim git cc tree-sitter)
(( needs_node == 1 )) && required_tools+=(node npm)
(( needs_go == 1 )) && required_tools+=(go)
(( needs_python == 1 )) && required_tools+=(python3)
for tool in "${required_tools[@]}"; do
  command -v "$tool" >/dev/null || { printf 'Required tool missing: %s\n' "$tool" >&2; exit 1; }
done
runtime_tools=()
(( needs_node == 0 )) || runtime_tools+=(node npm)
(( needs_go == 0 )) || runtime_tools+=(go)
(( needs_python == 0 )) || runtime_tools+=(python3)
for tool in "${runtime_tools[@]}"; do
  [[ -x "/usr/bin/$tool" && "$(readlink -f "$(command -v "$tool")")" == "$(readlink -f "/usr/bin/$tool")" ]] || {
    printf 'Editor runtime %s must resolve to authorized APT; rerun the corporate installer.\n' "$tool" >&2; exit 1;
  }
done
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"
asset_version_matches tree-sitter tree-sitter-linux-x86_64 || { printf 'Pinned tree-sitter 0.26.1 required; rerun corporate installer.\n' >&2; exit 1; }
asset_version_matches nvim neovim-linux-x86_64 || { printf 'Pinned Neovim required; rerun corporate installer.\n' >&2; exit 1; }
if (( needs_python == 1 )); then
  python_probe="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-editor-python.XXXXXX")"
  if ! python3 -m venv "$python_probe" >/dev/null 2>&1; then
    rm -rf "$python_probe"
    printf 'Python venv support is required for basedpyright and Ruff. Install python3-venv, then rerun this command.\n' >&2
    exit 1
  fi
  rm -rf "$python_probe"
fi
# Check all selected manifests before acquisition, then provision the closure.
python3 "$SCRIPT_DIR/install-editor-tools.py" --check "$@"
python3 "$SCRIPT_DIR/install-editor-tools.py" "$@"
export GOTOOLCHAIN=local GOPROXY="${DOTFILES_GO_PROXY:-off}" CARGO_NET_OFFLINE=true UV_PYTHON_DOWNLOADS=never
export DOTFILES_EDITOR_LANGUAGES="$*"
export DOTFILES_EDITOR_SETUP="$SCRIPT_DIR/editor-setup.lua"
DOTFILES_EDITOR_PROVISION=1 nvim --headless '+Lazy! restore' '+qa'
DOTFILES_EDITOR_PROVISION=1 nvim --headless '+lua dofile(vim.env.DOTFILES_EDITOR_SETUP)'
