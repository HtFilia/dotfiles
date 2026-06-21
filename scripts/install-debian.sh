#!/usr/bin/env bash
# Install packages on Debian/Ubuntu or WSL with pinned direct downloads.

set -euo pipefail

ENV_TYPE="linux"
if [[ $# -gt 0 && "$1" != --* ]]; then
  ENV_TYPE="$1"
  shift
fi
ENABLE_DOCKER_GROUP=0
SKIP_DOCKER=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  +\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
warn() { printf "\033[0;33m  !\033[0m %s\n" "$*" >&2; }
fatal() { printf "\033[0;31m  x\033[0m %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [linux|wsl] [--enable-docker-group] [--skip-docker]

Options:
  --enable-docker-group   add the current user to the root-equivalent docker group
  --skip-docker           do not install Docker
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable-docker-group) ENABLE_DOCKER_GROUP=1 ;;
    --skip-docker) SKIP_DOCKER=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done

LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
DOWNLOAD_DIR="${DOTFILES_DOWNLOAD_DIR:-$HOME/.cache/dotfiles/downloads}"
mkdir -p "$LOCAL_BIN" "$DOWNLOAD_DIR"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

ARCH="$(pinned_asset_arch)" || fatal "Unsupported architecture: $(uname -m)"
GO_ARCH="$(pinned_asset_go_arch)" || fatal "Unsupported Go architecture: $(uname -m)"
[[ "$ARCH" == "x86_64" ]] || fatal "Pinned Linux assets currently support x86_64 only."

extract_archive() {
  local archive="$1" dest="$2"
  case "$archive" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$dest" ;;
    *.tar.xz) tar -xJf "$archive" -C "$dest" ;;
    *.zip) unzip -oq "$archive" -d "$dest" ;;
    *) return 1 ;;
  esac
}

install_from_archive() {
  local key="$1" member="$2" dest="$3" archive tmp file
  file="$(pinned_asset_field "$key" file)"
  archive="$DOWNLOAD_DIR/$file"
  if [[ ! -f "$archive" ]]; then
    log "Downloading pinned asset: $key"
    download_pinned_asset "$key" "$DOWNLOAD_DIR" || fatal "Checksum failed for $file"
  elif ! require_pinned_file "$key" "$DOWNLOAD_DIR"; then
    fatal "Checksum failed for cached file: $archive"
  fi
  tmp="$(mktemp -d)"
  extract_archive "$archive" "$tmp" || { rm -rf "$tmp"; fatal "Unsupported archive type: $file"; }
  local found
  found="$(find "$tmp" -type f -name "$member" | head -1)"
  [[ -n "$found" ]] || { rm -rf "$tmp"; fatal "Could not find $member in $file"; }
  install -m 755 "$found" "$dest"
  rm -rf "$tmp"
  success "installed $(basename "$dest")"
}

install_binary_asset() {
  local key="$1" dest="$2" archive file
  file="$(pinned_asset_field "$key" file)"
  archive="$DOWNLOAD_DIR/$file"
  if [[ ! -f "$archive" ]]; then
    log "Downloading pinned asset: $key"
    download_pinned_asset "$key" "$DOWNLOAD_DIR" || fatal "Checksum failed for $file"
  elif ! require_pinned_file "$key" "$DOWNLOAD_DIR"; then
    fatal "Checksum failed for cached file: $archive"
  fi
  install -m 755 "$archive" "$dest"
  success "installed $(basename "$dest")"
}

pinned_version_matches() {
  local tool="$1" key="$2" version_cmd="${3:---version}" expected out
  command -v "$tool" >/dev/null 2>&1 || return 1
  expected="$(pinned_asset_field "$key" version 2>/dev/null || true)"
  [[ -n "$expected" ]] || return 1
  out="$("$tool" "$version_cmd" 2>&1 | head -1 || true)"
  [[ "$out" == *"${expected#v}"* ]]
}

install_archive_if_needed() {
  local tool="$1" key="$2" member="$3" dest="$4" version_cmd="${5:---version}"
  pinned_version_matches "$tool" "$key" "$version_cmd" || install_from_archive "$key" "$member" "$dest"
}

install_binary_if_needed() {
  local tool="$1" key="$2" dest="$3" version_cmd="${4:---version}"
  pinned_version_matches "$tool" "$key" "$version_cmd" || install_binary_asset "$key" "$dest"
}

