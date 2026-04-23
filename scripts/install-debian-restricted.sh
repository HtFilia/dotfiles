#!/usr/bin/env bash
# ============================================================================
# install-debian-restricted.sh
# ----------------------------------------------------------------------------
# Dotfiles installer for a locked-down Debian 12 (bookworm) workstation where
# the only reachable hosts are:
#
#   • official Debian apt repos (+ bookworm-backports)
#   • github.com (git clone over https/ssh)
#   • corporate Artifactory proxy for crates.io  (via ~/.cargo/config.toml)
#   • corporate Artifactory proxy for Go modules (via GOPROXY)
#
# Everything else is blocked — no GitHub Releases, no codeload.github.com,
# no *.githubusercontent.com, no static.rust-lang.org, no npm registry,
# no third-party apt repos (Microsoft / Docker / GitHub CLI).
#
# Strategy:
#   1. apt-install everything Debian packages already ship.
#   2. Require rustc ≥ 1.85 and go ≥ 1.23 already on PATH. Don't try to
#      bootstrap them — that belongs to a machine-setup step outside this
#      script (e.g. `apt -t bookworm-backports install rustc cargo golang-go`
#      or a corporate-managed deb). If they're missing, bail with guidance.
#   3. For each tool not packaged by Debian (starship, eza, zoxide, delta,
#      fnm, uv, lazygit, chezmoi): git-clone a pinned tag from GitHub and
#      build with cargo / go. Record per-tool failures, never abort.
#   4. Git-clone zsh plugins, tmux TPM, FiraCode Nerd Font (sparse).
#
# Flags:
#   --ssh                 Clone via git@github.com: instead of https.
#   --skip-docker         Don't install docker.io.
#   --skip-fonts          Don't clone the 500 MB nerd-fonts repo.
#   --pull-latest         Re-fetch tags for already-cloned build dirs.
#   -h | --help           Show this header and exit.
#
# Env var overrides (per-tool pins — set to a tag, branch, or commit):
#   STARSHIP_REF EZA_REF ZOXIDE_REF DELTA_REF FNM_REF UV_REF
#   LAZYGIT_REF CHEZMOI_REF
#   BUILD_DIR  (default: ~/.local/src)
#   LOCAL_BIN  (default: ~/.local/bin)
#   RUST_MIN   (default: 1.85)
#   GO_MIN     (default: 1.23)
# ============================================================================

set -uo pipefail

# --- Colors ---
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly PURPLE=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

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
BUILD_DIR="${BUILD_DIR:-$HOME/.local/src}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
GITHUB_BASE="${GITHUB_BASE:-https://github.com}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"

RUST_MIN="${RUST_MIN:-1.85}"
GO_MIN="${GO_MIN:-1.23}"

# Default pins: tags released in the Rust 1.85 / Go 1.23 era. Override any
# of these with e.g. STARSHIP_REF=v1.24.0 to pick a different tag.
STARSHIP_REF="${STARSHIP_REF:-v1.23.0}"
EZA_REF="${EZA_REF:-v0.21.5}"
ZOXIDE_REF="${ZOXIDE_REF:-v0.9.8}"
DELTA_REF="${DELTA_REF:-0.18.2}"
FNM_REF="${FNM_REF:-v1.38.1}"
UV_REF="${UV_REF:-0.6.17}"
LAZYGIT_REF="${LAZYGIT_REF:-v0.48.0}"
CHEZMOI_REF="${CHEZMOI_REF:-v2.58.0}"

SKIP_DOCKER=0
SKIP_FONTS=0
PULL_LATEST=0

# Tallies
declare -a INSTALLED=() FAILED=() SKIPPED=()

# ============================================================================
# ARGS
# ============================================================================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh)          GITHUB_BASE="git@github.com:" ;;
    --skip-docker)  SKIP_DOCKER=1 ;;
    --skip-fonts)   SKIP_FONTS=1 ;;
    --pull-latest)  PULL_LATEST=1 ;;
    -h|--help)
      # Print the top-of-file header, stripping the leading "# "
      sed -n '2,/^# ===/p' "$0" | sed 's/^# \{0,1\}//;s/^===.*$//'
      exit 0
      ;;
    *) fatal "Unknown argument: $1 (see --help)" ;;
  esac
  shift
done

mkdir -p "$BUILD_DIR" "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$PATH"
# Prevent `go` from auto-downloading a newer toolchain when go.mod asks for one.
export GOTOOLCHAIN=local

# ============================================================================
# HELPERS
# ============================================================================
command_exists() { command -v "$1" &>/dev/null; }

