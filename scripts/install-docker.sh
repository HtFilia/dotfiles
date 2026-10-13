#!/usr/bin/env bash
# Publisher-supported Docker service stack; isolated from the CLI bootstrap.
set -euo pipefail
ENV_TYPE="${1:-linux}"
SKIP_DOCKER="${2:-0}"
SKIP_PACKAGES="${3:-0}"
ENABLE_DOCKER_GROUP="${4:-0}"
case "$ENV_TYPE" in -h|--help) printf 'Usage: %s [linux|wsl] [skip-docker] [skip-packages] [enable-docker-group]\n' "$0"; exit 0;; esac
# shellcheck disable=SC1091
. /etc/os-release
OS_ID="$ID"
OS_CODENAME="${VERSION_CODENAME:-}"
warn() { printf 'Warning: %s\n' "$*" >&2; }
log() { printf '==> %s\n' "$*"; }
fatal() { printf '%s\n' "$*" >&2; exit 1; }
if [[ "$SKIP_DOCKER" == "1" ]]; then
  warn "Skipped Docker installation."
elif [[ "$SKIP_PACKAGES" == "1" ]]; then
  warn "Skipped Docker package/repository changes (--skip-packages)."
elif [[ "$ENV_TYPE" == "wsl" ]]; then
  warn "WSL detected: install Docker Desktop and VS Code on Windows with WSL integration."
else
  docker_packages_ready=1
  for package in docker-ce docker-ce-cli docker-compose-plugin docker-buildx-plugin; do
    [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" == "install ok installed" ]] || docker_packages_ready=0
  done
  if [[ "$docker_packages_ready" == 1 ]] && command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; then
    :
  else
    case "$OS_ID" in
      debian|ubuntu) ;;
      *) fatal "Docker apt repository is configured only for Debian/Ubuntu, detected $OS_ID" ;;
    esac
    log "Installing Docker from official apt repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$OS_ID/gpg" | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS_ID $OS_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  fi
fi

if [[ "$ENABLE_DOCKER_GROUP" == 1 && "$SKIP_PACKAGES" == 1 ]]; then
  fatal "--enable-docker-group requires package changes; omit --skip-packages"
fi
if [[ "$ENABLE_DOCKER_GROUP" == 1 && "$SKIP_DOCKER" == 0 && "$ENV_TYPE" != wsl ]]; then
  getent group docker >/dev/null || fatal "Docker group is absent; install the engine first."
  sudo usermod -aG docker "$(id -un)"
  warn "Docker group grants root-equivalent access; log out/in."
fi
