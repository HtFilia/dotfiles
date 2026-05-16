#!/usr/bin/env bash
# Restricted Debian 12 installer. Uses apt plus pre-downloaded pinned assets.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; PURPLE=$'\033[0;35m'; CYAN=$'\033[0;36m'
  BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; PURPLE=""; CYAN=""; BOLD=""; RESET=""
fi

log() { printf "%s==>%s %s\n" "${BLUE}${BOLD}" "$RESET" "$*"; }
success() { printf "%s  +%s %s\n" "$GREEN" "$RESET" "$*"; }
info() { printf "%s  i%s %s\n" "$CYAN" "$RESET" "$*"; }
warn() { printf "%s  !%s %s\n" "$YELLOW" "$RESET" "$*" >&2; }
skip() { printf "%s  -%s %s\n" "$PURPLE" "$RESET" "$*"; }
error() { printf "%s  x%s %s\n" "$RED" "$RESET" "$*" >&2; }
fatal() { error "$*"; exit 1; }

OFFLINE_ASSETS_DIR="${OFFLINE_ASSETS_DIR:-$HOME/dotfiles-offline-assets}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
ENABLE_BACKPORTS=0
SKIP_DOCKER=0
SKIP_FONTS=0
PULL_LATEST=0
DRY_RUN=0

declare -a INSTALLED=() FAILED=() SKIPPED=() MISSING_ASSETS=()

usage() {
  cat <<EOF
Usage: $0 [--enable-backports] [--assets-dir PATH] [--skip-docker] [--skip-fonts] [--pull-latest] [--dry-run]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable-backports) ENABLE_BACKPORTS=1 ;;
    --assets-dir) OFFLINE_ASSETS_DIR="$2"; shift ;;
    --skip-docker) SKIP_DOCKER=1 ;;
    --skip-fonts) SKIP_FONTS=1 ;;
    --pull-latest) PULL_LATEST=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    info "dry-run: $*"
  else
    "$@"
  fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

[[ -f /etc/os-release ]] || fatal "No /etc/os-release; cannot detect distro."
# shellcheck disable=SC1091
. /etc/os-release
[[ "${ID:-}" == "debian" && "${VERSION_CODENAME:-}" == "bookworm" ]] || fatal "Restricted mode targets Debian 12 bookworm. Detected: ${PRETTY_NAME:-unknown}."

ARCH="$(pinned_asset_arch)" || fatal "Unsupported architecture: $(uname -m)"
[[ "$ARCH" == "x86_64" ]] || fatal "Restricted offline manifest currently supports x86_64 only."

mkdir -p "$LOCAL_BIN" "$OFFLINE_ASSETS_DIR"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

log "Installing base packages from apt..."
apt_packages=(
  build-essential pkg-config ca-certificates curl wget unzip git git-lfs zsh tmux
  python3 python3-pip python3-venv python3-dev ripgrep fd-find bat fzf zoxide
  jq tree htop fontconfig xclip xsel direnv rust-analyzer gopls python3-pylsp
  shellcheck libssl-dev libncurses-dev
)
[[ "$SKIP_DOCKER" != "1" ]] && apt_packages+=(docker.io)
run sudo apt-get update || fatal "apt-get update failed."
run sudo apt-get install -y "${apt_packages[@]}" || fatal "Base apt install failed."
INSTALLED+=("base apt packages (${#apt_packages[@]} pkgs)")

command_exists fdfind && ! command_exists fd && run ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
command_exists batcat && ! command_exists bat && run ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"

BACKPORTS_SUITE="bookworm-backports"
backports_enabled() { apt-cache policy 2>/dev/null | grep -q " $BACKPORTS_SUITE/"; }
if [[ "$ENABLE_BACKPORTS" == "1" && ! backports_enabled ]]; then
  log "Enabling $BACKPORTS_SUITE..."
  if [[ "$DRY_RUN" == "1" ]]; then
    info "dry-run: would write /etc/apt/sources.list.d/${BACKPORTS_SUITE}.list"
  else
    printf 'deb http://deb.debian.org/debian %s main\n' "$BACKPORTS_SUITE" | sudo tee "/etc/apt/sources.list.d/${BACKPORTS_SUITE}.list" >/dev/null
  fi
  run sudo apt-get update
