#!/usr/bin/env bash
# ============================================================================
# install-debian-restricted.sh
# ----------------------------------------------------------------------------
# Dotfiles installer for a locked-down Debian 12 (bookworm) workstation where
# the only reachable network destinations are:
#
#   • official Debian apt repositories (+ bookworm-backports, opt-in)
#   • github.com (git clone over https or ssh)
#
# Everything else is blocked — no GitHub Release downloads (objects.github
# usercontent.com is firewalled), no third-party apt repos, no cargo/Go
# proxy, no npm, no PyPI.
#
# Strategy:
#   1. apt install everything Debian packages (main + backports).
#   2. For the handful of tools that aren't in apt (starship, eza, fnm, uv,
#      lazygit, FiraCode Nerd Font), look for pre-built release archives in
#      $OFFLINE_ASSETS_DIR that were fetched elsewhere and transferred by SCP.
#      If any are missing, print a manifest at the end listing exactly what
#      to download and where to put it.
#   3. Zsh plugins and tmux TPM still come from git clone (allowed).
#   4. Dotfiles: rendered by scripts/render-dotfiles.py (stdlib Python + a
#      small Go-template-subset evaluator), then symlinked into $HOME.
#   5. LazyVim: Mason is disabled; LSPs come from apt.
#
# Flags:
#   --enable-backports      Add bookworm-backports sources and install nvim
#   --assets-dir PATH       Override $OFFLINE_ASSETS_DIR
#   --skip-docker           Don't install docker.io
#   --skip-fonts            Don't install FiraCode font
#   --pull-latest           Reinstall offline assets even if binaries present
#   --dry-run               Print actions without executing them
#   -h | --help             Show this header
#
# Env var overrides (all optional — keep in sync with offline-manifest.md):
#   STARSHIP_REF EZA_REF FNM_REF UV_REF LAZYGIT_REF FONT_REF NVIM_REF
#   OFFLINE_ASSETS_DIR   (default: $HOME/dotfiles-offline-assets)
#   LOCAL_BIN            (default: $HOME/.local/bin)
#   BUILD_DIR            (default: $HOME/.local/src)
# ============================================================================

set -uo pipefail

# --- Colors -----------------------------------------------------------------
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; PURPLE=$'\033[0;35m'; CYAN=$'\033[0;36m'
  BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; PURPLE=""; CYAN=""; BOLD=""; RESET=""
fi
readonly RED GREEN YELLOW BLUE PURPLE CYAN BOLD RESET

log()     { printf "%s==>%s %s\n" "${BLUE}${BOLD}"  "$RESET" "$*"; }
success() { printf "%s  ✓%s %s\n" "$GREEN"          "$RESET" "$*"; }
info()    { printf "%s  i%s %s\n" "$CYAN"           "$RESET" "$*"; }
warn()    { printf "%s  ⚠%s %s\n" "$YELLOW"         "$RESET" "$*"; }
skip()    { printf "%s  ⊘%s %s\n" "$PURPLE"         "$RESET" "$*"; }
error()   { printf "%s  ✗%s %s\n" "$RED"            "$RESET" "$*" >&2; }
fatal()   { error "$*"; exit 1; }

# ============================================================================
# CONFIG
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_DIR="${BUILD_DIR:-$HOME/.local/src}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
OFFLINE_ASSETS_DIR="${OFFLINE_ASSETS_DIR:-$HOME/dotfiles-offline-assets}"
GITHUB_BASE="${GITHUB_BASE:-https://github.com}"

# Pins — keep in sync with scripts/offline-manifest.md
STARSHIP_REF="${STARSHIP_REF:-v1.23.0}"
EZA_REF="${EZA_REF:-v0.21.5}"
UV_REF="${UV_REF:-0.6.17}"
LAZYGIT_REF="${LAZYGIT_REF:-v0.48.0}"
DELTA_REF="${DELTA_REF:-0.18.2}"
FONT_REF="${FONT_REF:-v3.3.0}"
NVIM_REF="${NVIM_REF:-stable}"

