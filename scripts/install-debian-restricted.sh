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
# 2. RUST — backports-first strategy
# ============================================================================
# Debian 12 ships rustc 1.63, too old for starship/eza/uv/zoxide/delta.
# Strategy:
#   1. Check if bookworm-backports is enabled & reachable → install Rust 1.78+ from there.
#   2. Else try rustup (only useful if IT gave you a mirror; default rustup
#      uses static.rust-lang.org which is often blocked).
#   3. Else keep the system rustc and let each tool build_or_warn decide
#      whether it can still compile (most modern tools won't).
# ============================================================================
log "Setting up Rust toolchain..."

RUST_MIN="1.74"

# --- Helpers shared by Rust + Go sections ----------------------------------
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
BACKPORTS_SUITE="${CODENAME}-backports"

backports_available() {
  [[ -n "${BACKPORTS_SUITE:-}" ]] || return 1
  apt-cache policy 2>/dev/null | grep -q " ${BACKPORTS_SUITE}/" || return 1
  apt-cache show -t "$BACKPORTS_SUITE" rustc 2>/dev/null | grep -q '^Package:'
}

try_enable_backports() {
  if backports_available; then
    return 0
  fi
  if curl -fsI --max-time 5 "http://deb.debian.org/debian/dists/${BACKPORTS_SUITE}/Release" \
     >/dev/null 2>&1; then
    info "Trying to enable ${BACKPORTS_SUITE}..."
    echo "deb http://deb.debian.org/debian ${BACKPORTS_SUITE} main" | \
      sudo tee "/etc/apt/sources.list.d/${BACKPORTS_SUITE}.list" >/dev/null
    sudo apt update 2>/dev/null || true
    backports_available
  else
    return 1
  fi
}
# ---------------------------------------------------------------------------

# Check what's already available BEFORE touching apt
current_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")
info "Current rustc on PATH: $current_rustc (minimum for modern tools: $RUST_MIN)"

# If user already has a recent Rust (via rustc-web + update-alternatives,
# rustup, or whatever), don't touch anything — installing 'rustc' from
# the main repo would pull libstd-rust-dev, which conflicts with
# libstd-rust-web-dev that rustc-web installs.
if version_ge "$current_rustc" "$RUST_MIN"; then
  success "Rust is already recent enough — leaving toolchain alone."
else
  # Install apt's baseline only if we have nothing usable
  if ! command_exists rustc; then
    info "No rustc found — installing baseline rustc/cargo from main repo."
    sudo apt install -y rustc cargo 2>/dev/null || true
  fi

  # --- Attempt 1: Debian 12's rustc-web (Rust 1.85, in main repo!) ---
  # rustc-web exists for building Debian's web tools (cargo, etc.).
  # It installs as /usr/bin/rustc-1.85 + /usr/bin/cargo-1.85, and we wire
  # them as the default via update-alternatives.
  if apt-cache show rustc-web 2>/dev/null | grep -q '^Package:'; then
    log "Found 'rustc-web' in apt — installing it for a modern Rust toolchain."
    if sudo apt install -y rustc-web cargo-web; then
      # Find the suffixed binary (e.g. rustc-1.85) and wire it up.
      rustc_bin=$(dpkg -L rustc-web | grep -E '^/usr/bin/rustc-[0-9]+\.[0-9]+$' | head -1)
      cargo_bin=$(dpkg -L cargo-web | grep -E '^/usr/bin/cargo-[0-9]+\.[0-9]+$' | head -1)
      if [[ -x "$rustc_bin" && -x "$cargo_bin" ]]; then
        sudo update-alternatives --install /usr/bin/rustc rustc "$rustc_bin" 200
        sudo update-alternatives --install /usr/bin/cargo cargo "$cargo_bin" 200
        hash -r
        success "Wired $rustc_bin and $cargo_bin as default rustc/cargo."
      else
        warn "rustc-web installed but suffixed binaries not found at expected path."
      fi
    fi
  fi

  current_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")

  # --- Attempt 2: backports (only if rustc-web didn't help) ---
  if ! version_ge "$current_rustc" "$RUST_MIN" && try_enable_backports; then
    log "Installing Rust toolchain from ${BACKPORTS_SUITE}..."
    if sudo apt install -y -t "$BACKPORTS_SUITE" rustc cargo; then
      current_rustc=$(rustc --version | awk '{print $2}')
      success "Installed rustc $current_rustc from backports."
    else
      warn "apt install from backports failed."
    fi
  fi

  # --- Attempt 3: rustup (network-dependent; usually blocked in corp) ---
  if ! version_ge "$(rustc --version 2>/dev/null | awk '{print $2}' || echo 0)" "$RUST_MIN" \
      && [[ "${SKIP_RUSTUP:-0}" != "1" ]]; then
    warn "Attempting rustup bootstrap (requires static.rust-lang.org or a mirror)..."
    if [[ -z "${RUSTUP_DIST_SERVER:-}" ]]; then
      warn "RUSTUP_DIST_SERVER not set — default static.rust-lang.org is often blocked in corp."
    fi
    src=$(git_clone_or_update rust-lang/rustup)
    if (cd "$src" && cargo build --release --bin rustup-init 2>/dev/null); then
      install -m 755 "$src/target/release/rustup-init" "$LOCAL_BIN/rustup-init"
      if "$LOCAL_BIN/rustup-init" -y --no-modify-path --default-toolchain stable 2>/dev/null; then
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
        success "rustup succeeded; using stable toolchain."
      else
        warn "rustup couldn't fetch stable toolchain (likely network-blocked)."
      fi
    else
      warn "Failed to build rustup-init."
    fi
  fi

  # --- Final state ---
  final_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")
  if version_ge "$final_rustc" "$RUST_MIN"; then
    success "Rust OK: rustc $final_rustc"
  else
    warn "Staying on rustc $final_rustc. Rust-based tools that need ≥ $RUST_MIN will be skipped."
    warn "Workarounds:"
    warn "  (1) sudo apt install rustc-web cargo-web (Debian 12 — uses /usr/bin/rustc-1.85)"
    warn "  (2) Enable bookworm-backports"
    warn "  (3) Ask IT for RUSTUP_DIST_SERVER mirror"
  fi
