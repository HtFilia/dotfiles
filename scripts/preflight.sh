#!/usr/bin/env bash
# Read-only checks shared by Linux entrypoints.
preflight_linux() {
  local profile="$1"
  [[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || {
    printf 'Linux profiles support x86_64 only.\n' >&2; return 1;
  }
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}:${VERSION_ID:-}" in
    debian:13) ;;
    *) printf 'Supported Linux release: Debian 13.\n' >&2; return 1 ;;
  esac
  if [[ "$profile" == workstation ]]; then
    (( EUID != 0 )) || { printf 'Run workstation bootstrap as your regular user.\n' >&2; return 1; }
    command -v sudo >/dev/null || { printf 'sudo is required.\n' >&2; return 1; }
  fi
}