ENABLE_BACKPORTS=0
SKIP_DOCKER=0
SKIP_FONTS=0
PULL_LATEST=0
DRY_RUN=0

declare -a INSTALLED=() FAILED=() SKIPPED=()
declare -a MISSING_ASSETS=()   # entries: "name|url|filename"

bare_version() { printf '%s' "${1#v}"; }

# ============================================================================
# ARGS
# ============================================================================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable-backports)  ENABLE_BACKPORTS=1 ;;
    --assets-dir)        OFFLINE_ASSETS_DIR="$2"; shift ;;
    --skip-docker)       SKIP_DOCKER=1 ;;
    --skip-fonts)        SKIP_FONTS=1 ;;
    --pull-latest)       PULL_LATEST=1 ;;
    --dry-run)           DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,/^# ===/p' "$0" | sed 's/^# \{0,1\}//;s/^===.*$//'
      exit 0
      ;;
    *) fatal "Unknown argument: $1 (see --help)" ;;
  esac
  shift
done

mkdir -p "$BUILD_DIR" "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

# Wrapper that respects --dry-run for commands with side-effects
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    info "dry-run: $*"
  else
    "$@"
  fi
}

command_exists() { command -v "$1" &>/dev/null; }

# ============================================================================
# OS DETECTION
# ============================================================================
[[ -f /etc/os-release ]] || fatal "No /etc/os-release — cannot detect distro."
# shellcheck disable=SC1091
. /etc/os-release
DISTRO_ID="${ID:-unknown}"
CODENAME="${VERSION_CODENAME:-}"
if [[ "$DISTRO_ID" != "debian" || "$CODENAME" != "bookworm" ]]; then
  fatal "This script targets Debian 12 (bookworm). Detected: $DISTRO_ID $CODENAME."
fi
info "Distro: ${PRETTY_NAME:-Debian 12}"
BACKPORTS_SUITE="bookworm-backports"

# ============================================================================
# 1. APT — base packages (Tier 1)
# ============================================================================
log "Installing base packages from apt..."

apt_packages=(
  build-essential pkg-config
  ca-certificates curl wget unzip
  git git-lfs
  zsh tmux
  python3 python3-pip python3-venv python3-dev
  python3-jinja2 python3-yaml
  ripgrep fd-find bat fzf
  zoxide
  jq tree htop
  fontconfig xclip xsel direnv
  rust-analyzer gopls python3-pylsp shellcheck
  libssl-dev libncurses-dev
)
if [[ "$SKIP_DOCKER" != "1" ]]; then
  apt_packages+=(docker.io)
fi

run sudo apt-get update || fatal "apt-get update failed. Fix apt sources."
if ! run sudo apt-get install -y "${apt_packages[@]}"; then
  fatal "Base apt install failed. Fix apt and re-run."
fi
INSTALLED+=("base apt packages (${#apt_packages[@]} pkgs)")

# Debian ships `fd` as `fdfind`, `bat` as `batcat`. Canonicalize in $LOCAL_BIN.
if command_exists fdfind && ! command_exists fd; then
  run ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  info "Linked fdfind → fd"
fi
if command_exists batcat && ! command_exists bat; then
  run ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
  info "Linked batcat → bat"
fi
success "Base apt packages installed."

# ============================================================================
# 2. BACKPORTS — Neovim ≥ 0.9 for LazyVim
# ============================================================================
backports_enabled() { apt-cache policy 2>/dev/null | grep -q " $BACKPORTS_SUITE/"; }

