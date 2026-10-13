#!/usr/bin/env bash
# Independent workstation installs with native/GitHub/source fallbacks.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/preflight.sh
. "$SCRIPT_DIR/preflight.sh"
# shellcheck source=scripts/install-report.sh
. "$SCRIPT_DIR/install-report.sh"
ENV_TYPE=linux
if [[ $# -gt 0 && "$1" != --* ]]; then ENV_TYPE="$1"; shift; fi
skip_packages=0 skip_docker=0 enable_docker_group=0
methods="${DOTFILES_INSTALL_METHODS:-github,native,source}"
while (( $# )); do
  case "$1" in
    --skip-packages) skip_packages=1 ;;
    --skip-docker) skip_docker=1 ;;
    --enable-docker-group) enable_docker_group=1 ;;
    --methods) [[ $# -ge 2 ]] || exit 2; methods="$2"; shift ;;
    -h|--help) printf 'Usage: %s [linux|wsl] [--methods github,native,source] [--skip-packages] [--skip-docker] [--enable-docker-group]\n' "$0"; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
[[ "$ENV_TYPE" == linux || "$ENV_TYPE" == wsl ]] || exit 2
# Validate the order before touching the host.
validate_install_methods "$methods"
(( ! enable_docker_group || (! skip_docker && ! skip_packages) )) || { printf 'Docker group requires Docker package installation.\n' >&2; exit 2; }
preflight_linux workstation
if ! command -v python3 >/dev/null; then
  (( ! skip_packages )) || { printf 'python3 is essential; install it before --skip-packages.\n' >&2; exit 1; }
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends python3
fi
python3 "$SCRIPT_DIR/install-tools.py" --methods "$methods" --dry-run >/dev/null
report_init
trap report_location EXIT
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
if (( ! skip_packages )); then
  report_optional apt-index sudo apt-get update
  # Build prerequisites are best effort; missing libraries are explained by each build's log.
  report_optional build-prerequisites sudo apt-get install -y --no-install-recommends \
    build-essential ca-certificates unzip xz-utils pkg-config libssl-dev python3-pip python3-venv \
    autoconf automake libtool cmake ninja-build gettext libevent-dev libncurses-dev byacc \
    ncurses-term ncurses-bin less bsdextrautils fontconfig gnupg lsb-release
fi
args=(--methods "$methods")
(( ! skip_packages )) || args+=(--skip-packages)
(( ! skip_docker )) || args+=(--exclude lazydocker)
python3 "$SCRIPT_DIR/install-tools.py" "${args[@]}"
if (( skip_docker || skip_packages )) || [[ "$ENV_TYPE" == wsl ]]; then
  python3 "$SCRIPT_DIR/install-tools.py" --record docker --reason "Docker APT setup disabled (skip-docker=$skip_docker, skip-packages=$skip_packages, environment=$ENV_TYPE)"
else
  report_optional docker "$SCRIPT_DIR/install-docker.sh" "$ENV_TYPE" "$skip_docker" "$skip_packages" "$enable_docker_group"
fi
printf 'Workstation tool installation complete; review optional failures in the report.\n'
