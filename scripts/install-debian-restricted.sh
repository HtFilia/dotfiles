#!/usr/bin/env bash
# ============================================================================
# install-debian-restricted.sh
# ----------------------------------------------------------------------------
# Install dotfiles tooling on a LOCKED-DOWN Debian machine where:
#   - apt works (official Debian repos only)
#   - git clone from github.com works
#   - crates.io and Go modules are reachable (via Artifactory)
#   - GitHub Releases / *.githubusercontent.com are BLOCKED
#   - static.rust-lang.org (rustup), npm registry, etc. are BLOCKED
#
# Strategy:
#   1. Install everything available in Debian repos via apt
#   2. Get a recent Rust/Go via backports (Debian 12's defaults are too old)
#   3. Clone tools from GitHub and build from source with cargo / go
#   4. Skip tools that cannot be reasonably obtained
#
# Flags / env vars:
#   --ssh                   Clone GitHub via SSH (git@github.com:) not HTTPS
#   GITHUB_BASE=<url>       Override base URL (default: https://github.com)
#   BUILD_DIR=<path>        Where to clone sources (default: ~/.local/src)
# ============================================================================

set -euo pipefail

# --- Colors ---
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly PURPLE=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

log()     { printf "%s==>%s %s\n"   "${BLUE}${BOLD}"   "${RESET}" "$*"; }
success() { printf "%s  ✓%s %s\n"   "${GREEN}"         "${RESET}" "$*"; }
info()    { printf "%s  i%s %s\n"   "${CYAN}"          "${RESET}" "$*"; }
warn()    { printf "%s  ⚠%s %s\n"   "${YELLOW}"        "${RESET}" "$*"; }
skip()    { printf "%s  ⊘%s %s\n"   "${PURPLE}"        "${RESET}" "$*"; }
fatal()   { printf "%s  ✗%s %s\n"   "${RED}"           "${RESET}" "$*" >&2; exit 1; }

# ============================================================================
# CONFIG
# ============================================================================
BUILD_DIR="${BUILD_DIR:-$HOME/.local/src}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
GITHUB_BASE="${GITHUB_BASE:-https://github.com}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh)   GITHUB_BASE="git@github.com:" ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done

mkdir -p "$BUILD_DIR" "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$PATH"

# ============================================================================
# HELPERS
# ============================================================================
command_exists() { command -v "$1" &>/dev/null; }

github_url() {
  local slug="$1"
  case "$GITHUB_BASE" in
    git@*)  echo "${GITHUB_BASE}${slug}.git" ;;
    *)      echo "${GITHUB_BASE}/${slug}.git" ;;
  esac
}

# git_clone_or_update <owner/repo> [ref]
# Clones into $BUILD_DIR (shallow) or updates. Echoes the destination path.
git_clone_or_update() {
  local slug="$1" ref="${2:-}"
  local repo_name="${slug##*/}"
  local dest="$BUILD_DIR/$repo_name"
  local url
  url=$(github_url "$slug")

  if [[ -d "$dest/.git" ]]; then
    info "Updating $slug" >&2
    git -C "$dest" fetch --tags --quiet >&2 || true
  else
    info "Cloning $slug" >&2
    if [[ -n "$ref" ]]; then
      git clone --depth=1 --branch "$ref" "$url" "$dest" >&2
    else
      git clone --depth=1 "$url" "$dest" >&2
    fi
  fi

  if [[ -n "$ref" ]]; then
    git -C "$dest" checkout --quiet "$ref" >&2 || true
  fi

  echo "$dest"
}