fi

if ! command_exists nvim && backports_enabled && apt-cache madison neovim 2>/dev/null | grep -q "$BACKPORTS_SUITE"; then
  log "Installing neovim from backports..."
  run sudo apt-get install -y -t "$BACKPORTS_SUITE" neovim && INSTALLED+=("neovim ($BACKPORTS_SUITE)")
fi

record_missing() {
  local key="$1" name="$2" file url
  file="$(pinned_asset_field "$key" file)"
  url="$(pinned_asset_field "$key" url)"
  MISSING_ASSETS+=("$name|$url|$file|$(pinned_asset_field "$key" sha256)")
}

install_from_offline_tarball() {
  local check="$1" key="$2" name="$3" member="$4" dest="$5" file archive tmp found
  if command_exists "$check" && [[ "$PULL_LATEST" != "1" ]]; then
    SKIPPED+=("$check (already installed)")
    return 0
  fi
  file="$(pinned_asset_field "$key" file)"
  archive="$OFFLINE_ASSETS_DIR/$file"
  if [[ ! -f "$archive" ]]; then
    record_missing "$key" "$name"
    warn "$name missing (expected $file)"
    return 0
  fi
  if ! verify_sha256 "$archive" "$(pinned_asset_field "$key" sha256)"; then
    FAILED+=("$name (SHA256 mismatch)")
    error "$name checksum mismatch: $file"
    return 1
  fi
  tmp="$(mktemp -d)"
  tar -xzf "$archive" -C "$tmp" || { rm -rf "$tmp"; FAILED+=("$name (extract failed)"); return 1; }
  found="$(find "$tmp" -type f -name "$member" -perm -111 | head -1)"
  if [[ -z "$found" ]]; then
    rm -rf "$tmp"
    FAILED+=("$name (binary not found)")
    return 1
  fi
  run install -m 755 "$found" "$dest"
  rm -rf "$tmp"
  INSTALLED+=("$name -> $dest")
}

install_from_offline_tarball starship "starship-linux-$ARCH" "starship" starship "$LOCAL_BIN/starship"
install_from_offline_tarball eza "eza-linux-$ARCH" "eza" eza "$LOCAL_BIN/eza"
install_from_offline_tarball uv "uv-linux-$ARCH" "uv" uv "$LOCAL_BIN/uv"
[[ -x "$LOCAL_BIN/uv" && ! -e "$LOCAL_BIN/uvx" ]] && run ln -sf uv "$LOCAL_BIN/uvx"
install_from_offline_tarball delta "delta-linux-$ARCH" "git-delta" delta "$LOCAL_BIN/delta"
install_from_offline_tarball lazygit "lazygit-linux-$ARCH" "lazygit" lazygit "$LOCAL_BIN/lazygit"

if ! command_exists nvim; then
  key="neovim-linux-$ARCH"
  file="$(pinned_asset_field "$key" file)"
  archive="$OFFLINE_ASSETS_DIR/$file"
  if [[ -f "$archive" ]]; then
    if verify_sha256 "$archive" "$(pinned_asset_field "$key" sha256)"; then
      log "Installing offline neovim..."
      run mkdir -p "$HOME/.local/share"
      run tar -xzf "$archive" -C "$HOME/.local/share/"
      run ln -sf "$HOME/.local/share/nvim-linux-x86_64/bin/nvim" "$LOCAL_BIN/nvim"
      INSTALLED+=("neovim (offline)")
    else
      FAILED+=("neovim (SHA256 mismatch)")
    fi
  else
    record_missing "$key" "neovim"
  fi
fi

