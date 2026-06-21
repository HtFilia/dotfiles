#!/usr/bin/env bash
# Deploy dotfiles with Chezmoi, using this repository's home/ as source state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="${DOTFILES_SOURCE_DIR:-$REPO_ROOT/home}"
DESTINATION="${DOTFILES_DESTINATION:-$HOME}"
CHEZMOI_MODE="${DOTFILES_CHEZMOI_MODE:-symlink}"
CHEZMOI_STATE="${DOTFILES_CHEZMOI_STATE:-}"
DRY_RUN=0
FORCE=0

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  +\033[0m %s\n" "$*"; }
warn() { printf "\033[0;33m  !\033[0m %s\n" "$*" >&2; }
fatal() { printf "\033[0;31m  x\033[0m %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --destination PATH       apply dotfiles to PATH instead of \$HOME
  --source PATH            use PATH as Chezmoi source state
  --materialize MODE       Chezmoi materialization mode: symlink or file
  --dry-run                print actions without changing files
  --force                  allow Chezmoi to overwrite changed targets
  -h, --help               show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --destination)
      [[ $# -ge 2 && "$2" != --* ]] || fatal "--destination requires a value"
      DESTINATION="$2"
      shift
      ;;
    --source)
      [[ $# -ge 2 && "$2" != --* ]] || fatal "--source requires a value"
      SOURCE_DIR="$2"
      shift
      ;;
    --materialize)
      [[ $# -ge 2 && "$2" != --* ]] || fatal "--materialize requires a value"
      CHEZMOI_MODE="$2"
      shift
      ;;
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done

case "$CHEZMOI_MODE" in
  symlink|file) ;;
  *) fatal "--materialize must be 'symlink' or 'file'" ;;
esac
[[ -n "$CHEZMOI_STATE" ]] || CHEZMOI_STATE="$DESTINATION/.local/state/chezmoi/chezmoistate.boltdb"

command -v chezmoi >/dev/null 2>&1 || fatal "chezmoi is required. Run ./scripts/bootstrap.sh or install it from https://chezmoi.io."
[[ -d "$SOURCE_DIR" ]] || fatal "Chezmoi source directory not found: $SOURCE_DIR"
mkdir -p "$DESTINATION"
mkdir -p "$(dirname "$CHEZMOI_STATE")"

configure_git_identity() {
  local local_cfg="$DESTINATION/.gitconfig.local"
  [[ -e "$local_cfg" ]] && return 0
  if [[ "$DRY_RUN" == "1" ]]; then
    info "would create $local_cfg if git identity is provided"
    return 0
  fi

  local name="${DOTFILES_GIT_NAME:-}" email="${DOTFILES_GIT_EMAIL:-}"
  if [[ -z "$name" && -t 0 && "$DESTINATION" == "$HOME" ]]; then
    printf "Git user.name: "
    read -r name
  fi
  if [[ -z "$email" && -t 0 && "$DESTINATION" == "$HOME" ]]; then
    printf "Git user.email: "
    read -r email
  fi
  if [[ -n "$name" && -n "$email" ]]; then
    {
      printf '[user]\n'
      printf '    name = %s\n' "$name"
      printf '    email = %s\n' "$email"
    } >"$local_cfg"
    chmod 600 "$local_cfg"
    success "created $local_cfg"
  else
    warn "git identity not configured; create $local_cfg later"
  fi
}

refresh_bat_cache() {
  command -v bat >/dev/null 2>&1 || return 0
  [[ "$DRY_RUN" == "1" ]] && { info "would rebuild bat theme cache"; return 0; }
  [[ "$DESTINATION" != "$HOME" ]] && return 0
  if bat cache --build >/dev/null 2>&1; then
    success "rebuilt bat theme cache"
  else
    warn "could not rebuild bat theme cache; run: bat cache --build"
  fi
}

log "Deploying dotfiles with Chezmoi"
info "source: $SOURCE_DIR"
info "destination: $DESTINATION"
info "materialize: $CHEZMOI_MODE"

configure_git_identity

chezmoi_args=(
  --config /dev/null
  --config-format toml
  --persistent-state "$CHEZMOI_STATE"
  --source "$SOURCE_DIR"
  --destination "$DESTINATION"
  --mode "$CHEZMOI_MODE"
  --no-tty
)
[[ "$DRY_RUN" == "1" ]] && chezmoi_args+=(--dry-run)
[[ "$FORCE" == "1" ]] && chezmoi_args+=(--force)

chezmoi "${chezmoi_args[@]}" apply
refresh_bat_cache
success "dotfiles deployed"