install_yazi() {
  install_from_archive "yazi-linux-$ARCH" yazi "$LOCAL_BIN/yazi"
  install_from_archive "yazi-linux-$ARCH" ya "$LOCAL_BIN/ya"
}

install_tokei() {
  command -v cargo >/dev/null 2>&1 || fatal "cargo is required to install tokei"
  cargo install --locked --version 14.0.0 tokei
}

tokei_version_matches() {
  command -v tokei >/dev/null 2>&1 || return 1
  tokei --version 2>&1 | head -1 | grep -q '14\.0\.0'
}

install_neovim() {
  local key="neovim-linux-$ARCH" file archive
  file="$(pinned_asset_field "$key" file)"
  archive="$DOWNLOAD_DIR/$file"
  if [[ ! -f "$archive" ]]; then
    log "Downloading pinned Neovim"
    download_pinned_asset "$key" "$DOWNLOAD_DIR" || fatal "Checksum failed for $file"
  elif ! require_pinned_file "$key" "$DOWNLOAD_DIR"; then
    fatal "Checksum failed for cached file: $archive"
  fi
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf "$archive"
  sudo mv /opt/nvim-linux-* /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  success "installed nvim $(pinned_asset_field "$key" version)"
}

install_go() {
  local key="go-linux-$GO_ARCH" file archive
  file="$(pinned_asset_field "$key" file)"
  archive="$DOWNLOAD_DIR/$file"
  if [[ ! -f "$archive" ]]; then
    log "Downloading pinned Go"
    download_pinned_asset "$key" "$DOWNLOAD_DIR" || fatal "Checksum failed for $file"
  elif ! require_pinned_file "$key" "$DOWNLOAD_DIR"; then
    fatal "Checksum failed for cached file: $archive"
  fi
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$archive"
  sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
  sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
  success "installed go $(pinned_asset_field "$key" version)"
}

install_node() {
  local key="node-linux-$ARCH" file archive version tmp found
  file="$(pinned_asset_field "$key" file)"
  version="$(pinned_asset_field "$key" version)"
  archive="$DOWNLOAD_DIR/$file"
  if [[ ! -f "$archive" ]]; then
    log "Downloading pinned Node.js LTS"
    download_pinned_asset "$key" "$DOWNLOAD_DIR" || fatal "Checksum failed for $file"
  elif ! require_pinned_file "$key" "$DOWNLOAD_DIR"; then
    fatal "Checksum failed for cached file: $archive"
  fi
  tmp="$(mktemp -d)"
  tar -xJf "$archive" -C "$tmp"
  found="$(find "$tmp" -type f -path '*/bin/node' -perm -111 | head -1)"
  [[ -n "$found" ]] || { rm -rf "$tmp"; fatal "Could not find node in $file"; }
  sudo rm -rf /usr/local/node
  sudo mkdir -p /usr/local/node
  sudo cp -R "$(dirname "$(dirname "$found")")/." /usr/local/node/
  sudo ln -sf /usr/local/node/bin/node /usr/local/bin/node
  sudo ln -sf /usr/local/node/bin/npm /usr/local/bin/npm
  sudo ln -sf /usr/local/node/bin/npx /usr/local/bin/npx
  [[ -x /usr/local/node/bin/corepack ]] && sudo ln -sf /usr/local/node/bin/corepack /usr/local/bin/corepack
  rm -rf "$tmp"
  success "installed node $version"
}

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  info "Detected: ${PRETTY_NAME:-$ID}"
fi
OS_ID="${ID:-debian}"
OS_CODENAME="${VERSION_CODENAME:-}"

log "Updating apt repositories..."
sudo apt update
sudo apt upgrade -y

log "Installing packages from apt..."
sudo apt install -y \
  build-essential curl wget git zsh tmux unzip xz-utils ca-certificates gnupg lsb-release \
  pkg-config libssl-dev python3 python3-pip python3-venv jq tree htop fontconfig \
  xclip ripgrep fd-find bat fzf zoxide direnv rustc cargo shellcheck
success "apt packages installed"

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
fi
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
fi