enable_backports() {
  local list="/etc/apt/sources.list.d/${BACKPORTS_SUITE}.list"
  log "Enabling $BACKPORTS_SUITE sources at $list..."
  if [[ "$DRY_RUN" == "1" ]]; then
    info "dry-run: would write $list"
  else
    sudo tee "$list" >/dev/null <<EOF
deb http://deb.debian.org/debian ${BACKPORTS_SUITE} main
deb-src http://deb.debian.org/debian ${BACKPORTS_SUITE} main
EOF
  fi
  run sudo apt-get update
}

install_neovim_from_backports() {
  if command_exists nvim; then
    local v; v=$(nvim --version 2>/dev/null | head -1 | awk '{print $2}' | sed 's/^v//')
    if [[ -n "$v" ]]; then
      info "nvim $v already installed — skipping backports install"
      SKIPPED+=("neovim (already $v)")
      return 0
    fi
  fi
  if apt-cache madison neovim 2>/dev/null | grep -q "$BACKPORTS_SUITE"; then
    log "Installing neovim from $BACKPORTS_SUITE..."
    if run sudo apt-get install -y -t "$BACKPORTS_SUITE" neovim; then
      local v; v=$(nvim --version 2>/dev/null | head -1 | awk '{print $2}' | sed 's/^v//')
      INSTALLED+=("neovim ${v:-unknown} ($BACKPORTS_SUITE)")
      success "Neovim ${v:-installed} from backports."
      return 0
    fi
  fi
  warn "$BACKPORTS_SUITE does not ship neovim, or install failed."
  return 1
}

if [[ "$ENABLE_BACKPORTS" == "1" ]]; then
  if ! backports_enabled; then
    enable_backports
  else
    info "$BACKPORTS_SUITE already enabled."
  fi
  install_neovim_from_backports || warn "Will try offline asset fallback for nvim."
elif backports_enabled; then
  info "$BACKPORTS_SUITE already enabled (use --enable-backports to force refresh)."
  install_neovim_from_backports || warn "Will try offline asset fallback for nvim."
else
  skip "Backports disabled (use --enable-backports to install neovim from backports)."
fi

# ============================================================================
# 3. OFFLINE ASSETS — Tier 3
# ============================================================================
# Each asset is a pre-built release archive the user has SCP'd into
# $OFFLINE_ASSETS_DIR. We extract + install; if the archive is absent, we
# record it in MISSING_ASSETS for the final summary.

log "Scanning offline assets in $OFFLINE_ASSETS_DIR..."
mkdir -p "$OFFLINE_ASSETS_DIR"

# install_from_tarball <display_name> <archive> <url> <member_glob> <dest_bin>
install_from_tarball() {
  local name="$1" archive="$2" url="$3" member_glob="$4" dest_name="$5"
  local src="$OFFLINE_ASSETS_DIR/$archive"
  if [[ ! -f "$src" ]]; then
    MISSING_ASSETS+=("${name}|${url}|${archive}")
    warn "$name missing (expected $archive)"
    return 0
  fi
  local tmp; tmp=$(mktemp -d)
  case "$archive" in
    *.tar.gz|*.tgz) tar -xzf "$src" -C "$tmp" ;;
    *.tar.xz)       tar -xJf "$src" -C "$tmp" ;;
    *.zip)          unzip -q "$src" -d "$tmp" ;;
    *) error "unknown archive type: $archive"; FAILED+=("$name (unknown archive type)"); rm -rf "$tmp"; return 1 ;;
  esac
  local found
  found=$(find "$tmp" -type f -name "$member_glob" -executable 2>/dev/null | head -1)
  if [[ -z "$found" ]]; then
    found=$(find "$tmp" -type f -name "$member_glob" 2>/dev/null | head -1)
  fi
  if [[ -z "$found" ]]; then
    FAILED+=("$name (binary '$member_glob' not found in $archive)")
    error "$name: could not locate '$member_glob' inside $archive"
    rm -rf "$tmp"
    return 1
  fi
  run install -m 755 "$found" "$LOCAL_BIN/$dest_name"
  rm -rf "$tmp"
  INSTALLED+=("$name → $LOCAL_BIN/$dest_name")
  success "$name installed → $LOCAL_BIN/$dest_name"
}

