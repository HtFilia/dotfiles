#!/usr/bin/env bash
# Deploy dotfiles with Chezmoi, using this repository's home/ as source state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="${DOTFILES_SOURCE_DIR:-$REPO_ROOT/home}"
DESTINATION="${DOTFILES_DESTINATION:-$HOME}"
CHEZMOI_MODE="${DOTFILES_CHEZMOI_MODE:-}"
CHEZMOI_STATE="${DOTFILES_CHEZMOI_STATE:-}"
DRY_RUN=0
FORCE=0
SNAPSHOT_ONLY=0
PROFILE="${DOTFILES_PROFILE:-}"

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  +\033[0m %s\n" "$*"; }
warn() { printf "\033[0;33m  !\033[0m %s\n" "$*" >&2; }
fatal() { printf "\033[0;31m  x\033[0m %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --profile PROFILE        workstation (default) or server
  --destination PATH       apply dotfiles to PATH instead of \$HOME
  --source PATH            use PATH as Chezmoi source state
  --materialize MODE       Chezmoi materialization mode: symlink or file
  --dry-run                print actions without changing files
  --snapshot-only          back up live contents without applying
  --force                  allow Chezmoi to overwrite changed targets
  -h, --help               show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 && "$2" != --* ]] || fatal "--profile requires a value"
      PROFILE="$2"
      shift
      ;;
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
    --snapshot-only) SNAPSHOT_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done
if [[ -z "$PROFILE" && -f "$DESTINATION/.local/state/dotfiles/profile" ]]; then
  PROFILE="$(cat "$DESTINATION/.local/state/dotfiles/profile")"
fi
PROFILE="${PROFILE:-workstation}"
if [[ -z "$CHEZMOI_MODE" && -f "$DESTINATION/.local/state/dotfiles/materialize" ]]; then
  CHEZMOI_MODE="$(cat "$DESTINATION/.local/state/dotfiles/materialize")"
fi
[[ -n "$CHEZMOI_MODE" ]] || { if [[ "$PROFILE" == server ]]; then CHEZMOI_MODE="file"; else CHEZMOI_MODE=symlink; fi; }
case "$PROFILE" in
  workstation|server) ;;
  *) fatal "Unknown profile: $PROFILE" ;;
esac
export DOTFILES_PROFILE="$PROFILE"

case "$CHEZMOI_MODE" in
  symlink|file) ;;
  *) fatal "--materialize must be 'symlink' or 'file'" ;;
esac
[[ -n "$CHEZMOI_STATE" ]] || CHEZMOI_STATE="$DESTINATION/.local/state/chezmoi/chezmoistate.boltdb"

command -v chezmoi >/dev/null 2>&1 || fatal "chezmoi is required. Run ./scripts/bootstrap.sh or install it from https://chezmoi.io."
[[ -d "$SOURCE_DIR" ]] || fatal "Chezmoi source directory not found: $SOURCE_DIR"
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
export DOTFILES_SOURCE_DIR="$SOURCE_DIR"
if [[ "$DRY_RUN" == 1 ]]; then
  dry_state="$(mktemp -d)"
  trap 'rm -rf "$dry_state"' EXIT
  CHEZMOI_STATE="$dry_state/state.boltdb"
else
  mkdir -p "$DESTINATION" "$(dirname "$CHEZMOI_STATE")"
fi

configure_git_identity() {
  local local_cfg="$DESTINATION/.gitconfig.local"
  [[ -e "$local_cfg" || -L "$local_cfg" ]] && return 0
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
    local stage
    stage="$(mktemp "$DESTINATION/.gitconfig.local.XXXXXX")"
    chmod 600 "$stage"
    git config --file "$stage" user.name "$name"
    git config --file "$stage" user.email "$email"
    mv "$stage" "$local_cfg"
    success "created $local_cfg"
  else
    warn "git identity not configured; create $local_cfg later"
  fi
}

log "Deploying dotfiles with Chezmoi"
info "source: $SOURCE_DIR"
info "destination: $DESTINATION"
info "materialize: $CHEZMOI_MODE"

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

# Save existing managed files before the first write, including forced applies.
if [[ "$DRY_RUN" == 0 ]]; then
  managed="$(chezmoi "${chezmoi_args[@]}" managed --include=files,symlinks --path-style=relative)"
  backup_files=()
  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    [[ -e "$DESTINATION/$target" || -L "$DESTINATION/$target" ]] && backup_files+=("$target")
  done <<<"$managed"
  if (( ${#backup_files[@]} )); then
    backup_root="$DESTINATION/.local/state/dotfiles/backups"
    mkdir -p "$backup_root"
    backup_dir="$(mktemp -d "$backup_root/$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")"
    chmod 700 "$backup_root" "$backup_dir"
    (umask 077; tar -C "$DESTINATION" -cpf "$backup_dir/targets.tar" -- "${backup_files[@]}")
    # Keep link metadata and a separate independent content snapshot.
    content_files=()
    for target in "${backup_files[@]}"; do
      [[ ! -e "$DESTINATION/$target" ]] || content_files+=("$target")
    done
    if (( ${#content_files[@]} )); then
      (umask 077; tar -h -C "$DESTINATION" -cpf "$backup_dir/contents.tar" -- "${content_files[@]}")
    fi
    git -C "$REPO_ROOT" rev-parse HEAD >"$backup_dir/source-revision" 2>/dev/null || true
    info "backup: $backup_dir/targets.tar"
  fi
fi
[[ "$SNAPSHOT_ONLY" != 1 ]] || { success "snapshot complete"; exit 0; }
# Preserve existing host identities when introducing the local SSH include.
if [[ "$DRY_RUN" == 0 && -f "$DESTINATION/.ssh/config" && ! -e "$DESTINATION/.ssh/config.local" && ! -L "$DESTINATION/.ssh/config.local" ]]; then
  if ! grep -Eq '^[[:space:]]*Include[[:space:]]+~/.ssh/config.local' "$DESTINATION/.ssh/config"; then
    (umask 077; cp -L "$DESTINATION/.ssh/config" "$DESTINATION/.ssh/config.local")
    chmod 600 "$DESTINATION/.ssh/config.local"
    info "preserved existing SSH hosts in .ssh/config.local"
  fi
fi
configure_git_identity
chezmoi "${chezmoi_args[@]}" apply
if [[ "$DRY_RUN" == 0 ]]; then
  mkdir -p "$DESTINATION/.local/state/dotfiles"
  printf '%s\n' "$PROFILE" >"$DESTINATION/.local/state/dotfiles/profile"
  printf '%s\n' "$CHEZMOI_MODE" >"$DESTINATION/.local/state/dotfiles/materialize"
fi
success "dotfiles deployed"
