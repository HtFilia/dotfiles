#!/usr/bin/env bash
# Read-only corporate checks; no secrets or endpoints are printed.
corporate_platform() {
  local profile="${1:-workstation}"
  [[ "$profile" == workstation ]] || {
    printf 'Corporate installation supports the workstation profile only; use master for personal servers.\n' >&2; return 1;
  }
  [[ "$(uname -s):$(uname -m)" == Linux:x86_64 ]] || {
    printf 'Corporate assets require Linux x86_64; resolve AGENTS.md C01 before extending support.\n' >&2; return 1;
  }
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}:${VERSION_ID:-}" in
    debian:12|debian:13) ;;
    *) printf 'Corporate installation currently supports Debian 12/13; resolve AGENTS.md C01.\n' >&2; return 1 ;;
  esac
}

corporate_repository() {
  local root="$1" branch
  branch="$(git -C "$root" symbolic-ref --quiet --short HEAD)" || {
    printf 'Use a checkout of environment/corporate before installing or updating.\n' >&2; return 1;
  }
  [[ "$branch" == environment/corporate ]] || {
    printf 'Expected environment/corporate; refusing to install/update from %s.\n' "$branch" >&2; return 1;
  }
}

corporate_apt_runtime() {
  local tool="$1" package="$2" destination="$3"
  [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" == 'install ok installed' && -x "/usr/bin/$tool" ]] || {
    printf 'Required APT runtime %s is missing; have an administrator install %s from authorized repositories.\n' "$tool" "$package" >&2; return 1;
  }
  # Do not reuse an old vendor runtime merely because it happens to be on PATH.
  [[ -d "$destination" && ! -L "$destination" && -O "$destination" ]] || return 1
  ln -sfnT "/usr/bin/$tool" "$destination/$tool"
}

corporate_editor_languages() {
  local language
  (( $# )) || { printf 'Empty editor selection.\n' >&2; return 1; }
  for language in "$@"; do
    case "$language" in lua|python|go|rust|node|shell) ;;
      *) printf 'Unknown editor language: %s\n' "$language" >&2; return 1 ;;
    esac
  done
}

corporate_settings() {
  local file="$HOME/.config/dotfiles/corporate.env"
  if [[ -f "$file" ]]; then
    [[ ! -L "$file" && -O "$file" ]] || { printf 'Unsafe corporate.env ownership.\n' >&2; return 1; }
    # This is explicitly host-owned shell configuration, never downloaded code.
    # shellcheck disable=SC1090
    . "$file"
  fi
  export NPM_CONFIG_REGISTRY="${DOTFILES_NPM_REGISTRY:-https://registry.invalid/npm/}"
  export PIP_INDEX_URL="${DOTFILES_PYTHON_REGISTRY:-https://registry.invalid/python/simple/}"
  export PIP_EXTRA_INDEX_URL="" PIP_DISABLE_PIP_VERSION_CHECK=1
  export UV_DEFAULT_INDEX="$PIP_INDEX_URL" UV_PYTHON_DOWNLOADS=never
  export GOTOOLCHAIN=local GOPROXY="${DOTFILES_GO_PROXY:-off}" CARGO_NET_OFFLINE=true
  export MISE_AUTO_INSTALL=false MISE_NOT_FOUND_AUTO_INSTALL=false
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in
    -h|--help) printf 'Usage: %s\nRead-only corporate platform, branch and APT candidate report.\n' "$0"; exit 0 ;;
    '') [[ $# == 0 ]] || exit 2 ;;
    *) exit 2 ;;
  esac
  corporate_platform workstation
  corporate_repository "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  printf 'Corporate platform/branch accepted. Registry and network availability require the AGENTS.md checks.\n'
  apt-cache policy nodejs npm golang-go rustc cargo gh docker.io docker-compose docker-buildx tokei
fi
