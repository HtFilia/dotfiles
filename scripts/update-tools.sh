#!/usr/bin/env bash
# Repeat approved corporate tool acquisition; system-wide upgrades stay with IT.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/profile.sh
. "$SCRIPT_DIR/profile.sh"
# shellcheck source=scripts/pinned-plugins.sh
. "$SCRIPT_DIR/pinned-plugins.sh"
# shellcheck source=scripts/corporate-preflight.sh
. "$SCRIPT_DIR/corporate-preflight.sh"
skip_packages=0 dry_run=0 explicit_profile=""
while (( $# )); do
  case "$1" in
    --skip-packages) skip_packages=1 ;;
    --dry-run) dry_run=1 ;;
    --profile) [[ $# -ge 2 ]] || exit 2; explicit_profile="$2"; shift ;;
    -h|--help) printf 'Usage: %s [--profile workstation] [--skip-packages] [--dry-run]\nNo system-wide upgrade, rustup update, or implicit interpreter download.\n' "$0"; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
profile="$(dotfiles_profile "$explicit_profile")" || exit 2
# Validate saved state before any package action.
languages=()
if [[ -f "$HOME/.local/state/dotfiles/editor-languages" ]]; then
  read -ra languages < "$HOME/.local/state/dotfiles/editor-languages"
  corporate_editor_languages "${languages[@]}"
fi
corporate_platform "$profile"
corporate_repository "$(cd "$SCRIPT_DIR/.." && pwd)"
corporate_settings
(( EUID != 0 )) || { printf 'Run as a regular user.\n' >&2; exit 2; }
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
if (( ! dry_run && ${#languages[@]} )); then
  python3 "$SCRIPT_DIR/install-editor-tools.py" --check "${languages[@]}"
fi
run() {
  if (( dry_run )); then printf 'would run:'; printf ' %q' "$@"; printf '\n';
  else "$@"; fi
}
args=(linux)
[[ -z "${WSL_DISTRO_NAME:-}" ]] || args=(wsl)
(( ! skip_packages )) || args+=(--skip-packages)
if [[ -f "$HOME/.local/state/dotfiles/skip-docker" ]]; then
  selection="$(cat "$HOME/.local/state/dotfiles/skip-docker")"
  case "$selection" in
    1) args+=(--skip-docker) ;;
    0) ;;
    *) printf 'Invalid Docker selection; refusing package changes.\n' >&2; exit 2 ;;
  esac
else
  # Updating an existing workstation must not introduce a new container engine.
  args+=(--skip-docker)
fi
run "$SCRIPT_DIR/install-debian.sh" "${args[@]}"
if (( ${#languages[@]} )); then run "$SCRIPT_DIR/setup-editor.sh" "${languages[@]}"; fi
if [[ "$(cat "$HOME/.local/state/dotfiles/shell-plugins" 2>/dev/null || true)" == installed ]]; then
  if (( dry_run )); then
    printf 'would verify pinned Zsh plugin checkouts\n'
  else
    prepare_zsh_plugin_parents
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
      install_pinned_plugin "$plugin" "$HOME/.local/share/zsh/plugins"
    done
  fi
fi
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  run install_pinned_plugin tmux-tpm "$HOME/.tmux/plugins"
fi
(( dry_run )) || printf 'Corporate tool update complete. Run scripts/verify.sh.\n'