# Version compare: returns 0 if $1 >= $2
version_ge() {
  [[ "$(printf '%s\n%s' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

# ============================================================================
# 0. DETECT DEBIAN VERSION
# ============================================================================
DEBIAN_MAJOR=0
if [[ -f /etc/debian_version ]]; then
  DEBIAN_MAJOR=$(cut -d. -f1 /etc/debian_version | tr -d '[:space:]')
  info "Detected Debian version: $(cat /etc/debian_version)"
fi

# ============================================================================
# 1. APT — Everything available in Debian repos
# ============================================================================
log "Updating apt index and installing base packages..."

sudo apt-get update
sudo apt-get install -y \
  build-essential pkg-config \
  libssl-dev libncurses-dev libevent-dev \
  bison autoconf automake cmake ninja-build gettext \
  unzip curl ca-certificates \
  git zsh tmux \
  ripgrep fd-find bat fzf \
  python3 python3-pip python3-venv python3-dev \
  jq tree htop fontconfig xclip direnv

# Debian names some binaries differently; symlink to canonical names
if command_exists fdfind && ! command_exists fd; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  info "Symlinked fdfind → fd"
fi
if command_exists batcat && ! command_exists bat; then
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
  info "Symlinked batcat → bat"
fi

# --- Docker ---
if ! command_exists docker; then
  log "Installing Docker from Debian repos (docker.io)..."
  sudo apt-get install -y docker.io
  if apt-cache show docker-compose-v2 &>/dev/null 2>&1; then
    sudo apt-get install -y docker-compose-v2
    info "Installed docker-compose-v2"
  elif apt-cache show docker-compose &>/dev/null 2>&1; then
    sudo apt-get install -y docker-compose
    info "Installed docker-compose v1"
  fi
  sudo usermod -aG docker "$USER"
  info "Added $USER to the 'docker' group — log out/in to take effect."
fi

success "Base apt packages installed."

# ============================================================================
# 2. RUST TOOLCHAIN — apt + backports
# ============================================================================
# Debian 12 ships rustc 1.63, too old for starship/eza/zoxide/delta.
# Backports typically has a much more recent version (1.80+).
# We cannot use rustup because static.rust-lang.org is blocked.
# ============================================================================
log "Setting up Rust toolchain..."

RUST_MIN="1.74"

CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
BACKPORTS_SUITE="${CODENAME}-backports"

backports_reachable() {
  apt-cache policy 2>/dev/null | grep -q " ${BACKPORTS_SUITE}/" 2>/dev/null
}

try_enable_backports() {
  if backports_reachable; then
    return 0
  fi
  info "Trying to enable ${BACKPORTS_SUITE}..."
  echo "deb http://deb.debian.org/debian ${BACKPORTS_SUITE} main" | \
    sudo tee "/etc/apt/sources.list.d/${BACKPORTS_SUITE}.list" >/dev/null
  sudo apt-get update 2>/dev/null || true
  backports_reachable
}

# Install baseline Rust from main repo if nothing is present
if ! command_exists rustc; then
  sudo apt-get install -y rustc cargo 2>/dev/null || true
fi

current_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")
info "Current rustc: $current_rustc (minimum for modern tools: $RUST_MIN)"

if ! version_ge "$current_rustc" "$RUST_MIN"; then
  # Try backports for a newer Rust
  if try_enable_backports; then
    if apt-cache show -t "$BACKPORTS_SUITE" rustc &>/dev/null; then
      log "Installing Rust from ${BACKPORTS_SUITE}..."
      sudo apt-get install -y -t "$BACKPORTS_SUITE" rustc cargo && \
        current_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")
    fi
  fi
fi

if version_ge "$current_rustc" "$RUST_MIN"; then
  success "Rust OK: rustc $current_rustc"
else
  warn "Rust $current_rustc is too old (need ≥ $RUST_MIN). Rust-based tools will be skipped."
  warn "Fix: enable ${BACKPORTS_SUITE} with a recent enough rustc, then re-run."
fi

# ============================================================================
# 3. GO TOOLCHAIN — apt + backports
# ============================================================================
# Debian 12 ships Go 1.19. chezmoi needs ≥ 1.23, lazygit needs ≥ 1.22.
# ============================================================================
log "Setting up Go toolchain..."

GO_MIN="1.23"
go_version() { go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/^go//'; }

if ! command_exists go; then
  sudo apt-get install -y golang-go 2>/dev/null || true
fi

current_go=$(go_version)
current_go="${current_go:-0.0.0}"
info "Current Go: $current_go (minimum for modern tools: $GO_MIN)"

if ! version_ge "$current_go" "$GO_MIN"; then
  if try_enable_backports; then
    if apt-cache show -t "$BACKPORTS_SUITE" golang-go &>/dev/null; then
      log "Installing Go from ${BACKPORTS_SUITE}..."
      sudo apt-get install -y -t "$BACKPORTS_SUITE" golang-go && \
        current_go=$(go_version) && current_go="${current_go:-0.0.0}"
    fi
  fi
fi

if version_ge "$current_go" "$GO_MIN"; then
  success "Go OK: $current_go"
else
  warn "Go $current_go is too old (need ≥ $GO_MIN). Go-based tools will be skipped."
  warn "Fix: enable ${BACKPORTS_SUITE} with a recent enough golang-go, then re-run."
fi

# Tell Go NOT to download a newer toolchain when go.mod requests it
export GOTOOLCHAIN=local

# ============================================================================
# 4. BUILD TOOLS FROM SOURCE
# ============================================================================
# Cargo builds work because crates.io is accessible via Artifactory.
# Go builds work because Go modules are accessible via Artifactory.
# Each tool is cloned from GitHub and built locally.

# --- Pre-flight helpers ---
_rust_ok() {
  local min="${1:-$RUST_MIN}"
  local v
  v=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")
  if version_ge "$v" "$min"; then
    return 0
  else
    skip "Skipping (need rustc ≥ $min, have $v)"
    return 1
  fi
}

_go_ok() {
  local min="${1:-$GO_MIN}"
  local v
  v=$(go_version)
  v="${v:-0.0.0}"
  if version_ge "$v" "$min"; then
    return 0
  else
    skip "Skipping (need go ≥ $min, have $v)"
    return 1
  fi
}

build_or_warn() {
  local name="$1" fn="$2"
  if command_exists "$name"; then
    info "$name already present"
    return 0
  fi
  log "Building $name from source..."
  if "$fn"; then
    success "$name installed"
  else
    warn "Failed to build $name — continuing without it."
  fi
}

# ---- Starship prompt ------------------------------------------------------
build_starship() {
  _rust_ok || return 1
  local src; src=$(git_clone_or_update starship/starship)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/starship" "$LOCAL_BIN/starship"
}
build_or_warn starship build_starship

# ---- eza ------------------------------------------------------------------
build_eza() {
  _rust_ok || return 1
  local src; src=$(git_clone_or_update eza-community/eza)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/eza" "$LOCAL_BIN/eza"
}
build_or_warn eza build_eza

# ---- zoxide ---------------------------------------------------------------
build_zoxide() {
  _rust_ok || return 1
  local src; src=$(git_clone_or_update ajeetdsouza/zoxide)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/zoxide" "$LOCAL_BIN/zoxide"
}
build_or_warn zoxide build_zoxide

# ---- git-delta ------------------------------------------------------------
build_delta() {
  _rust_ok || return 1
  local src; src=$(git_clone_or_update dandavison/delta)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/delta" "$LOCAL_BIN/delta"
}
build_or_warn delta build_delta

# ---- fnm ------------------------------------------------------------------
build_fnm() {
  _rust_ok || return 1
  local src; src=$(git_clone_or_update Schniz/fnm)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/fnm" "$LOCAL_BIN/fnm"
}
build_or_warn fnm build_fnm

# ---- uv (needs a very recent Rust — 1.85+) --------------------------------
build_uv() {
  _rust_ok "1.85" || return 1
  local src; src=$(git_clone_or_update astral-sh/uv)
  (cd "$src" && cargo build --release --locked --bin uv) || return 1
  install -m 755 "$src/target/release/uv" "$LOCAL_BIN/uv"
}
build_or_warn uv build_uv

# ---- lazygit (Go) ---------------------------------------------------------
build_lazygit() {
  _go_ok || return 1
  local src; src=$(git_clone_or_update jesseduffield/lazygit)
  (cd "$src" && GOTOOLCHAIN=local go build -o lazygit .) || return 1
  install -m 755 "$src/lazygit" "$LOCAL_BIN/lazygit"
}
build_or_warn lazygit build_lazygit

# ---- chezmoi (Go) ---------------------------------------------------------
build_chezmoi() {
  _go_ok || return 1
  local src; src=$(git_clone_or_update twpayne/chezmoi)
  (cd "$src" && GOTOOLCHAIN=local go build -o chezmoi .) || return 1
  install -m 755 "$src/chezmoi" "$LOCAL_BIN/chezmoi"
}
build_or_warn chezmoi build_chezmoi

# ---- Neovim ---------------------------------------------------------------
# Neovim's cmake build downloads bundled deps from GitHub (archive URLs that
# redirect to codeload.githubusercontent.com). This may fail if that domain
# is blocked. In that case, fall back to apt's version.
nvim_version() { nvim --version 2>/dev/null | head -1 | awk '{print $2}' | sed 's/^v//'; }

build_nvim() {
  local src; src=$(git_clone_or_update neovim/neovim stable)
  (cd "$src" && \
    make -j"$JOBS" CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local" && \
    make install) || return 1
}

if ! command_exists nvim || ! version_ge "$(nvim_version)" "0.9"; then
  log "Building Neovim from source..."
  if build_nvim; then
    success "Neovim installed"
  else
    warn "Neovim build failed (cmake dependency downloads are probably blocked)."
    warn "Falling back to apt's neovim (may be too old for LazyVim)."
    sudo apt-get install -y neovim 2>/dev/null || true
    if command_exists nvim; then
      info "Installed neovim $(nvim_version) from apt"
    fi
  fi
else
  info "Neovim $(nvim_version) already present"
fi

# ============================================================================
# 5. ZSH PLUGINS — via git clone
# ============================================================================
log "Installing Zsh plugins..."
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"
for plugin in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
  name="${plugin##*/}"
  if [[ ! -d "$ZSH_PLUGIN_DIR/$name" ]]; then
    git clone --depth=1 "$(github_url "$plugin")" "$ZSH_PLUGIN_DIR/$name"
    success "Installed $name"
  else
    git -C "$ZSH_PLUGIN_DIR/$name" pull --quiet --ff-only || true
    info "Updated $name"
  fi
done

# ============================================================================
# 6. TMUX PLUGIN MANAGER — via git clone
# ============================================================================
log "Installing tmux plugin manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone --depth=1 "$(github_url tmux-plugins/tpm)" "$TPM_DIR"
  success "TPM installed"
else
  info "TPM already present"
fi

# ============================================================================
# 7. NERD FONT — Sparse git clone
# ============================================================================
log "Installing FiraCode Nerd Font..."
if fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
  info "FiraCode Nerd Font already installed"
else
  FONT_REPO="$BUILD_DIR/nerd-fonts"
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  if [[ ! -d "$FONT_REPO/.git" ]]; then
    git clone --depth=1 --filter=blob:none --sparse \
      "$(github_url ryanoasis/nerd-fonts)" "$FONT_REPO"
    git -C "$FONT_REPO" sparse-checkout set patched-fonts/FiraCode
  else
    git -C "$FONT_REPO" pull --quiet --ff-only || true
  fi

  find "$FONT_REPO/patched-fonts/FiraCode" -name "*.ttf" ! -name "*Windows*" \
    -exec cp {} "$FONT_DIR/" \;
  fc-cache -f "$FONT_DIR"
  success "FiraCode Nerd Font installed"
fi

# ============================================================================
# 8. FINAL REPORT
# ============================================================================
final_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "none")
final_go=$(go_version)
final_go="${final_go:-none}"

cat <<EOF

${CYAN}${BOLD}Toolchain versions:${RESET}
  rustc: ${BOLD}${final_rustc}${RESET}   (needed ≥ $RUST_MIN for most Rust tools, ≥ 1.85 for uv)
  go:    ${BOLD}${final_go}${RESET}   (needed ≥ $GO_MIN for chezmoi / lazygit)

${CYAN}${BOLD}Tool status:${RESET}
EOF

for tool in starship eza zoxide delta lazygit nvim uv fnm chezmoi; do
  if command_exists "$tool"; then
    printf "  ${GREEN}✓${RESET} %s\n" "$tool"
  else
    printf "  ${RED}✗${RESET} %s\n" "$tool"
  fi
done

cat <<EOF

${YELLOW}${BOLD}Skipped in restricted mode:${RESET}

  ${PURPLE}⊘${RESET} ${BOLD}atuin${RESET}        — needs sync server; not usable offline.
  ${PURPLE}⊘${RESET} ${BOLD}Ghostty${RESET}      — needs Zig toolchain; not yet packaged for Debian.
  ${PURPLE}⊘${RESET} ${BOLD}VS Code${RESET}      — Microsoft's apt repo not reachable.
  ${PURPLE}⊘${RESET} ${BOLD}GitHub CLI${RESET}   — cli.github.com apt repo not reachable.
  ${PURPLE}⊘${RESET} ${BOLD}Claude Code${RESET}  — npm-based; needs npm registry.

${YELLOW}${BOLD}If Rust/Go tools were skipped due to old toolchain:${RESET}

  Enable ${BOLD}${BACKPORTS_SUITE}${RESET} (the easiest fix on Debian 12):
    ${CYAN}echo 'deb http://deb.debian.org/debian ${BACKPORTS_SUITE} main' | \\
        sudo tee /etc/apt/sources.list.d/${BACKPORTS_SUITE}.list${RESET}
    ${CYAN}sudo apt-get update${RESET}
    ${CYAN}sudo apt-get install -t ${BACKPORTS_SUITE} rustc cargo golang-go${RESET}
  Then re-run this installer.

${YELLOW}${BOLD}If cargo/go builds fail fetching dependencies:${RESET}

  Ensure Artifactory is configured as the registry proxy:

  ${CYAN}# ~/.cargo/config.toml${RESET}
  [source.crates-io]
  replace-with = "corporate"
  [source.corporate]
  registry = "sparse+https://your-artifactory/cargo/"

  ${CYAN}# Shell environment (e.g. ~/.zshrc.local)${RESET}
  export GOPROXY=https://your-artifactory/goproxy,direct
  export GONOSUMDB='*'

${YELLOW}${BOLD}Next:${RESET} run ${CYAN}./scripts/verify.sh${RESET} to check what got installed.

EOF

success "Restricted-mode installation complete."
