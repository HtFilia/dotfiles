#!/usr/bin/env bash
# Upgrade packages and user tools separately from configuration deployment.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skip_packages=0
case "${1:-}" in
  --skip-packages) skip_packages=1; [[ $# == 1 ]] || exit 1 ;;
  -h|--help) printf 'Usage: %s [--skip-packages]\nUpgrade supported system packages, pinned user tools, stable Rust and managed Python.\n' "$0"; exit 0 ;;
  '') [[ $# == 0 ]] || exit 1 ;;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
esac
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
case "$(uname -s)" in
  Darwin) "$SCRIPT_DIR/install-macos.sh" ;;
  Linux)
    if [[ "$skip_packages" == 0 ]]; then
      sudo apt-get update
      sudo apt-get upgrade --with-new-pkgs --no-remove -y
    fi
    # Existing rustup is user-owned. Project overrides and lockfiles remain authoritative.
    if command -v rustup >/dev/null 2>&1; then rustup update stable; fi
    args=(linux)
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/sys/kernel/osrelease; then args=(wsl); fi
    [[ "$skip_packages" == 0 ]] || args+=(--skip-packages)
    "$SCRIPT_DIR/install-debian.sh" "${args[@]}"
    # User-level managed Python; never replace /usr/bin/python3.
    # shellcheck source=scripts/runtime-versions.sh
    . "$SCRIPT_DIR/runtime-versions.sh"
    uv python install --default "$PYTHON_VERSION"
    ;;
  *) printf 'Unsupported platform\n' >&2; exit 1 ;;
esac
printf 'Tool update complete. Open a new shell, then run scripts/verify.sh.\n'
