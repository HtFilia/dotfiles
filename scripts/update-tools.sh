#!/usr/bin/env bash
# Upgrade packages and user tools using the selected deployment profile.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/profile.sh
. "$SCRIPT_DIR/profile.sh"
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
        args+=(--setup-editor)
      fi
      run "$SCRIPT_DIR/install-server.sh" "${args[@]}"
      if [[ -f "$HOME/.local/state/dotfiles/editor-languages" ]]; then
        read -ra languages < "$HOME/.local/state/dotfiles/editor-languages"
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
(( dry_run )) || printf 'Tool update complete. Open a new shell, then run scripts/verify.sh.\n'