github_url() {
  local slug="$1"
  case "$GITHUB_BASE" in
    git@*) printf '%s%s.git\n' "$GITHUB_BASE" "$slug" ;;
    *)     printf '%s/%s.git\n' "$GITHUB_BASE" "$slug" ;;
  esac
}

# version_ge <have> <min> — returns 0 if have >= min (empty = 0.0.0)
version_ge() {
  local have="${1:-0.0.0}" min="${2:?}"
  [[ "$(printf '%s\n%s\n' "$min" "$have" | sort -V | head -n1)" == "$min" ]]
}

rustc_version() { rustc --version 2>/dev/null | awk '{print $2}'; }
go_version()    { go version 2>/dev/null | awk '{print $3}' | sed 's/^go//'; }
nvim_version()  { nvim --version 2>/dev/null | head -1 | awk '{print $2}' | sed 's/^v//'; }

# git_sync <owner/repo> [<ref>] — clone or update into $BUILD_DIR, checkout
# <ref> (tag/branch/sha) if given. Prints the dest path on stdout. All other
# output goes to stderr so callers can safely capture `$(git_sync ...)`.
git_sync() {
  local slug="$1" ref="${2:-}" dest url
  dest="$BUILD_DIR/${slug##*/}"
  url=$(github_url "$slug")

  if [[ -d "$dest/.git" ]]; then
    info "Using cached $slug at $dest" >&2
    if [[ "$PULL_LATEST" == "1" ]]; then
      git -C "$dest" fetch --quiet --tags origin >&2 || true
    fi
  else
    info "Cloning $slug${ref:+ @ $ref}" >&2
    # --branch works for tags too. --depth=1 to avoid pulling full history.
    if [[ -n "$ref" ]]; then
      if ! git clone --quiet --depth=1 --branch "$ref" "$url" "$dest" >&2; then
        # Ref isn't a branch/tag head (e.g. arbitrary sha). Do a full clone.
        rm -rf "$dest"
        git clone --quiet "$url" "$dest" >&2 || return 1
      fi
    else
      git clone --quiet --depth=1 "$url" "$dest" >&2 || return 1
    fi
  fi

  if [[ -n "$ref" ]]; then
    git -C "$dest" checkout --quiet "$ref" >&2 || {
      error "Failed to check out $slug @ $ref" >&2
      return 1
    }
  fi
  printf '%s\n' "$dest"
}

# ============================================================================
# OS DETECTION
# ============================================================================
[[ -f /etc/os-release ]] || fatal "No /etc/os-release — not a Linux distro we support."
# shellcheck disable=SC1091
. /etc/os-release
DISTRO_ID="${ID:-unknown}"
CODENAME="${VERSION_CODENAME:-bookworm}"
if [[ "$DISTRO_ID" != "debian" && "$DISTRO_ID" != "ubuntu" ]]; then
  fatal "This script targets Debian/Ubuntu (got: $DISTRO_ID)."
fi
info "Distro: ${PRETTY_NAME:-$DISTRO_ID $VERSION_ID}"
BACKPORTS_SUITE="${CODENAME}-backports"

# ============================================================================
# 1. APT — base packages from Debian repos
# ============================================================================
log "Installing base packages from apt..."
sudo apt-get update || fatal "apt-get update failed. Check apt sources."

# Note: rustc/cargo/golang-go are intentionally NOT here. We require the user
# to have already installed rust ≥ $RUST_MIN and go ≥ $GO_MIN by their own
# means (typically bookworm-backports, or a corporate-managed .deb).
sudo apt-get install -y \
  build-essential pkg-config \
  ca-certificates curl wget unzip \
  git git-lfs \
  zsh tmux \
  python3 python3-pip python3-venv python3-dev \
  ripgrep fd-find bat fzf \
  jq tree htop \
  fontconfig xclip xsel direnv \
  libssl-dev libncurses-dev \
  || fatal "Base apt install failed. Fix apt before re-running."

# Debian ships `fd` as `fdfind` and `bat` as `batcat`. Canonicalize.
if command_exists fdfind && ! command_exists fd; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  info "Linked fdfind → fd"
fi
if command_exists batcat && ! command_exists bat; then
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
  info "Linked batcat → bat"
fi
success "Base apt packages installed."

# ============================================================================
# 2. TOOLCHAIN PRECHECK — required, not installed by this script
# ============================================================================
log "Verifying toolchains (rustc ≥ $RUST_MIN, go ≥ $GO_MIN)..."

cur_rustc="$(rustc_version || true)"
cur_go="$(go_version || true)"