fi

export PATH="$HOME/.cargo/bin:$PATH"

# ============================================================================
# 3. GO — also needs a recent version for chezmoi (≥ 1.23) and lazygit
# ============================================================================
# Debian 12's golang-go is 1.19. chezmoi's go.mod requires Go 1.23+, and the
# 'toolchain' directive in modern go.mod files triggers the error:
#   "invalid go version 1.25.7 must match format 1.23"
# on older Go. Same backports-first strategy as Rust.
# ============================================================================
log "Setting up Go toolchain..."

GO_MIN="1.23"
go_version() { go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/^go//'; }

current_go=$(go_version)
current_go="${current_go:-0.0.0}"
info "System Go: $current_go (minimum for modern tools: $GO_MIN)"

if ! version_ge "$current_go" "$GO_MIN"; then
  # Try backports
  if try_enable_backports && apt-cache show -t "$BACKPORTS_SUITE" golang-go &>/dev/null; then
    log "Installing Go from ${BACKPORTS_SUITE}..."
    sudo apt install -y -t "$BACKPORTS_SUITE" golang-go || warn "golang-go from backports failed."
    current_go="$(go_version)"
    current_go="${current_go:-0.0.0}"
  fi

  if version_ge "$current_go" "$GO_MIN"; then
    success "Go OK: $current_go"
  else
    warn "Go $current_go is < $GO_MIN. Go-based tools (chezmoi, lazygit) will be skipped."
    warn "Workaround: enable bookworm-backports, or install Go manually from go.dev/dl."
  fi
fi

# Important for chezmoi: even if Go is recent enough, tell it NOT to try
# downloading a newer toolchain when a go.mod requests it.
export GOTOOLCHAIN=local
export GOFLAGS="${GOFLAGS:-} -mod=mod"

# ============================================================================
# 4. GITHUB BUILDS — Tools not in Debian (or too old)
# ============================================================================
# Each tool in its own function. build_or_warn skips on failure and keeps going.
# A build_rust_if_ok / build_go_if_ok wrapper also checks toolchain version
# BEFORE attempting, so we don't burn 10 min compiling only to fail at link time.

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

# Pre-flight check: skip Rust builds if toolchain is too old
_rust_ok() {
  local min="${1:-$RUST_MIN}"
  local v
  v=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "0.0.0")
  if version_ge "$v" "$min"; then
    return 0
  else
    skip "Skipping Rust build (need rustc ≥ $min, got $v)"
    return 1
  fi
}

# Pre-flight check: skip Go builds if toolchain is too old
_go_ok() {
  local min="${1:-$GO_MIN}"
  local v
  v=$(go_version)
  v="${v:-0.0.0}"
  if version_ge "$v" "$min"; then
    return 0
  else
    skip "Skipping Go build (need go ≥ $min, got $v)"
    return 1
  fi
}

