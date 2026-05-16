#!/usr/bin/env bash
# Install packages on Debian/Ubuntu or WSL with pinned direct downloads.

set -euo pipefail

ENV_TYPE="linux"
if [[ $# -gt 0 && "$1" != --* ]]; then
  ENV_TYPE="$1"
  shift
fi
ENABLE_DOCKER_GROUP=0
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
Usage: $0 [linux|wsl] [--enable-docker-group]

Options:
  --enable-docker-group   add the current user to the root-equivalent docker group
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable-docker-group) ENABLE_DOCKER_GROUP=1 ;;
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

install_from_tarball() {
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
  tar -xzf "$archive" -C "$tmp"
  local found
  found="$(find "$tmp" -type f -name "$member" -perm -111 | head -1)"
  [[ -n "$found" ]] || { rm -rf "$tmp"; fatal "Could not find $member in $file"; }
  install -m 755 "$found" "$dest"
  rm -rf "$tmp"
  success "installed $(basename "$dest")"
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
  build-essential curl wget git zsh tmux unzip ca-certificates gnupg lsb-release \
  pkg-config libssl-dev python3 python3-pip python3-venv jq tree htop fontconfig \
  xclip ripgrep fd-find bat fzf zoxide direnv rustc cargo
success "apt packages installed"

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
fi
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
fi

command -v starship >/dev/null 2>&1 || install_from_tarball "starship-linux-$ARCH" starship "$LOCAL_BIN/starship"
command -v eza >/dev/null 2>&1 || install_from_tarball "eza-linux-$ARCH" eza "$LOCAL_BIN/eza"
command -v uv >/dev/null 2>&1 || install_from_tarball "uv-linux-$ARCH" uv "$LOCAL_BIN/uv"
[[ -x "$LOCAL_BIN/uv" && ! -e "$LOCAL_BIN/uvx" ]] && ln -sf uv "$LOCAL_BIN/uvx"
command -v delta >/dev/null 2>&1 || install_from_tarball "delta-linux-$ARCH" delta "$LOCAL_BIN/delta"
command -v lazygit >/dev/null 2>&1 || install_from_tarball "lazygit-linux-$ARCH" lazygit "$LOCAL_BIN/lazygit"

if ! command -v nvim >/dev/null 2>&1; then
  install_neovim
fi
if ! command -v go >/dev/null 2>&1; then
  install_go
fi

if [[ "$ENV_TYPE" == "wsl" ]]; then
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