handle_tool() {
  # $1 = PATH check name, $2...$6 = install_from_tarball args
  local check="$1"; shift
  if command_exists "$check" && [[ "$PULL_LATEST" != "1" ]]; then
    SKIPPED+=("$check (already installed)")
    info "$check already installed — skipping offline install"
    return 0
  fi
  install_from_tarball "$@"
}

# --- starship ---------------------------------------------------------------
handle_tool starship \
  "starship ${STARSHIP_REF}" \
  "starship-x86_64-unknown-linux-gnu.tar.gz" \
  "https://github.com/starship/starship/releases/download/${STARSHIP_REF}/starship-x86_64-unknown-linux-gnu.tar.gz" \
  "starship" \
  "starship"

# --- eza --------------------------------------------------------------------
handle_tool eza \
  "eza ${EZA_REF}" \
  "eza_x86_64-unknown-linux-gnu.tar.gz" \
  "https://github.com/eza-community/eza/releases/download/${EZA_REF}/eza_x86_64-unknown-linux-gnu.tar.gz" \
  "eza" \
  "eza"

# --- uv (+ uvx symlink) -----------------------------------------------------
handle_tool uv \
  "uv ${UV_REF}" \
  "uv-x86_64-unknown-linux-gnu.tar.gz" \
  "https://github.com/astral-sh/uv/releases/download/${UV_REF}/uv-x86_64-unknown-linux-gnu.tar.gz" \
  "uv" \
  "uv"
if [[ -x "$LOCAL_BIN/uv" && ! -e "$LOCAL_BIN/uvx" ]]; then
  run ln -sf uv "$LOCAL_BIN/uvx"
  info "Linked uv → uvx"
fi

# --- git-delta --------------------------------------------------------------
delta_archive="delta-${DELTA_REF}-x86_64-unknown-linux-gnu.tar.gz"
handle_tool delta \
  "git-delta ${DELTA_REF}" \
  "$delta_archive" \
  "https://github.com/dandavison/delta/releases/download/${DELTA_REF}/${delta_archive}" \
  "delta" \
  "delta"

# --- lazygit ----------------------------------------------------------------
lazygit_archive="lazygit_$(bare_version "$LAZYGIT_REF")_Linux_x86_64.tar.gz"
handle_tool lazygit \
  "lazygit ${LAZYGIT_REF}" \
  "$lazygit_archive" \
  "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_REF}/${lazygit_archive}" \
  "lazygit" \
  "lazygit"

# --- neovim fallback --------------------------------------------------------
# Only if we still don't have nvim after the backports attempt.
if ! command_exists nvim; then
  nvim_archive="nvim-linux-x86_64.tar.gz"
  nvim_src="$OFFLINE_ASSETS_DIR/$nvim_archive"
  nvim_url="https://github.com/neovim/neovim/releases/download/${NVIM_REF}/${nvim_archive}"
  if [[ -f "$nvim_src" ]]; then
    log "Installing neovim from offline tarball ($nvim_archive)..."
    run mkdir -p "$HOME/.local/share"
    run tar -xzf "$nvim_src" -C "$HOME/.local/share/"
    run ln -sf "$HOME/.local/share/nvim-linux-x86_64/bin/nvim" "$LOCAL_BIN/nvim"
    INSTALLED+=("neovim (offline tarball)")
    success "Neovim installed from tarball → $LOCAL_BIN/nvim"
  else
    MISSING_ASSETS+=("neovim ${NVIM_REF}|${nvim_url}|${nvim_archive}")
    warn "neovim missing (expected $nvim_archive) — and backports unavailable."
  fi
fi

