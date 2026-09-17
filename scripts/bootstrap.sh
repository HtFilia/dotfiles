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

DOTFILES_REPO="${DOTFILES_REPO:-git@github.com:HtFilia/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-plugins.sh
. "$SCRIPT_DIR/pinned-plugins.sh"

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
  --profile PROFILE       workstation (default) or server (SSH terminal/editor)
  --skip-docker            do not install container packages
  --skip-fonts             do not install FiraCode Nerd Font
  --no-shell-plugins       skip zsh plugin installation
  --with-tpm               install optional tmux plugin manager
  --setup-editor           explicitly download language tools and parsers
  --skip-vscode-extensions skip VS Code extension installation
  --configure-shell        allow /etc/shells and chsh changes
  --start-colima           start and enable Colima on macOS
  --enable-docker-group    add current Linux user to docker group
  -y, --yes                assume yes to prompts
  -h, --help               show help
EOF
}

install_vscode_extensions() {
  local extensions_file="$1"
  [[ -f "$extensions_file" ]] || return 0
  if ! command -v code >/dev/null 2>&1; then
    warn "VS Code CLI not found; skipped extension installation."
    return 0
  fi

  log "Installing VS Code extensions..."
  local extension
  while IFS= read -r extension || [[ -n "$extension" ]]; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    if code --install-extension "$extension" >/dev/null 2>&1; then
      success "installed $extension"
    else
      warn "Could not install VS Code extension: $extension"
    fi
  done <"$extensions_file"
}

main() {
  local install_shell_plugins=1 install_tpm=0 configure_shell=0 start_colima=0 enable_docker_group=0
  local install_code_extensions=1 skip_docker=0 skip_fonts=0 setup_editor=0
  local profile="${DOTFILES_PROFILE:-workstation}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        [[ $# -ge 2 ]] || fatal "--profile requires a value"
        profile="$2"
        shift
        ;;
      --skip-docker) skip_docker=1 ;;
      --skip-fonts) skip_fonts=1 ;;
      --setup-editor) setup_editor=1 ;;
      --with-tpm) install_tpm=1 ;;
      --no-shell-plugins) install_shell_plugins=0 ;;
      --skip-vscode-extensions) install_code_extensions=0 ;;
      --configure-shell) configure_shell=1 ;;
      --start-colima) start_colima=1 ;;
      --enable-docker-group) enable_docker_group=1 ;;
      -y|--yes) export DOTFILES_ASSUME_YES=1 ;;
      -h|--help) usage; exit 0 ;;
      *) fatal "Unknown flag: $1" ;;
    esac
    shift
  done
  case "$profile" in
    workstation|server) ;;
    *) fatal "Unknown profile: $profile" ;;
  esac
  export DOTFILES_PROFILE="$profile"
  if [[ "$profile" == server ]]; then
    skip_fonts=1
    install_code_extensions=0
    [[ "$(uname -s)" == Linux ]] || fatal "The server profile requires Linux."
  fi

  local os
  os="$(detect_os)"
  success "Detected OS: $os"

  confirm "Continue with installation?" || { warn "Aborted."; exit 0; }

  export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
  if [[ "$os" == macos ]]; then
    for prefix in /opt/homebrew /usr/local; do
      [[ ! -x "$prefix/bin/brew" ]] || { export PATH="$prefix/bin:$prefix/sbin:$PATH"; break; }
    done
  else
    # shellcheck source=scripts/preflight.sh
    . "$SCRIPT_DIR/preflight.sh"
    preflight_linux "$profile"
    (( EUID != 0 )) || fatal "Run bootstrap as your regular SSH/development user."
  fi
  log "Running system installer..."
  case "$os" in
    macos)
      macos_args=()
      [[ "$start_colima" == "1" ]] && macos_args+=(--start-colima)
      [[ "$skip_fonts" == "1" ]] && macos_args+=(--skip-fonts)
      [[ "$skip_docker" == "1" ]] && macos_args+=(--skip-docker)
      bash "$SCRIPT_DIR/install-macos.sh" "${macos_args[@]}"
      ;;
    linux|wsl)
      if [[ "$profile" == server ]]; then
        server_args=()
        [[ "$setup_editor" == "1" ]] && server_args+=(--setup-editor)
        bash "$SCRIPT_DIR/install-server.sh" "${server_args[@]}"
      else
      debian_args=("$os")
      [[ "$enable_docker_group" == "1" ]] && debian_args+=(--enable-docker-group)
      [[ "$skip_docker" == "1" ]] && debian_args+=(--skip-docker)
      bash "$SCRIPT_DIR/install-debian.sh" "${debian_args[@]}"
      fi
      ;;
  esac

  if [[ "$skip_fonts" == "1" ]]; then
    warn "Skipped font installation."
  elif [[ "$os" != "wsl" ]]; then
    log "Installing FiraCode Nerd Font..."
    bash "$SCRIPT_DIR/install-fonts.sh"
  else
    warn "On WSL, install FiraCode Nerd Font on the Windows host."
  fi

  if [[ "$install_shell_plugins" == "1" ]]; then
    log "Installing pinned zsh plugins..."
    plugin_dir="$HOME/.local/share/zsh/plugins"
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
      if install_pinned_plugin "$plugin" "$plugin_dir"; then
        success "installed $plugin"
      else
        fatal "Could not install pinned plugin: $plugin"
      fi
    done


  else
    warn "Skipped Zsh plugin installation."
  fi

    if [[ "$install_tpm" == 1 ]]; then
    log "Installing pinned tmux plugin manager..."
    if install_pinned_plugin tmux-tpm "$HOME/.tmux/plugins"; then
      success "installed tmux TPM"
    else
      fatal "Could not install pinned tmux TPM"
    fi
    fi

  log "Applying dotfiles..."
  if [[ -f "$SCRIPT_DIR/../home/dot_zshrc" ]]; then
    dotfiles_dir="$(cd "$SCRIPT_DIR/.." && pwd)"
  else
    dotfiles_dir="$DOTFILES_DIR"
    [[ -d "$dotfiles_dir/.git" ]] || git clone "$DOTFILES_REPO" "$dotfiles_dir"
  fi
  "$dotfiles_dir/scripts/apply-dotfiles.sh" --force

  if [[ "$install_code_extensions" == "1" ]]; then
    install_vscode_extensions "$dotfiles_dir/extensions.txt"
  else
    warn "Skipped VS Code extension installation."
  fi

  [[ "$setup_editor" != 1 ]] || "$dotfiles_dir/scripts/setup-editor.sh"

  if [[ "$configure_shell" == "1" && "${SHELL:-}" != *"zsh"* ]]; then
    zsh_path="$(command -v zsh)"
    if [[ -n "$zsh_path" ]]; then
      grep -Fxq "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
      if confirm "Change default shell to Zsh?"; then
        chsh -s "$zsh_path" || warn "Could not change shell. Run: chsh -s $zsh_path"
      fi
    fi
  elif [[ "${SHELL:-}" != *"zsh"* ]]; then
    warn "Default shell not changed. Re-run with --configure-shell to allow /etc/shells and chsh changes."
  fi

  cat <<EOF

${GREEN}${BOLD}Done.${RESET}

Next steps:
  1. Restart your terminal or run: exec zsh
  2. Run: ./scripts/verify.sh --profile $profile
  3. For a Mac connecting over SSH, see docs/VPS-GHOSTTY.md
EOF
}

main "$@"
