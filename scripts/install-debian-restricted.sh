#!/usr/bin/env bash
# ============================================================================
# install-debian-restricted.sh
# ----------------------------------------------------------------------------
# Install dotfiles tooling on a LOCKED-DOWN Debian machine where only
# apt (official Debian repos) and github.com are reachable.
#
# Strategy:
#   - Install everything available in Debian repos via apt
#   - For tools too old (or absent) in Debian repos, clone from GitHub and
#     build from source (toolchains come from apt, plus rustup bootstrap
#     when Debian's rustc is too old)
#   - Skip tools that cannot be reasonably obtained
#
# Flags / env vars:
#   --ssh                   Clone GitHub via SSH (git@github.com:) not HTTPS
#   GITHUB_BASE=<url>       Override base URL (default: https://github.com)
#   BUILD_DIR=<path>        Where to clone sources (default: ~/.local/src)
#   SKIP_RUSTUP=1           Skip rustup bootstrap (use system rustc only)
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
export PATH="$LOCAL_BIN:$PATH"

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
# Clones into $BUILD_DIR or updates. Echoes the destination path on stdout.
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
    info "Cloning $slug from $url" >&2
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

sudo apt update
sudo apt install -y \
  build-essential pkg-config \
  libssl-dev libncurses-dev libevent-dev \
  bison autoconf automake cmake ninja-build gettext \
  unzip curl ca-certificates \
  git zsh tmux \
  ripgrep fd-find bat fzf \
  python3 python3-pip python3-venv python3-dev \
  golang-go \
  jq tree htop fontconfig xclip direnv

# Debian names some binaries differently; symlink to canonical names
if command_exists fdfind && ! command_exists fd; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  info "Symlinked fdfind → ~/.local/bin/fd"
fi
if command_exists batcat && ! command_exists bat; then
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
  info "Symlinked batcat → ~/.local/bin/bat"
fi

# --- Docker ---
if ! command_exists docker; then
  log "Installing Docker from Debian repos (docker.io)..."
  sudo apt install -y docker.io
  # Compose plugin: prefer v2 if available (Debian 13+), else fall back to v1
  if apt-cache show docker-compose-v2 &>/dev/null 2>&1; then
    sudo apt install -y docker-compose-v2
    info "Installed docker-compose-v2 (Compose v2)"
  elif apt-cache show docker-compose &>/dev/null 2>&1; then
    sudo apt install -y docker-compose
    warn "Installed docker-compose v1 (Debian 12 default). For Compose v2, build from source."
  else
    warn "No docker-compose package found."
  fi
  sudo usermod -aG docker "$USER"
  info "Added $USER to the 'docker' group — log out/in to take effect."
fi

success "Base apt packages installed."

# ============================================================================
# 2. RUST — apt works on Debian 13; Debian 12 needs a newer toolchain
# ============================================================================
# Many modern Rust tools (starship, eza, uv) now require rustc ≥ 1.74.
# Debian 12 ships 1.63. If we're on that, we bootstrap rustup.

log "Setting up Rust toolchain..."

RUST_MIN="1.74"

# Install apt's rustc/cargo first — it's needed to bootstrap rustup anyway
sudo apt install -y rustc cargo

current_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")
info "System rustc: $current_rustc (minimum required: $RUST_MIN)"

if version_ge "$current_rustc" "$RUST_MIN"; then
  success "System rustc is recent enough."
elif [[ "${SKIP_RUSTUP:-0}" == "1" ]]; then
  warn "SKIP_RUSTUP=1 and system rustc is too old — some builds will fail."