toolchain_missing=0
if ! command_exists rustc || ! version_ge "${cur_rustc:-0.0.0}" "$RUST_MIN"; then
  error "rustc ${cur_rustc:-<missing>} is below $RUST_MIN."
  toolchain_missing=1
fi
if ! command_exists cargo; then
  error "cargo is missing."
  toolchain_missing=1
fi
if ! command_exists go || ! version_ge "${cur_go:-0.0.0}" "$GO_MIN"; then
  error "go ${cur_go:-<missing>} is below $GO_MIN."
  toolchain_missing=1
fi

if [[ "$toolchain_missing" == "1" ]]; then
  cat >&2 <<EOF

${YELLOW}${BOLD}Install the required toolchains, then re-run this script.${RESET}

Options (any one works):

  ${CYAN}# From Debian backports (requires bookworm-backports to be enabled):${RESET}
  echo 'deb http://deb.debian.org/debian ${BACKPORTS_SUITE} main' | \\
    sudo tee /etc/apt/sources.list.d/${BACKPORTS_SUITE}.list
  sudo apt-get update
  sudo apt-get install -t ${BACKPORTS_SUITE} rustc cargo golang-go

  ${CYAN}# From a corporate-managed deb (if your org publishes one)${RESET}
  ${CYAN}# From trixie (testing) apt pinning${RESET}
  ${CYAN}# From an Artifactory-hosted toolchain bundle${RESET}

Expected on PATH after install:
  rustc  ≥ ${RUST_MIN}   (currently: ${cur_rustc:-<missing>})
  cargo  (currently: $(command -v cargo >/dev/null && echo present || echo missing))
  go     ≥ ${GO_MIN}    (currently: ${cur_go:-<missing>})

EOF
  exit 2
fi

success "rustc $cur_rustc"
success "go $cur_go"

# ============================================================================
# 3. CARGO / GO REGISTRY SANITY CHECK
# ============================================================================
# crates.io and proxy.golang.org are blocked — the user must have an
# Artifactory (or equivalent) mirror configured. We don't edit these
# configs (they're machine-level), but we do warn if they look unset.
log "Checking cargo / go registry configuration..."

cargo_cfg_ok=0
for f in "$HOME/.cargo/config.toml" "$HOME/.cargo/config" /etc/cargo/config.toml; do
  if [[ -f "$f" ]] && grep -q 'replace-with' "$f" 2>/dev/null; then
    cargo_cfg_ok=1
    info "cargo registry mirror configured in $f"
    break
  fi
done
if [[ "$cargo_cfg_ok" != "1" ]]; then
  warn "No cargo registry mirror detected. crates.io may be unreachable."
  warn "  Configure ~/.cargo/config.toml — see the end of this script for a template."
fi

if [[ -n "${GOPROXY:-}" && "$GOPROXY" != "proxy.golang.org,direct" && "$GOPROXY" != "direct" ]]; then
  info "GOPROXY=$GOPROXY"
else
  warn "GOPROXY is unset or points at proxy.golang.org. Go builds may hang."
  warn "  Set: export GOPROXY=https://<artifactory>/goproxy,direct"
fi

# ============================================================================
# 4. BUILD TOOLS FROM SOURCE
# ============================================================================
# cargo_build <src> <bin_name>
#   Try --locked first (maintainer-tested deps), fall back to unlocked.
cargo_build() {
  local src="$1" bin="$2"
  (
    cd "$src"
    if cargo build --release --locked --bin "$bin" 2>&1; then exit 0; fi
    printf '%s  ⚠%s cargo --locked failed; retrying without --locked\n' "$YELLOW" "$RESET"
    cargo build --release --bin "$bin"
  )
}

build_rust_tool() {
  local name="$1" slug="$2" ref="$3" bin="${4:-$1}" src
  if command_exists "$name" && [[ "$PULL_LATEST" != "1" ]]; then
    info "$name already installed — skipping build"
    INSTALLED+=("$name")
    return 0
  fi
  log "Building $name ($slug @ $ref)..."
  if ! src=$(git_sync "$slug" "$ref"); then
    FAILED+=("$name (clone failed)")
    return 1
  fi
  if cargo_build "$src" "$bin"; then
    install -m 755 "$src/target/release/$bin" "$LOCAL_BIN/$bin"
    INSTALLED+=("$name ($ref)")
    success "$name installed → $LOCAL_BIN/$bin"
  else
    FAILED+=("$name (cargo build failed)")
    error "$name: cargo build failed. Is your Artifactory crates mirror reachable?"
  fi
}

