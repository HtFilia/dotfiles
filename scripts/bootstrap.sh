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
# shellcheck source=scripts/profile.sh
. "$SCRIPT_DIR/profile.sh"

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
  --profile PROFILE       workstation (default on new hosts) or server
  --system-baseline       apply the portable Debian 13 server baseline
  --dry-run               preview actions without installing or applying
  --skip-docker            do not install container packages
  --skip-fonts             do not install FiraCode Nerd Font
  --no-shell-plugins       skip zsh plugin installation
  --with-tpm               install optional tmux plugin manager
  --setup-editor           explicitly download language tools and parsers
  --editor-languages LIST  comma-separated subset: lua,python,go,rust,node,shell
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
  local profile="" editor_languages="" system_baseline=0 dry_run=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        [[ $# -ge 2 ]] || fatal "--profile requires a value"
        profile="$2"
        shift
        ;;
      --system-baseline) system_baseline=1 ;;
      --dry-run) dry_run=1 ;;
      --skip-docker) skip_docker=1 ;;
      --skip-fonts) skip_fonts=1 ;;
      --setup-editor) setup_editor=1 ;;
      --editor-languages) [[ $# -ge 2 ]] || fatal "--editor-languages requires a value"; editor_languages="$2"; setup_editor=1; shift ;;
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
  profile="$(dotfiles_profile "$profile")" || fatal "Unknown profile"
  [[ "$profile" == server || "$system_baseline" == 0 ]] || fatal "--system-baseline requires --profile server"
  if [[ -n "$editor_languages" ]]; then
    [[ "$editor_languages" =~ ^(lua|python|go|rust|node|shell)(,(lua|python|go|rust|node|shell))*$ ]] || fatal "Invalid editor language list"
    local language
    IFS=, read -ra selected_languages <<< "$editor_languages"
    for language in "${selected_languages[@]}"; do
      case "$language" in lua|python|go|rust|node|shell) ;; *) fatal "Unknown editor language: $language" ;; esac
    done
  fi
  export DOTFILES_PROFILE="$profile"
  if [[ "$profile" == server ]]; then
    skip_fonts=1
    install_code_extensions=0
    [[ "$(uname -s)" == Linux ]] || fatal "The server profile requires Linux."
  fi

  local os
  os="$(detect_os)"
  if [[ "$profile" == server && "$os" == wsl ]]; then fatal 'Server profile cannot run under WSL.'; fi
  if [[ "$system_baseline" == 1 ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "$ID:$VERSION_ID" == debian:13 ]] || fatal '--system-baseline requires Debian 13.'
  fi
  if [[ "$os" != macos ]]; then
    # shellcheck source=scripts/preflight.sh
    . "$SCRIPT_DIR/preflight.sh"
    preflight_linux "$profile"
    (( EUID != 0 )) || fatal "Run bootstrap as your regular SSH/development user."
  fi
  success "Detected OS: $os"
  (( system_baseline == 0 )) || "$SCRIPT_DIR/server-baseline.sh" --dry-run

  if (( dry_run )); then
    info "profile: $profile; desktop/fonts: $([[ "$profile" == server ]] && printf excluded || printf included)"
    if [[ "$profile" == server ]]; then
      # shellcheck source=scripts/server-packages.sh
      . "$SCRIPT_DIR/server-packages.sh"
      printf 'would install Debian packages:'; printf ' %s' "${dotfiles_server_packages[@]}"; printf '\n'
      printf 'would verify pinned downloads: starship eza delta lazygit chezmoi just Neovim gitleaks actionlint\n'
      if (( setup_editor )); then
        [[ -n "$editor_languages" ]] || selected_languages=(lua python go rust node shell)
        printf 'would provision editor languages:'; printf ' %s' "${selected_languages[@]}"; printf '\n'
        printf 'would install editor prerequisites:'
        dotfiles_server_editor_packages "${selected_languages[@]}" | tr '\n' ' '
        printf '\n'
      fi
    else
      info 'would run workstation installer and selected optional tools'
    fi
    (( install_shell_plugins == 0 )) || info 'would install pinned Zsh plugins'
    (( install_tpm == 0 )) || info 'would install pinned tmux TPM'
    info 'would apply Chezmoi source'
    if command -v chezmoi >/dev/null 2>&1; then "$SCRIPT_DIR/apply-dotfiles.sh" --profile "$profile" --dry-run; fi
    return 0
  fi

  confirm "Continue with installation?" || { warn "Aborted."; exit 0; }

  export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
  if [[ "$os" == macos ]]; then
    for prefix in /opt/homebrew /usr/local; do
      [[ ! -x "$prefix/bin/brew" ]] || { export PATH="$prefix/bin:$prefix/sbin:$PATH"; break; }
    done
  else
    :
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
        [[ -z "$editor_languages" ]] || server_args+=(--editor-languages "$editor_languages")
        bash "$SCRIPT_DIR/install-server.sh" "${server_args[@]}"
        if (( system_baseline )); then "$SCRIPT_DIR/server-baseline.sh" --apply; fi
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
    prepare_zsh_plugin_parents || fatal "Unsafe shell plugin parent"
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
  "$dotfiles_dir/scripts/apply-dotfiles.sh" --profile "$profile" --force

  if [[ "$install_code_extensions" == "1" ]]; then
    install_vscode_extensions "$dotfiles_dir/extensions.txt"
  else
    warn "Skipped VS Code extension installation."
  fi

  if [[ "$setup_editor" == 1 ]]; then
    if [[ -n "$editor_languages" ]]; then
      "$dotfiles_dir/scripts/setup-editor.sh" "${selected_languages[@]}"
    else
      "$dotfiles_dir/scripts/setup-editor.sh"
    fi
  fi
  mkdir -p "$HOME/.local/state/dotfiles"
  if [[ "$install_shell_plugins" == 1 ]]; then printf 'installed\n' > "$HOME/.local/state/dotfiles/shell-plugins"; else printf 'skipped\n' > "$HOME/.local/state/dotfiles/shell-plugins"; fi
  if [[ "$install_tpm" == 1 ]]; then printf 'installed\n' > "$HOME/.local/state/dotfiles/tpm"; fi

  if [[ "$os" == macos ]]; then
    current_shell="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"
  else
    current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  fi
  if [[ "$configure_shell" == "1" && "$current_shell" != *"zsh"* ]]; then
    zsh_path="$(command -v zsh)"
    if [[ -n "$zsh_path" ]]; then
      grep -Fxq "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
      if confirm "Change default shell to Zsh?"; then
        chsh -s "$zsh_path" || warn "Could not change shell. Run: chsh -s $zsh_path"
      fi
    fi
  elif [[ "$current_shell" != *"zsh"* ]]; then
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