else
  warn "System rustc < $RUST_MIN — bootstrapping rustup from GitHub source..."
  warn "NOTE: rustup itself needs static.rust-lang.org to download toolchains."
  warn "If that host is blocked, ask IT for a mirror and set RUSTUP_DIST_SERVER."

  # Build rustup-init from source using the apt rustc we just installed
  src=$(git_clone_or_update rust-lang/rustup)
  if (cd "$src" && cargo build --release --bin rustup-init); then
    install -m 755 "$src/target/release/rustup-init" "$LOCAL_BIN/rustup-init"
    if "$LOCAL_BIN/rustup-init" -y --no-modify-path --default-toolchain stable; then
      # shellcheck disable=SC1091
      [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
      success "rustup installed; using stable toolchain."
    else
      warn "rustup-init couldn't fetch stable toolchain — staying on system rustc."
    fi
  else
    warn "Failed to build rustup-init — staying on system rustc."
  fi
fi

# Make sure ~/.cargo/bin is on PATH for later builds
export PATH="$HOME/.cargo/bin:$PATH"

# ============================================================================
# 3. GITHUB BUILDS — Tools not in Debian (or too old)
# ============================================================================
# Each tool in its own function, so one failure doesn't abort the script.

build_or_warn() {
  local name="$1" fn="$2"
  if command_exists "$name"; then
    info "$name already present"
    return 0
  fi
  if "$fn"; then
    success "$name installed"
  else
    warn "Failed to build $name — continuing without it."
  fi
}

# ---- Starship prompt ------------------------------------------------------
build_starship() {
  log "Building Starship..."
  local src; src=$(git_clone_or_update starship/starship)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/starship" "$LOCAL_BIN/starship"
}
build_or_warn starship build_starship

# ---- eza ------------------------------------------------------------------
build_eza() {
  log "Building eza..."
  local src; src=$(git_clone_or_update eza-community/eza)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/eza" "$LOCAL_BIN/eza"
}
build_or_warn eza build_eza

# ---- zoxide ---------------------------------------------------------------
build_zoxide() {
  log "Building zoxide..."
  local src; src=$(git_clone_or_update ajeetdsouza/zoxide)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/zoxide" "$LOCAL_BIN/zoxide"
}
build_or_warn zoxide build_zoxide

# ---- git-delta ------------------------------------------------------------
build_delta() {
  log "Building git-delta..."
  local src; src=$(git_clone_or_update dandavison/delta)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/delta" "$LOCAL_BIN/delta"
}
build_or_warn delta build_delta

# ---- lazygit (Go) ---------------------------------------------------------
build_lazygit() {
  log "Building lazygit..."
  local src; src=$(git_clone_or_update jesseduffield/lazygit)
  (cd "$src" && go build -o lazygit .) || return 1
  install -m 755 "$src/lazygit" "$LOCAL_BIN/lazygit"
}
build_or_warn lazygit build_lazygit

# ---- Neovim (LazyVim needs ≥ 0.9) -----------------------------------------
nvim_version() { nvim --version 2>/dev/null | head -1 | awk '{print $2}' | sed 's/^v//'; }

build_nvim() {
  log "Building Neovim stable..."
  local src; src=$(git_clone_or_update neovim/neovim stable)
  (cd "$src" && \
    make -j"$JOBS" CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local" && \
    make install) || return 1
}

if ! command_exists nvim || ! version_ge "$(nvim_version)" "0.9"; then
  build_or_warn nvim build_nvim
else
  info "Neovim $(nvim_version) already present"
fi

# ---- Python uv ------------------------------------------------------------
build_uv() {
  log "Building uv..."
  local src; src=$(git_clone_or_update astral-sh/uv)
  (cd "$src" && cargo build --release --locked --bin uv) || return 1
  install -m 755 "$src/target/release/uv" "$LOCAL_BIN/uv"
}
build_or_warn uv build_uv

# ---- fnm ------------------------------------------------------------------
build_fnm() {
  log "Building fnm..."
  local src; src=$(git_clone_or_update Schniz/fnm)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/fnm" "$LOCAL_BIN/fnm"
}
build_or_warn fnm build_fnm

# ---- chezmoi --------------------------------------------------------------
build_chezmoi() {
  log "Building chezmoi..."
  local src; src=$(git_clone_or_update twpayne/chezmoi)
  (cd "$src" && go build -o chezmoi .) || return 1
  install -m 755 "$src/chezmoi" "$LOCAL_BIN/chezmoi"
}
build_or_warn chezmoi build_chezmoi

# ============================================================================
# 4. ZSH PLUGINS — via git clone (no framework, no registry)
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
# 5. TMUX PLUGIN MANAGER — via git clone
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
# 6. NERD FONT — Sparse git clone (no Releases download needed)
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
# 7. FINAL REPORT
# ============================================================================
cat <<EOF

${YELLOW}${BOLD}Skipped in restricted mode:${RESET}

  ${PURPLE}⊘${RESET} ${BOLD}atuin${RESET}        — needs crates.io + sync server.
                   To build manually:
                     git clone ${GITHUB_BASE}/atuinsh/atuin
                     cd atuin && cargo build --release --locked --bin atuin

  ${PURPLE}⊘${RESET} ${BOLD}Ghostty${RESET}      — needs Zig toolchain; not yet packaged for Debian.
                   Alternative: GNOME Terminal (apt) with FiraCode Nerd Font.

  ${PURPLE}⊘${RESET} ${BOLD}VS Code${RESET}      — Microsoft's apt repo not reachable.
                   Alternative: Neovim + LazyVim (fully configured here).

  ${PURPLE}⊘${RESET} ${BOLD}GitHub CLI${RESET}   — cli.github.com apt repo not reachable.
                   To build: git clone ${GITHUB_BASE}/cli/cli && cd cli && make

  ${PURPLE}⊘${RESET} ${BOLD}Claude Code${RESET}  — npm-based. If npm registry is reachable:
                     npm install -g @anthropic-ai/claude-code

${YELLOW}${BOLD}If any cargo/go build above failed:${RESET}
  It likely couldn't reach ${BOLD}crates.io${RESET} (Rust) or ${BOLD}proxy.golang.org${RESET} (Go).
  Ask your IT for internal mirrors and configure:

    ${CYAN}# ~/.cargo/config.toml${RESET}
    [source.crates-io]
    replace-with = "corporate"
    [source.corporate]
    registry = "sparse+https://your-internal-mirror/cargo/"

    ${CYAN}# In ~/.zshrc.local${RESET}
    export GOPROXY=https://your-internal-mirror/goproxy,direct
    export GOSUMDB=off

${YELLOW}${BOLD}Next:${RESET} run ${CYAN}./scripts/verify.sh${RESET} to check what got installed.

EOF

success "Restricted-mode installation complete."