build_go_tool() {
  local name="$1" slug="$2" ref="$3" bin="${4:-$1}" src
  if command_exists "$name" && [[ "$PULL_LATEST" != "1" ]]; then
    info "$name already installed — skipping build"
    INSTALLED+=("$name")
    return 0
  fi
  log "Building $name ($slug @ $ref)..."
  if ! src=$(git_sync "$slug" "$ref"); then
    FAILED+=("$name (clone failed)")
    return 1
  fi
  if (cd "$src" && GOTOOLCHAIN=local go build -o "$bin" .); then
    install -m 755 "$src/$bin" "$LOCAL_BIN/$bin"
    INSTALLED+=("$name ($ref)")
    success "$name installed → $LOCAL_BIN/$bin"
  else
    FAILED+=("$name (go build failed)")
    error "$name: go build failed. Is your Artifactory GOPROXY reachable?"
  fi
}

build_rust_tool starship  starship/starship      "$STARSHIP_REF"
build_rust_tool eza       eza-community/eza      "$EZA_REF"
build_rust_tool zoxide    ajeetdsouza/zoxide     "$ZOXIDE_REF"
build_rust_tool delta     dandavison/delta       "$DELTA_REF"
build_rust_tool fnm       Schniz/fnm             "$FNM_REF"
build_rust_tool uv        astral-sh/uv           "$UV_REF"

# uv bundles `uvx` as a symlink to the uv binary (argv[0] dispatch).
if command_exists uv && [[ ! -e "$LOCAL_BIN/uvx" ]]; then
  ln -sf uv "$LOCAL_BIN/uvx"
  info "Linked uv → uvx"
fi

build_go_tool lazygit  jesseduffield/lazygit  "$LAZYGIT_REF"
build_go_tool chezmoi  twpayne/chezmoi        "$CHEZMOI_REF"

# ============================================================================
# 5. NEOVIM — apt-only (backports preferred)
# ============================================================================
# Building Neovim from source would pull its bundled deps (LuaJIT, libvterm,
# msgpack, tree-sitter) from codeload.github.com, which is blocked in this
# environment. Trying and failing wastes time; we rely on apt.
log "Installing Neovim from apt..."

backports_enabled() {
  apt-cache policy 2>/dev/null | grep -q " $BACKPORTS_SUITE/"
}

neovim_install() {
  if command_exists nvim && version_ge "$(nvim_version)" "0.9"; then
    info "nvim $(nvim_version) already installed"
    INSTALLED+=("neovim $(nvim_version)")
    return 0
  fi

  # Prefer backports (typically has a LazyVim-compatible version).
  if backports_enabled && apt-cache madison neovim 2>/dev/null | grep -q "$BACKPORTS_SUITE"; then
    log "Installing neovim from $BACKPORTS_SUITE..."
    if sudo apt-get install -y -t "$BACKPORTS_SUITE" neovim; then
      local v; v=$(nvim_version)
      if version_ge "$v" "0.9"; then
        INSTALLED+=("neovim $v ($BACKPORTS_SUITE)")
        success "Neovim $v installed from backports"
        return 0
      fi
      warn "backports gave neovim $v (< 0.9) — LazyVim needs ≥ 0.9"
    fi
  else
    warn "$BACKPORTS_SUITE not enabled, or it doesn't ship neovim."
    warn "  Enable backports to get a LazyVim-compatible neovim:"
    warn "    echo 'deb http://deb.debian.org/debian $BACKPORTS_SUITE main' | \\"
    warn "      sudo tee /etc/apt/sources.list.d/$BACKPORTS_SUITE.list"
    warn "    sudo apt-get update && sudo apt-get install -t $BACKPORTS_SUITE neovim"
  fi

  # Fallback: apt main (Debian 12 ships 0.7.2 — too old for LazyVim).
  log "Falling back to neovim from Debian main..."
  if sudo apt-get install -y neovim; then
    local v; v=$(nvim_version)
    warn "Installed neovim $v — below 0.9, LazyVim will refuse to load."
    INSTALLED+=("neovim $v (too old for LazyVim)")
  else
    FAILED+=("neovim")
  fi
}
neovim_install

# ============================================================================
# 6. ZSH PLUGINS — via git clone
# ============================================================================
log "Installing Zsh plugins..."
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"
for plugin in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
  name="${plugin##*/}"
  dest="$ZSH_PLUGIN_DIR/$name"
  if [[ -d "$dest/.git" ]]; then
    [[ "$PULL_LATEST" == "1" ]] && git -C "$dest" pull --ff-only --quiet || true
    info "$name already present"
  else
    if git clone --quiet --depth=1 "$(github_url "$plugin")" "$dest"; then
      success "$name installed"
    else
      FAILED+=("$name")
    fi
  fi
