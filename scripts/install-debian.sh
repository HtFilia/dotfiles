#!/usr/bin/env bash
# ============================================================================
# install-debian.sh — Install packages on Debian 12/13 (native or WSL)
# ============================================================================
# Usage: install-debian.sh [linux|wsl]

set -euo pipefail

readonly ENV_TYPE="${1:-linux}"  # "linux" or "wsl"

log()     { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  ✓\033[0m %s\n" "$*"; }
info()    { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
warn()    { printf "\033[0;33m  ⚠\033[0m %s\n" "$*"; }

# ---- Detect Debian version ----
if [[ -f /etc/debian_version ]]; then
  DEBIAN_MAJOR="$(cut -d. -f1 /etc/debian_version 2>/dev/null || echo 0)"
  info "Detected Debian version: $(cat /etc/debian_version)"
else
  warn "Not a Debian-based system — proceeding cautiously."
  DEBIAN_MAJOR=0
fi

# ---- apt basics ----
log "Updating apt repositories..."
sudo apt update
sudo apt upgrade -y

log "Installing base packages..."
sudo apt install -y \
  build-essential \
  curl \
  wget \
  git \
  zsh \
  tmux \
  unzip \
  ca-certificates \
  gnupg \
  lsb-release \
  pkg-config \
  libssl-dev \
  python3 \
  python3-pip \
  python3-venv \
  jq \
  tree \
  htop \
  fontconfig \
  xclip
success "Base apt packages installed."

# ---- ripgrep, fd, bat, eza, fzf, zoxide, delta, tmux plugins ----
# Debian 12's repos are older, so for several tools we fetch the latest .deb
# directly from GitHub releases to guarantee up-to-date versions.

ARCH="$(dpkg --print-architecture)"  # amd64 / arm64

install_deb_from_github() {
  local repo="$1" pattern="$2" tmpfile
  tmpfile=$(mktemp --suffix=.deb)
  # Use HTTP redirect to get the latest release tag without hitting API rate limits
  local latest_url
  latest_url=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/$repo/releases/latest")
  local tag="${latest_url##*/}"
  # Replace %20, etc. if needed, but normally tag is just v1.2.3
  
  # For the actual asset, we often need to fetch the release page HTML and extract the asset URL
  url=$(curl -fsSL "https://github.com/$repo/releases/expanded_assets/$tag" | grep -oE "href=\"/[^\"]*${pattern}\"" | head -n1 | sed 's/href=\"//' | sed 's/\"//')
  
  if [[ -n "$url" ]]; then
    url="https://github.com${url}"
  fi
  if [[ -z "$url" ]]; then
    warn "Could not find download URL for $repo (pattern: $pattern)"
    return 1
  fi
  info "Downloading $url"
  curl -fsSL "$url" -o "$tmpfile"
  sudo dpkg -i "$tmpfile" || sudo apt install -f -y
  rm -f "$tmpfile"
}

# ripgrep
if ! command -v rg &>/dev/null; then
  log "Installing ripgrep..."
  sudo apt install -y ripgrep || install_deb_from_github "BurntSushi/ripgrep" "ripgrep_.*_${ARCH}\\.deb"
fi

# fd
if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
  log "Installing fd..."
  sudo apt install -y fd-find || install_deb_from_github "sharkdp/fd" "fd_.*_${ARCH}\\.deb"
fi
# Debian installs as `fdfind` — alias to `fd`
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# bat
if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
  log "Installing bat..."
  sudo apt install -y bat || install_deb_from_github "sharkdp/bat" "bat_.*_${ARCH}\\.deb"
fi
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# eza (modern ls replacement — not in older Debian repos)
if ! command -v eza &>/dev/null; then
  log "Installing eza..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
    sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
    sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
fi

# fzf — clone from source to get latest version & key-bindings
if ! command -v fzf &>/dev/null; then
  log "Installing fzf..."
  if [[ ! -d "$HOME/.fzf" ]]; then
    git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi
  "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# zoxide
if ! command -v zoxide &>/dev/null; then
  log "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# git-delta
if ! command -v delta &>/dev/null; then
  log "Installing git-delta..."
  install_deb_from_github "dandavison/delta" "git-delta_.*_${ARCH}\\.deb"
fi

# lazygit
if ! command -v lazygit &>/dev/null; then
  log "Installing lazygit..."
  local latest_url
  latest_url=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/jesseduffield/lazygit/releases/latest")
  LAZYGIT_VERSION="${latest_url##*/v}"
  case "$ARCH" in
    amd64) LZ_ARCH="x86_64" ;;
    arm64) LZ_ARCH="arm64" ;;
    *)     LZ_ARCH="$ARCH" ;;
  esac
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LZ_ARCH}.tar.gz"
  tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin
  rm /tmp/lazygit /tmp/lazygit.tar.gz
