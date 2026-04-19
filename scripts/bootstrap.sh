#!/usr/bin/env bash
# ============================================================================
# bootstrap.sh — One-command dotfiles installer
# ----------------------------------------------------------------------------
# Detects OS (macOS / Debian / WSL), installs all required tools,
# clones & applies dotfiles via chezmoi.
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

# --- Logging helpers ---
log()     { printf "%s==>%s %s\n"   "${BLUE}${BOLD}"   "${RESET}" "$*"; }
info()    { printf "%s  i%s %s\n"   "${CYAN}"          "${RESET}" "$*"; }
success() { printf "%s  ✓%s %s\n"   "${GREEN}"         "${RESET}" "$*"; }
warn()    { printf "%s  ⚠%s %s\n"   "${YELLOW}"        "${RESET}" "$*"; }
error()   { printf "%s  ✗%s %s\n"   "${RED}"           "${RESET}" "$*" >&2; }
fatal()   { error "$*"; exit 1; }

# --- Paths ---
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/YOUR_USERNAME/dotfiles.git}"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# OS DETECTION
# ============================================================================
detect_os() {
  local os distro
  case "$(uname -s)" in
    Darwin)
      os="macos"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null || \
         grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
        os="wsl"
      else
        os="linux"
      fi
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        distro=$(. /etc/os-release && echo "$ID")
        if [[ "$distro" != "debian" && "$distro" != "ubuntu" ]]; then
          warn "Detected distro: $distro (only Debian/Ubuntu are officially supported)"
        fi
      fi
      ;;
    *)
      fatal "Unsupported OS: $(uname -s)"
      ;;
  esac
  echo "$os"
}

# ============================================================================
# BANNER
# ============================================================================
print_banner() {
  cat <<EOF
${PURPLE}${BOLD}
╭─────────────────────────────────────────────────────────╮
│                                                         │
│   🚀  Dotfiles bootstrap                                │
│                                                         │
│   Shell    :  Zsh + Starship                            │
│   Terminal :  Ghostty                                   │
│   Editors  :  Neovim (LazyVim) + VS Code                │
│   Theme    :  Tokyo Night                               │
│   Font     :  FiraCode Nerd Font                        │
│                                                         │
╰─────────────────────────────────────────────────────────╯
${RESET}
EOF
}