done

# ============================================================================
# 7. TMUX PLUGIN MANAGER (TPM)
# ============================================================================
log "Installing tmux plugin manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR/.git" ]]; then
  info "TPM already present"
else
  if git clone --quiet --depth=1 "$(github_url tmux-plugins/tpm)" "$TPM_DIR"; then
    success "TPM installed"
  else
    FAILED+=("tpm")
  fi
fi

# ============================================================================
# 8. NERD FONT (FiraCode) — sparse git clone
# ============================================================================
if [[ "$SKIP_FONTS" == "1" ]]; then
  skip "Font install (--skip-fonts)"
elif fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
  info "FiraCode Nerd Font already installed"
else
  log "Installing FiraCode Nerd Font (sparse clone)..."
  FONT_REPO="$BUILD_DIR/nerd-fonts"
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  if [[ ! -d "$FONT_REPO/.git" ]]; then
    if git clone --depth=1 --filter=blob:none --sparse \
         "$(github_url ryanoasis/nerd-fonts)" "$FONT_REPO" &&
       git -C "$FONT_REPO" sparse-checkout set patched-fonts/FiraCode; then
      :
    else
      FAILED+=("FiraCode Nerd Font")
      warn "Nerd Font clone failed — continuing."
    fi
  fi

  if [[ -d "$FONT_REPO/patched-fonts/FiraCode" ]]; then
    find "$FONT_REPO/patched-fonts/FiraCode" -name '*.ttf' ! -name '*Windows*' \
      -exec cp -n {} "$FONT_DIR/" \;
    fc-cache -f "$FONT_DIR" >/dev/null
    success "FiraCode Nerd Font installed to $FONT_DIR"
  fi
fi

# ============================================================================
# 9. DOCKER (optional)
# ============================================================================
if [[ "$SKIP_DOCKER" == "1" ]]; then
  skip "Docker install (--skip-docker)"
elif command_exists docker; then
  info "docker already installed"
else
  log "Installing docker.io from Debian repos..."
  if sudo apt-get install -y docker.io; then
    sudo usermod -aG docker "$USER"
    info "Added $USER to docker group — log out/in to take effect."
    INSTALLED+=("docker (docker.io)")
  else
    FAILED+=("docker")
  fi
fi

# ============================================================================
# 10. SUMMARY
# ============================================================================
printf '\n%s%s──────── Summary ────────%s\n' "$CYAN" "$BOLD" "$RESET"
printf '  rustc: %s\n' "${cur_rustc:-missing}"
printf '  go:    %s\n' "${cur_go:-missing}"

printf '\n%sTools:%s\n' "$BOLD" "$RESET"
for tool in starship eza zoxide delta fnm uv lazygit chezmoi nvim; do
  if command_exists "$tool"; then
    printf '  %s✓%s %-10s\n' "$GREEN" "$RESET" "$tool"
  else
    printf '  %s✗%s %-10s\n' "$RED" "$RESET" "$tool"
  fi
done

if (( ${#FAILED[@]} > 0 )); then
  printf '\n%sFailures:%s\n' "$RED" "$RESET"
  for f in "${FAILED[@]}"; do printf '  - %s\n' "$f"; done
fi

cat <<EOF

${YELLOW}${BOLD}Always skipped in restricted mode${RESET} (not reachable):
  ${PURPLE}⊘${RESET} VS Code      — Microsoft apt repo blocked
  ${PURPLE}⊘${RESET} GitHub CLI   — cli.github.com apt repo blocked
  ${PURPLE}⊘${RESET} Claude Code  — npm registry blocked
  ${PURPLE}⊘${RESET} Ghostty      — no Debian package, needs Zig
  ${PURPLE}⊘${RESET} atuin        — needs an external sync server

${BOLD}If any cargo build failed${RESET} with registry errors, add this to
${CYAN}~/.cargo/config.toml${RESET} (adjust the URL to your Artifactory):

  [source.crates-io]
  replace-with = "corporate"
  [source.corporate]
  registry = "sparse+https://artifactory.example.com/cargo/"

${BOLD}If any go build failed${RESET} with registry errors, add this to
your shell rc (e.g. ${CYAN}~/.zshrc.local${RESET}):

  export GOPROXY=https://artifactory.example.com/goproxy,direct
  export GONOSUMDB='*'

${BOLD}Next:${RESET} run ${CYAN}scripts/verify.sh${RESET} to double-check what landed.
EOF

if (( ${#FAILED[@]} > 0 )); then
  exit 1
fi
success "Restricted-mode installation complete."