# --- FiraCode Nerd Font -----------------------------------------------------
install_firacode() {
  local font_src="$OFFLINE_ASSETS_DIR/FiraCode.zip"
  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_REF}/FiraCode.zip"
  local font_dst="$HOME/.local/share/fonts"
  if [[ "$SKIP_FONTS" == "1" ]]; then
    skip "FiraCode font (--skip-fonts)"
    return 0
  fi
  if fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
    info "FiraCode Nerd Font already installed"
    SKIPPED+=("FiraCode (already installed)")
    return 0
  fi
  if [[ ! -f "$font_src" ]]; then
    MISSING_ASSETS+=("FiraCode Nerd Font ${FONT_REF}|${font_url}|FiraCode.zip")
    warn "FiraCode.zip missing"
    return 0
  fi
  log "Installing FiraCode Nerd Font..."
  run mkdir -p "$font_dst"
  local tmp; tmp=$(mktemp -d)
  if [[ "$DRY_RUN" != "1" ]]; then
    unzip -q "$font_src" -d "$tmp"
    # Skip *Windows* variants (PowerShell-specific subsets we don't need).
    find "$tmp" -name '*.ttf' ! -name '*Windows*' -exec cp -n {} "$font_dst/" \;
    fc-cache -f "$font_dst" >/dev/null
  fi
  rm -rf "$tmp"
  INSTALLED+=("FiraCode Nerd Font")
  success "FiraCode installed → $font_dst"
}
install_firacode

# ============================================================================
# 4. GIT-CLONE INSTALLS — zsh plugins + tmux TPM
# ============================================================================
log "Installing Zsh plugins and tmux TPM (via git clone)..."
github_url() {
  local slug="$1"
  case "$GITHUB_BASE" in
    git@*) printf '%s%s.git' "$GITHUB_BASE" "$slug" ;;
    *)     printf '%s/%s.git' "$GITHUB_BASE" "$slug" ;;
  esac
}
clone_or_pull() {
  local slug="$1" dst="$2"
  if [[ -d "$dst/.git" ]]; then
    if [[ "$PULL_LATEST" == "1" ]]; then
      run git -C "$dst" pull --ff-only --quiet || warn "pull failed for $slug"
    else
      info "$slug already cloned"
    fi
    SKIPPED+=("$slug (cached)")
    return 0
  fi
  if run git clone --quiet --depth=1 "$(github_url "$slug")" "$dst"; then
    INSTALLED+=("$slug")
    success "Cloned $slug"
  else
    FAILED+=("$slug")
    error "Failed to clone $slug"
  fi
}

ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"
clone_or_pull zsh-users/zsh-autosuggestions "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
clone_or_pull zsh-users/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
clone_or_pull tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# ============================================================================
# 5. DOTFILES — render + symlink via render-dotfiles.py
# ============================================================================
log "Deploying dotfiles..."
if [[ "$DRY_RUN" == "1" ]]; then
  info "dry-run: python3 $SCRIPT_DIR/render-dotfiles.py apply --dry-run"
  python3 "$SCRIPT_DIR/render-dotfiles.py" apply --dry-run || true
else
  if python3 "$SCRIPT_DIR/render-dotfiles.py" apply; then
    INSTALLED+=("dotfiles (rendered + symlinked)")
    success "Dotfiles deployed."
  else
    FAILED+=("dotfiles (render-dotfiles.py failed)")
  fi
fi

# ============================================================================
# 6. LAZYVIM — disable Mason (apt LSPs replace it)
# ============================================================================
log "Disabling Mason in LazyVim (apt LSPs: rust-analyzer, gopls, python3-pylsp, shellcheck)..."
mason_src="$REPO_ROOT/home/dot_config/nvim/lua/plugins/mason-disabled.lua.example"
mason_dst="$HOME/.config/nvim/lua/plugins/mason-disabled.lua"
if [[ -f "$mason_src" ]]; then
  run mkdir -p "$(dirname "$mason_dst")"
  run cp -f "$mason_src" "$mason_dst"
  INSTALLED+=("LazyVim Mason override")
  success "Mason disabled ($mason_dst)"
