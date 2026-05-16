#!/usr/bin/env bash
# One-command dotfiles installer.

set -euo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

log() { printf "%s==>%s %s\n" "${BLUE}${BOLD}" "$RESET" "$*"; }
info() { printf "%s  i%s %s\n" "$CYAN" "$RESET" "$*"; }
success() { printf "%s  +%s %s\n" "$GREEN" "$RESET" "$*"; }
warn() { printf "%s  !%s %s\n" "$YELLOW" "$RESET" "$*" >&2; }
fatal() { printf "%s  x%s %s\n" "$RED" "$RESET" "$*" >&2; exit 1; }

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/HtFilia/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_os() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' macos ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
        printf '%s\n' wsl
      else
        printf '%s\n' linux
      fi
      ;;
    *) fatal "Unsupported OS: $(uname -s)" ;;
  esac
}

confirm() {
  local msg="$1"
  [[ "${DOTFILES_ASSUME_YES:-0}" == "1" ]] && return 0
  printf "%s %s[y/N]%s " "$msg" "$YELLOW" "$RESET"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --restricted             use restricted Debian mode and restricted Neovim
  --enable-backports       pass through to restricted installer
  --assets-dir PATH        pass through to restricted installer
  --skip-docker            pass through to restricted installer
  --skip-fonts             pass through to restricted installer
  --pull-latest            reinstall offline assets in restricted mode
  -y, --yes                assume yes to prompts
  -h, --help               show help
EOF
}

main() {
  local mode="${DOTFILES_MODE:-full}"
  local restricted_args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --restricted) mode="restricted" ;;
      --enable-backports|--skip-docker|--skip-fonts|--pull-latest)
        restricted_args+=("$1")
        ;;
      --assets-dir)
        restricted_args+=("$1" "$2")
        shift
        ;;
      -y|--yes) export DOTFILES_ASSUME_YES=1 ;;
      -h|--help) usage; exit 0 ;;
      *) fatal "Unknown flag: $1" ;;
    esac
    shift
  done

  local os
  os="$(detect_os)"
  success "Detected OS: $os"
  success "Install mode: $mode"
  [[ "$mode" == "restricted" && "$os" == "macos" ]] && fatal "Restricted mode is Linux-only."

  confirm "Continue with installation?" || { warn "Aborted."; exit 0; }

  log "Running system installer..."
  case "$os:$mode" in
    macos:full) bash "$SCRIPT_DIR/install-macos.sh" ;;
    linux:restricted|wsl:restricted)
      bash "$SCRIPT_DIR/install-debian-restricted.sh" "${restricted_args[@]}"
      exit $?
      ;;
    linux:full|wsl:full) bash "$SCRIPT_DIR/install-debian.sh" "$os" ;;
  esac

  if [[ "$os" != "wsl" ]]; then
    log "Installing FiraCode Nerd Font..."
    bash "$SCRIPT_DIR/install-fonts.sh"
  else
    warn "On WSL, install FiraCode Nerd Font on the Windows host."
  fi

  log "Installing zsh plugins..."
  plugin_dir="$HOME/.local/share/zsh/plugins"
  mkdir -p "$plugin_dir"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$plugin_dir/$plugin/.git" ]]; then
      git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$plugin_dir/$plugin"
      success "installed $plugin"
    else
      info "$plugin already present"
    fi
  done

  log "Installing tmux plugin manager..."
  tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir/.git" ]]; then
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  log "Applying dotfiles..."
  if [[ -f "$SCRIPT_DIR/../home/dot_zshrc" ]]; then
    dotfiles_dir="$(cd "$SCRIPT_DIR/.." && pwd)"
  else
    dotfiles_dir="$DOTFILES_DIR"
    [[ -d "$dotfiles_dir/.git" ]] || git clone "$DOTFILES_REPO" "$dotfiles_dir"
  fi
  "$dotfiles_dir/scripts/apply-dotfiles.sh" --mode "$mode"

  if [[ "$SHELL" != *"zsh"* ]]; then
    zsh_path="$(command -v zsh)"
    if [[ -n "$zsh_path" ]]; then
      grep -q "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
      if confirm "Change default shell to Zsh?"; then
        chsh -s "$zsh_path" || warn "Could not change shell. Run: chsh -s $zsh_path"
      fi
    fi
  fi

  cat <<EOF

${GREEN}${BOLD}Done.${RESET}

Next steps:
  1. Restart your terminal or run: exec zsh
  2. Open tmux and press Ctrl-a then I to install tmux plugins
  3. Run: ./scripts/verify.sh
EOF
}

main "$@"