install_archive_if_needed starship "starship-linux-$ARCH" starship "$LOCAL_BIN/starship"
install_archive_if_needed eza "eza-linux-$ARCH" eza "$LOCAL_BIN/eza"
install_archive_if_needed uv "uv-linux-$ARCH" uv "$LOCAL_BIN/uv"
[[ -x "$LOCAL_BIN/uv" && ! -e "$LOCAL_BIN/uvx" ]] && ln -sf uv "$LOCAL_BIN/uvx"
install_archive_if_needed delta "delta-linux-$ARCH" delta "$LOCAL_BIN/delta"
install_archive_if_needed lazygit "lazygit-linux-$ARCH" lazygit "$LOCAL_BIN/lazygit"
install_archive_if_needed chezmoi "chezmoi-linux-$GO_ARCH" chezmoi "$LOCAL_BIN/chezmoi"
install_archive_if_needed just "just-linux-$ARCH" just "$LOCAL_BIN/just"
install_binary_if_needed mise "mise-linux-$ARCH" "$LOCAL_BIN/mise"
if ! pinned_version_matches yazi "yazi-linux-$ARCH" --version || ! command -v ya >/dev/null 2>&1; then
  install_yazi
fi
install_binary_if_needed yq "yq-linux-$GO_ARCH" "$LOCAL_BIN/yq"
install_archive_if_needed sd "sd-linux-$ARCH" sd "$LOCAL_BIN/sd"
install_archive_if_needed dust "dust-linux-$ARCH" dust "$LOCAL_BIN/dust"
install_archive_if_needed duf "duf-linux-$ARCH" duf "$LOCAL_BIN/duf"
install_archive_if_needed hyperfine "hyperfine-linux-$ARCH" hyperfine "$LOCAL_BIN/hyperfine"
tokei_version_matches || install_tokei
install_archive_if_needed watchexec "watchexec-linux-$ARCH" watchexec "$LOCAL_BIN/watchexec"
install_archive_if_needed xh "xh-linux-$ARCH" xh "$LOCAL_BIN/xh"
install_archive_if_needed lazydocker "lazydocker-linux-$ARCH" lazydocker "$LOCAL_BIN/lazydocker"
install_archive_if_needed gitleaks "gitleaks-linux-x64" gitleaks "$LOCAL_BIN/gitleaks" version
install_archive_if_needed actionlint "actionlint-linux-$GO_ARCH" actionlint "$LOCAL_BIN/actionlint"

if ! pinned_version_matches nvim "neovim-linux-$ARCH" --version; then
  install_neovim
fi
if ! pinned_version_matches go "go-linux-$GO_ARCH" version; then
  install_go
fi
if ! pinned_version_matches node "node-linux-$ARCH" --version; then
  install_node
fi
if command -v corepack >/dev/null 2>&1; then
  sudo corepack enable pnpm --install-directory /usr/local/bin >/dev/null 2>&1 || corepack enable pnpm >/dev/null 2>&1 || warn "Could not enable pnpm with Corepack."
fi

if [[ "$SKIP_DOCKER" == "1" ]]; then
  warn "Skipped Docker installation."
elif [[ "$ENV_TYPE" == "wsl" ]]; then
  warn "WSL detected: install Docker Desktop and VS Code on Windows with WSL integration."
else
  if ! command -v docker >/dev/null 2>&1; then
    case "$OS_ID" in
      debian|ubuntu) ;;
      *) fatal "Docker apt repository is configured only for Debian/Ubuntu, detected $OS_ID" ;;
    esac
    log "Installing Docker from official apt repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$OS_ID/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS_ID $OS_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    if [[ "$ENABLE_DOCKER_GROUP" == "1" ]]; then
      warn "Adding $USER to the docker group grants root-equivalent access."
      sudo usermod -aG docker "$USER"
      info "Added $USER to docker group; log out/in to take effect."
    else
      warn "Did not add $USER to docker group. Re-run with --enable-docker-group if you accept root-equivalent access."
    fi
  fi
fi

if ! command -v gh >/dev/null 2>&1; then
  log "Installing GitHub CLI from official apt repository..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update
  sudo apt install -y gh
fi

warn "Claude Code and atuin are not installed automatically; install them manually if you accept their upstream installer."
warn "Ghostty has no official Debian package; install it manually from your trusted channel."
success "Debian/WSL setup complete."