else
  warn "mason-disabled.lua.example missing at $mason_src"
fi

# ============================================================================
# 7. DEFAULT SHELL
# ============================================================================
if [[ "$DRY_RUN" != "1" && "$SHELL" != *"zsh"* ]]; then
  zsh_path="$(command -v zsh)"
  if [[ -n "$zsh_path" ]]; then
    log "Setting zsh as default shell..."
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    if chsh -s "$zsh_path" 2>/dev/null; then
      INSTALLED+=("default shell → zsh")
      success "Default shell is now zsh."
    else
      warn "Could not change shell. Run manually: chsh -s $zsh_path"
    fi
  fi
fi

# ============================================================================
# 8. SUMMARY
# ============================================================================
printf '\n%s%s──────── Summary ────────%s\n' "$CYAN" "$BOLD" "$RESET"

printf '\n%sInstalled (%d):%s\n' "$BOLD" "${#INSTALLED[@]}" "$RESET"
for x in "${INSTALLED[@]}"; do printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$x"; done

if (( ${#SKIPPED[@]} > 0 )); then
  printf '\n%sSkipped (%d):%s\n' "$BOLD" "${#SKIPPED[@]}" "$RESET"
  for x in "${SKIPPED[@]}"; do printf '  %s⊘%s %s\n' "$PURPLE" "$RESET" "$x"; done
fi

if (( ${#FAILED[@]} > 0 )); then
  printf '\n%sFailed (%d):%s\n' "$BOLD" "${#FAILED[@]}" "$RESET"
  for x in "${FAILED[@]}"; do printf '  %s✗%s %s\n' "$RED" "$RESET" "$x"; done
fi

if (( ${#MISSING_ASSETS[@]} > 0 )); then
  printf '\n%s%s──────── MISSING OFFLINE ASSETS ────────%s\n' "$YELLOW" "$BOLD" "$RESET"
  printf '%sDownload these on an internet-connected machine (e.g. Windows) and%s\n' "$BOLD" "$RESET"
  printf '%splace them in:%s\n' "$BOLD" "$RESET"
  printf '    %s%s%s\n' "$CYAN" "$OFFLINE_ASSETS_DIR" "$RESET"
  printf '%sThen re-run this script.%s\n\n' "$BOLD" "$RESET"
  for entry in "${MISSING_ASSETS[@]}"; do
    IFS='|' read -r name url filename <<<"$entry"
    printf '  %s%s%s\n' "$BOLD" "$name" "$RESET"
    printf '    %surl :%s %s\n' "$CYAN" "$RESET" "$url"
    printf '    %sfile:%s %s\n\n' "$CYAN" "$RESET" "$filename"
  done
  printf '%sFull manifest (incl. PowerShell one-liner):%s\n' "$BOLD" "$RESET"
  printf '    %s%s/scripts/offline-manifest.md%s\n' "$CYAN" "$REPO_ROOT" "$RESET"
fi

printf '\n%sNext:%s\n' "$BOLD" "$RESET"
printf '  1. Run %s./scripts/verify.sh%s to check each tool.\n' "$YELLOW" "$RESET"
printf '  2. Start a fresh zsh session: %sexec zsh%s\n' "$YELLOW" "$RESET"
printf '  3. Open tmux, press %sCtrl-a I%s to install tmux plugins.\n' "$YELLOW" "$RESET"
printf '  4. Open %snvim%s — LazyVim installs plugins on first launch.\n' "$YELLOW" "$RESET"

# Exit 0 unless there were hard failures. Missing assets aren't failures —
# they're pending user actions that unblock on next run.
if (( ${#FAILED[@]} > 0 )); then
  exit 1
fi
if (( ${#MISSING_ASSETS[@]} > 0 )); then
  exit 0
fi
printf '\n%s✓ Restricted-mode installation complete.%s\n' "${GREEN}${BOLD}" "$RESET"
