#!/usr/bin/env bash
# Upgrade packages and user tools using the selected deployment profile.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/profile.sh
. "$SCRIPT_DIR/profile.sh"
# shellcheck source=scripts/pinned-plugins.sh
. "$SCRIPT_DIR/pinned-plugins.sh"
skip_packages=0 dry_run=0 explicit_profile=""
while (( $# )); do
  case "$1" in
    --skip-packages) skip_packages=1 ;;
    --dry-run) dry_run=1 ;;
    --profile) [[ $# -ge 2 ]] || { printf 'Missing profile\n' >&2; exit 2; }; explicit_profile="$2"; shift ;;
    -h|--help) printf 'Usage: %s [--profile server|workstation] [--skip-packages] [--dry-run]\n' "$0"; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
profile="$(dotfiles_profile "$explicit_profile")" || exit 2
if [[ "$(uname -s)" == Linux ]]; then
  # shellcheck source=scripts/preflight.sh
  . "$SCRIPT_DIR/preflight.sh"
  preflight_linux "$profile"
  (( EUID != 0 )) || { printf 'Run as the regular user.\n' >&2; exit 2; }
fi
# Validate saved selections before any package mutation.
if [[ "$profile" == server && -f "$HOME/.local/state/dotfiles/editor-languages" ]]; then
  read -ra languages < "$HOME/.local/state/dotfiles/editor-languages"
  (( ${#languages[@]} )) || { printf 'Empty editor selection.\n' >&2; exit 2; }
  # shellcheck source=scripts/server-packages.sh
  . "$SCRIPT_DIR/server-packages.sh"
  dotfiles_server_editor_packages "${languages[@]}" >/dev/null
fi
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
run() {
  if (( dry_run )); then printf 'would run:'; printf ' %q' "$@"; printf '\n';
  else "$@"; fi
}
printf 'Tool update: profile=%s, packages=%s\n' "$profile" "$([[ "$skip_packages" == 1 ]] && printf skipped || printf enabled)"
case "$(uname -s)" in
  Darwin)
    [[ "$profile" == workstation ]] || { printf 'Server profile requires Linux\n' >&2; exit 2; }
    [[ "$skip_packages" == 0 ]] || { printf '%s\n' '--skip-packages is unavailable on macOS' >&2; exit 2; }
    run "$SCRIPT_DIR/install-macos.sh"
    ;;
  Linux)
    if (( ! skip_packages )); then
      run sudo apt-get update
      run sudo apt-get upgrade --with-new-pkgs --no-remove -y
    fi
    if [[ "$profile" == server ]]; then
      args=()
      (( skip_packages )) && args+=(--skip-packages)
      if [[ -f "$HOME/.local/state/dotfiles/editor-languages" ]]; then
        read -ra languages < "$HOME/.local/state/dotfiles/editor-languages"
        languages_csv="$(IFS=,; printf '%s' "${languages[*]}")"
        args+=(--editor-languages "$languages_csv")
      fi
      run "$SCRIPT_DIR/install-server.sh" "${args[@]}"
      if [[ -f "$HOME/.local/state/dotfiles/editor-languages" ]]; then
        run "$SCRIPT_DIR/setup-editor.sh" "${languages[@]}"
      fi
    else
      if command -v rustup >/dev/null 2>&1; then run rustup update stable; fi
      args=(linux)
      if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/sys/kernel/osrelease; then args=(wsl); fi
      (( skip_packages )) && args+=(--skip-packages)
      run "$SCRIPT_DIR/install-debian.sh" "${args[@]}"
      # shellcheck source=scripts/runtime-versions.sh
      . "$SCRIPT_DIR/runtime-versions.sh"
      run uv python install --default "$PYTHON_VERSION"
    fi

    ;;
  *) printf 'Unsupported platform\n' >&2; exit 2 ;;
esac
if [[ "$(cat "$HOME/.local/state/dotfiles/shell-plugins" 2>/dev/null || true)" == installed ]]; then
  if (( dry_run )); then
    printf 'would update pinned zsh-autosuggestions and zsh-syntax-highlighting checkouts\n'
  else
    prepare_zsh_plugin_parents
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
      install_pinned_plugin "$plugin" "$HOME/.local/share/zsh/plugins"
    done
  fi
fi
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  if (( dry_run )); then printf "would update pinned tmux TPM checkout\n";
  else install_pinned_plugin tmux-tpm "$HOME/.tmux/plugins"; fi
fi
(( dry_run )) || printf 'Tool update complete. Open a new shell, then run scripts/verify.sh.\n'