# ---- Starship prompt ------------------------------------------------------
build_starship() {
  _rust_ok || return 1
  log "Building Starship..."
  local src; src=$(git_clone_or_update starship/starship)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/starship" "$LOCAL_BIN/starship"
}
build_or_warn starship build_starship

# ---- eza ------------------------------------------------------------------
build_eza() {
  _rust_ok || return 1
  log "Building eza..."
  local src; src=$(git_clone_or_update eza-community/eza)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/eza" "$LOCAL_BIN/eza"
}
build_or_warn eza build_eza

# ---- zoxide ---------------------------------------------------------------
build_zoxide() {
  _rust_ok || return 1
  log "Building zoxide..."
  local src; src=$(git_clone_or_update ajeetdsouza/zoxide)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/zoxide" "$LOCAL_BIN/zoxide"
}
build_or_warn zoxide build_zoxide

# ---- git-delta ------------------------------------------------------------
build_delta() {
  _rust_ok || return 1
  log "Building git-delta..."
  local src; src=$(git_clone_or_update dandavison/delta)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/delta" "$LOCAL_BIN/delta"
}
build_or_warn delta build_delta

# ---- lazygit (Go) ---------------------------------------------------------
build_lazygit() {
  _go_ok || return 1
  log "Building lazygit..."
  local src; src=$(git_clone_or_update jesseduffield/lazygit)
  (cd "$src" && GOTOOLCHAIN=local go build -o lazygit .) || return 1
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
# uv requires a pretty recent Rust; bump the minimum for just this build.
build_uv() {
  _rust_ok "1.85" || return 1
  log "Building uv..."
  local src; src=$(git_clone_or_update astral-sh/uv)
  (cd "$src" && cargo build --release --locked --bin uv) || return 1
  install -m 755 "$src/target/release/uv" "$LOCAL_BIN/uv"
}
build_or_warn uv build_uv

# ---- fnm ------------------------------------------------------------------
build_fnm() {
  _rust_ok || return 1
  log "Building fnm..."
  local src; src=$(git_clone_or_update Schniz/fnm)
  (cd "$src" && cargo build --release --locked) || return 1
  install -m 755 "$src/target/release/fnm" "$LOCAL_BIN/fnm"
}
build_or_warn fnm build_fnm

# ---- chezmoi --------------------------------------------------------------
build_chezmoi() {
  _go_ok || return 1
  log "Building chezmoi..."
  local src; src=$(git_clone_or_update twpayne/chezmoi)
  # GOTOOLCHAIN=local tells Go: do NOT try to download a newer toolchain
  # just because go.mod has a 'toolchain' directive. Fixes:
  #   "invalid go version 1.25.7 must match format 1.23"
  (cd "$src" && GOTOOLCHAIN=local go build -o chezmoi .) || return 1
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
# ============================================================================
# 7. FINAL REPORT
# ============================================================================
final_rustc=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "unknown")
final_go=$(go_version)
final_go="${final_go:-unknown}"

cat <<EOF

${CYAN}${BOLD}Toolchain summary:${RESET}
  rustc: ${BOLD}${final_rustc}${RESET}   (needed ≥ $RUST_MIN for most Rust tools, ≥ 1.85 for uv)
  go:    ${BOLD}${final_go}${RESET}   (needed ≥ $GO_MIN for chezmoi / lazygit)

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

${YELLOW}${BOLD}If Rust/Go tools were skipped due to old toolchain:${RESET}

  1. ${BOLD}Enable bookworm-backports${RESET} (the easiest fix on Debian 12):
     ${CYAN}echo 'deb http://deb.debian.org/debian bookworm-backports main' | \\
         sudo tee /etc/apt/sources.list.d/bookworm-backports.list${RESET}
     ${CYAN}sudo apt update${RESET}
     ${CYAN}sudo apt install -t bookworm-backports rustc cargo golang-go${RESET}
     Then re-run this installer.

  2. ${BOLD}Ask IT for a Rust mirror${RESET} (bypasses static.rust-lang.org block):
     ${CYAN}export RUSTUP_DIST_SERVER=https://your-internal-rust-mirror${RESET}
     ${CYAN}export RUSTUP_UPDATE_ROOT=\$RUSTUP_DIST_SERVER/rustup${RESET}
     Then re-run this installer.

  3. ${BOLD}Ask IT for cargo/go registry mirrors${RESET} if cargo/go builds themselves
     can't fetch deps (separate from toolchain — these mirrors bypass
     crates.io and proxy.golang.org):
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