if [[ "$SKIP_FONTS" != "1" ]]; then
  key="firacode"
  file="$(pinned_asset_field "$key" file)"
  archive="$OFFLINE_ASSETS_DIR/$file"
  if fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
    SKIPPED+=("FiraCode Nerd Font (already installed)")
  elif [[ -f "$archive" ]]; then
    if verify_sha256 "$archive" "$(pinned_asset_field "$key" sha256)"; then
      tmp="$(mktemp -d)"
      run mkdir -p "$HOME/.local/share/fonts"
      if [[ "$DRY_RUN" != "1" ]]; then
        unzip -q "$archive" -d "$tmp"
        find "$tmp" -name '*.ttf' ! -name '*Windows*' -exec cp -n {} "$HOME/.local/share/fonts/" \;
        fc-cache -f "$HOME/.local/share/fonts" >/dev/null
      fi
      rm -rf "$tmp"
      INSTALLED+=("FiraCode Nerd Font")
    else
      FAILED+=("FiraCode Nerd Font (SHA256 mismatch)")
    fi
  else
    record_missing "$key" "FiraCode Nerd Font"
  fi
else
  SKIPPED+=("FiraCode Nerd Font (--skip-fonts)")
fi

log "Installing zsh plugins and tmux TPM via git clone..."
clone_or_skip() {
  local slug="$1" dst="$2"
  if [[ -d "$dst/.git" ]]; then
    SKIPPED+=("$slug (cached)")
    return 0
  fi
  run git clone --quiet --depth=1 "https://github.com/$slug.git" "$dst" && INSTALLED+=("$slug") || FAILED+=("$slug")
}
mkdir -p "$HOME/.local/share/zsh/plugins"
clone_or_skip zsh-users/zsh-autosuggestions "$HOME/.local/share/zsh/plugins/zsh-autosuggestions"
clone_or_skip zsh-users/zsh-syntax-highlighting "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting"
clone_or_skip tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

log "Deploying dotfiles in restricted mode..."
apply_args=(--mode restricted)
[[ "$DRY_RUN" == "1" ]] && apply_args+=(--dry-run)
if "$SCRIPT_DIR/apply-dotfiles.sh" "${apply_args[@]}"; then
  INSTALLED+=("dotfiles (restricted)")
else
  FAILED+=("dotfiles")
fi

if [[ "$DRY_RUN" != "1" && "$SHELL" != *"zsh"* ]]; then
  zsh_path="$(command -v zsh)"
  if [[ -n "$zsh_path" ]]; then
    grep -q "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$zsh_path" 2>/dev/null && INSTALLED+=("default shell -> zsh") || warn "Run manually: chsh -s $zsh_path"
  fi
fi

printf '\n%s%sSummary%s\n' "$CYAN" "$BOLD" "$RESET"
printf '\nInstalled (%d):\n' "${#INSTALLED[@]}"
for x in "${INSTALLED[@]}"; do printf '  + %s\n' "$x"; done
if (( ${#SKIPPED[@]} > 0 )); then
  printf '\nSkipped (%d):\n' "${#SKIPPED[@]}"
  for x in "${SKIPPED[@]}"; do printf '  - %s\n' "$x"; done
fi
if (( ${#FAILED[@]} > 0 )); then
  printf '\nFailed (%d):\n' "${#FAILED[@]}"
  for x in "${FAILED[@]}"; do printf '  x %s\n' "$x"; done
fi
if (( ${#MISSING_ASSETS[@]} > 0 )); then
  printf '\nMissing offline assets for %s:\n' "$OFFLINE_ASSETS_DIR"
  for entry in "${MISSING_ASSETS[@]}"; do
    IFS='|' read -r name url filename sha <<<"$entry"
    printf '  %s\n    url: %s\n    file: %s\n    sha256: %s\n' "$name" "$url" "$filename" "$sha"
  done
  printf '\nSee %s/scripts/offline-manifest.md\n' "$REPO_ROOT"
fi

(( ${#FAILED[@]} > 0 )) && exit 1
success "restricted setup complete"