# ============================================================================
# CONFIRMATION
# ============================================================================
confirm() {
  local msg="$1"
  if [[ "${DOTFILES_ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi
  printf "%s %s[y/N]%s " "$msg" "${YELLOW}" "${RESET}"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

# ============================================================================
# COMMON HELPERS
# ============================================================================
command_exists() { command -v "$1" &>/dev/null; }

ensure_dir() { [[ -d "$1" ]] || mkdir -p "$1"; }

# ============================================================================
# MAIN
# ============================================================================
# ============================================================================
# USAGE
# ============================================================================
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --restricted       Use GitHub-only build-from-source mode (for locked-down
                     corporate machines where only apt + github.com are
                     reachable). Linux only.
  -y, --yes          Assume 'yes' to all prompts.
  -h, --help         Show this help.

Environment variables:
  DOTFILES_MODE         'full' (default) or 'restricted'
  DOTFILES_ASSUME_YES   set to 1 to skip confirmations
  DOTFILES_REPO         git URL to clone (default: see top of script)

Examples:
  $0                        # Normal install
  $0 --restricted           # For corporate/locked-down machines
  DOTFILES_MODE=restricted $0 --yes
EOF
}

main() {
  # ---- Parse flags ----
  local mode="${DOTFILES_MODE:-full}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --restricted)  mode="restricted" ;;
      -y|--yes)      export DOTFILES_ASSUME_YES=1 ;;
      -h|--help)     usage; exit 0 ;;
      *)             error "Unknown flag: $1"; usage; exit 1 ;;
    esac
    shift
  done

  print_banner

  local os
  os=$(detect_os)
  success "Detected OS: ${BOLD}${os}${RESET}"
  success "Install mode: ${BOLD}${mode}${RESET}"
  if [[ "$mode" == "restricted" && "$os" == "macos" ]]; then
    fatal "Restricted mode is Linux-only. Use the default mode on macOS."
  fi
  echo

  if ! confirm "Continue with installation?"; then
    warn "Aborted by user."
    exit 0
  fi

  # ---- Run the OS-specific installer ----
  log "Running system-level installer for ${os} (mode: ${mode})..."
  case "$os" in
    macos)
      bash "${SCRIPT_DIR}/install-macos.sh"
      ;;
    linux|wsl)
      if [[ "$mode" == "restricted" ]]; then
        bash "${SCRIPT_DIR}/install-debian-restricted.sh"
      else
        bash "${SCRIPT_DIR}/install-debian.sh" "$os"
      fi
      ;;
  esac
  success "System packages installed."
  echo

  # ---- Install Nerd Font (skip on WSL — handled by Windows host) ----
  # In restricted mode, the font is installed by install-debian-restricted.sh itself.
  if [[ "$mode" != "restricted" ]]; then
    if [[ "$os" != "wsl" ]]; then
      log "Installing FiraCode Nerd Font..."
      bash "${SCRIPT_DIR}/install-fonts.sh"
      success "Font installed."
    else
      warn "On WSL, install FiraCode Nerd Font on the Windows host instead."
      warn "  → https://github.com/ryanoasis/nerd-fonts/releases"
    fi
    echo
  fi

  # ---- Install Zsh plugins manually (no framework) ----
  log "Installing Zsh plugins..."
  local plugin_dir="$HOME/.local/share/zsh/plugins"
  ensure_dir "$plugin_dir"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$plugin_dir/$plugin" ]]; then
      git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$plugin_dir/$plugin"
      success "Installed $plugin"
    else
      info "$plugin already present, pulling updates..."
      git -C "$plugin_dir/$plugin" pull --quiet
    fi
  done
  echo

  # ---- Install tmux plugin manager (TPM) ----
  log "Installing tmux plugin manager..."
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    success "TPM installed."
  else
    info "TPM already installed."
  fi
  echo

  # ---- Install chezmoi & apply dotfiles ----
  log "Installing chezmoi..."
  if ! command_exists chezmoi; then
    export PATH="$HOME/.local/bin:$PATH"
    if [[ "$mode" == "restricted" ]]; then
      # Build from source (requires `go` from apt)
      log "Building chezmoi from source (restricted mode)..."
      local build_dir="$HOME/.local/src/chezmoi"
      if [[ ! -d "$build_dir/.git" ]]; then
        git clone --depth=1 https://github.com/twpayne/chezmoi.git "$build_dir"
      fi
      (cd "$build_dir" && go build -o chezmoi .)
      install -m 755 "$build_dir/chezmoi" "$HOME/.local/bin/chezmoi"
    else
      # Use the official installer
      sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    fi
    success "chezmoi installed."
  else
    info "chezmoi already present."
  fi
  echo

  log "Applying dotfiles via chezmoi..."
  # If script is run from inside the repo, use local source; else use remote
  local source_arg
  if [[ -f "${SCRIPT_DIR}/../.chezmoi.toml.tmpl" ]]; then
    source_arg="${SCRIPT_DIR}/.."
    info "Using local source: $source_arg"
  else
    source_arg="$DOTFILES_REPO"
    info "Using remote source: $source_arg"
  fi

  if [[ ! -d "$HOME/.local/share/chezmoi" ]]; then
    chezmoi init --apply "$source_arg"
  else
    info "chezmoi source already initialized — running 'chezmoi apply'"
    chezmoi apply
  fi
  success "Dotfiles applied."
  echo

  # ---- Set Zsh as default shell ----
  if [[ "$SHELL" != *"zsh"* ]]; then
    log "Setting Zsh as default shell..."
    local zsh_path
    zsh_path=$(command -v zsh)
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    if confirm "Change default shell to Zsh?"; then
      chsh -s "$zsh_path" || warn "Could not change shell automatically. Run: chsh -s $zsh_path"
    fi
  fi
  echo

  # ---- Final summary ----
  cat <<EOF

${GREEN}${BOLD}╭─────────────────────────────────────────────────────────╮
│  ✅  All done!                                          │
╰─────────────────────────────────────────────────────────╯${RESET}

${BOLD}Next steps:${RESET}

  1. ${CYAN}Restart your terminal${RESET} (or run ${YELLOW}exec zsh${RESET})
  2. Open tmux and press ${YELLOW}prefix + I${RESET} (Ctrl-a then I) to install tmux plugins
  3. Open Neovim — LazyVim will install plugins on first launch: ${YELLOW}nvim${RESET}
  4. Configure Ghostty to use "${YELLOW}FiraCode Nerd Font${RESET}" if not auto-applied
  5. In VS Code, install the ${YELLOW}Tokyo Night${RESET} theme + recommended extensions:
     ${CYAN}code --install-extension $(cat "${SCRIPT_DIR}/../extensions.txt" 2>/dev/null | head -1 || echo enkia.tokyo-night)${RESET}

${BOLD}Daily workflow:${RESET}

  • Edit a config:      ${YELLOW}chezmoi edit ~/.zshrc${RESET}
  • Preview changes:    ${YELLOW}chezmoi diff${RESET}
  • Apply changes:      ${YELLOW}chezmoi apply${RESET}
  • Push changes:       ${YELLOW}chezmoi cd${RESET} then git commit/push

EOF
}

main "$@"
