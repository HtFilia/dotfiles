#!/usr/bin/env bash
# Deploy dotfiles with plain symlinks. No template engine, no Chezmoi.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOME_SRC="$REPO_ROOT/home"
MODE="${DOTFILES_MODE:-full}"
DRY_RUN=0
FORCE=0

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  +\033[0m %s\n" "$*"; }
warn() { printf "\033[0;33m  !\033[0m %s\n" "$*" >&2; }
fatal() { printf "\033[0;31m  x\033[0m %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [--mode full|restricted] [--dry-run] [--force]

Options:
  --mode MODE      full uses LazyVim; restricted uses local no-plugin Neovim
  --dry-run        print actions without changing files
  --force          replace existing files, but still back them up first
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 && "$2" != --* ]] || fatal "--mode requires a value"
      MODE="$2"
      shift
      ;;
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done

case "$MODE" in
  full|restricted) ;;
  *) fatal "--mode must be 'full' or 'restricted'" ;;
esac

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    info "dry-run: $*"
  else
    "$@"
  fi
}

target_for_rel() {
  local rel="$1" out="" part
  IFS='/' read -r -a parts <<<"$rel"
  for part in "${parts[@]}"; do
    if [[ "$part" == dot_* ]]; then
      part=".${part#dot_}"
    fi
    out="${out:+$out/}$part"
  done
  printf '%s/%s\n' "$HOME" "$out"
}

backup_path() {
  local dst="$1" stamp
  stamp="$(date +%Y%m%d%H%M%S)"
  printf '%s.dotfiles-bak.%s\n' "$dst" "$stamp"
}

link_path() {
  local src="$1" dst="$2"
  if [[ "$DRY_RUN" == "1" ]]; then
    info "would link $dst -> $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      info "already linked: $dst"
      return 0
    fi
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local bak
    bak="$(backup_path "$dst")"
    mv "$dst" "$bak"
    warn "backed up $dst -> $bak"
  fi
  ln -s "$src" "$dst"
  success "linked $dst"
}

refresh_bat_cache() {
  command -v bat >/dev/null 2>&1 || return 0
  if [[ "$DRY_RUN" == "1" ]]; then
    info "would rebuild bat theme cache"
    return 0
  fi
  if bat cache --build >/dev/null 2>&1; then
    success "rebuilt bat theme cache"
  else
    warn "could not rebuild bat theme cache; run: bat cache --build"
  fi
}

configure_git_identity() {
  local local_cfg="$HOME/.gitconfig.local"
  [[ -e "$local_cfg" ]] && return 0
  if [[ "$DRY_RUN" == "1" ]]; then
    info "would create $local_cfg if git identity is provided"
    return 0
  fi
  local name="${DOTFILES_GIT_NAME:-}" email="${DOTFILES_GIT_EMAIL:-}"
  if [[ -z "$name" && -t 0 ]]; then
    printf "Git user.name: "
    read -r name
  fi
  if [[ -z "$email" && -t 0 ]]; then
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

log "Deploying dotfiles (mode: $MODE)"
configure_git_identity

while IFS= read -r -d '' src; do
  rel="${src#$HOME_SRC/}"
  case "$rel" in
    dot_config/nvim-lazyvim/*|dot_config/nvim-restricted/*) continue ;;
  esac
  dst="$(target_for_rel "$rel")"
  link_path "$src" "$dst"
done < <(find "$HOME_SRC" -type f -print0 | sort -z)

if [[ "$MODE" == "restricted" ]]; then
  link_path "$HOME_SRC/dot_config/nvim-restricted" "$HOME/.config/nvim"
else
  link_path "$HOME_SRC/dot_config/nvim-lazyvim" "$HOME/.config/nvim"
fi

refresh_bat_cache
success "dotfiles deployed"