fi

# atuin
if ! command -v atuin &>/dev/null; then
  log "Installing atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# direnv
if ! command -v direnv &>/dev/null; then
  log "Installing direnv..."
  sudo apt install -y direnv
fi

# starship
if ! command -v starship &>/dev/null; then
  log "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# ---- Neovim (need a recent version; Debian's is often too old for LazyVim) ----
if ! command -v nvim &>/dev/null || [[ "$(nvim --version | head -1 | grep -oP '\d+\.\d+' | head -1)" < "0.9" ]]; then
  log "Installing Neovim (latest stable)..."
  curl -fsSL -o /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH/amd64/x86_64}.tar.gz"
  # Older releases used "nvim-linux64.tar.gz"; try fallback if above fails
  if [[ ! -s /tmp/nvim.tar.gz ]] || [[ "$(stat -c%s /tmp/nvim.tar.gz)" -lt 1000 ]]; then
    curl -fsSL -o /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
  fi
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf /tmp/nvim.tar.gz
  sudo mv /opt/nvim-linux* /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm /tmp/nvim.tar.gz
  success "Neovim installed."
fi

# ---- Rust ----
if ! command -v rustup &>/dev/null; then
  log "Installing Rust (rustup)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable
fi

# ---- Go ----
if ! command -v go &>/dev/null; then
  log "Installing Go..."
  GO_VERSION="1.23.4"
  curl -fsSL -o /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm /tmp/go.tar.gz
  # Symlink binaries so they're on PATH
  sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
  sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
fi

# ---- Python uv ----
if ! command -v uv &>/dev/null; then
  log "Installing uv (modern Python package manager)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ---- Node via fnm ----
if ! command -v fnm &>/dev/null; then
  log "Installing fnm (Node version manager)..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

# ---- Docker ----
if ! command -v docker &>/dev/null; then
  log "Installing Docker..."
  if [[ "$ENV_TYPE" == "wsl" ]]; then
    warn "On WSL it is recommended to install Docker Desktop on Windows and enable WSL integration."
    warn "Skipping in-distro Docker install."
  else
    # Official Docker repo (Debian)
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    info "Added $USER to the 'docker' group — log out/in to take effect."
  fi
fi

# ---- VS Code (skip on WSL — install on Windows host instead) ----
if [[ "$ENV_TYPE" != "wsl" ]]; then
  if ! command -v code &>/dev/null; then
    log "Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
      gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
      sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    rm -f /tmp/packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code
  fi
else
  info "WSL detected — install VS Code on Windows and use the Remote-WSL extension."
fi

# ---- GitHub CLI ----
if ! command -v gh &>/dev/null; then
  log "Installing GitHub CLI..."
  (type -p wget >/dev/null || sudo apt install wget -y)
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update
  sudo apt install -y gh
fi

# ---- Ghostty ----
# Ghostty isn't yet in Debian repos — point the user to the build instructions.
if ! command -v ghostty &>/dev/null; then
  warn "Ghostty has no official Debian package yet."
  warn "  Download from: https://ghostty.org/download"
  warn "  Or build from source: https://ghostty.org/docs/install/build"
fi

# ---- Claude Code ----
if ! command -v claude &>/dev/null; then
  log "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash || \
    warn "Claude Code install skipped — install manually from https://claude.com/claude-code"
fi

success "Debian/WSL setup complete."
