#!/usr/bin/env bash
# Check installed tools, dotfile links and active Neovim profile.

set -u

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

status_ok() { printf "  %s+%s %-20s %s\n" "$GREEN" "$RESET" "$1" "$2"; }
status_miss() { printf "  %sx%s %-20s %s\n" "$RED" "$RESET" "$1" "${YELLOW}not installed${RESET}"; }
status_opt() { printf "  %s-%s %-20s %s\n" "$YELLOW" "$RESET" "$1" "${YELLOW}optional${RESET}"; }
section() { printf "\n%s%s%s\n" "$CYAN$BOLD" "$1" "$RESET"; }

check_tool() {
  local name="$1" version_cmd="${2:---version}" optional="${3:-0}"
  if command -v "$name" >/dev/null 2>&1; then
    local v
    v=$("$name" $version_cmd 2>&1 | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1 || true)
    status_ok "$name" "${v:-installed}"
  elif [[ "$optional" == "1" ]]; then
    status_opt "$name" ""
  else
    status_miss "$name" ""
  fi
}

asset_arch="$(pinned_asset_arch 2>/dev/null || printf '%s' x86_64)"

check_pinned_version() {
  local tool="$1" key="$2" version_cmd="${3:---version}"
  if command -v "$tool" >/dev/null 2>&1; then
    local expected out
    expected="$(pinned_asset_field "$key" version 2>/dev/null || true)"
    out="$("$tool" $version_cmd 2>&1 | head -1 || true)"
    if [[ -n "$expected" && "$out" == *"${expected#v}"* ]]; then
      status_ok "$tool" "pinned $expected"
    elif [[ -n "$expected" ]]; then
      status_ok "$tool" "installed (${out:-unknown}; pinned $expected)"
    else
      status_ok "$tool" "${out:-installed}"
    fi
  else
    status_miss "$tool" ""
  fi
}

printf "%s%sDotfiles verification%s\n" "$CYAN" "$BOLD" "$RESET"
printf "%s%s%s on %s %s%s\n" "$CYAN" "$BOLD" "$(date +'%Y-%m-%d %H:%M')" "$(uname -s)" "$(uname -m)" "$RESET"

section "Shell & prompt"
check_tool zsh
check_pinned_version starship "starship-linux-$asset_arch"
check_tool tmux

section "Editors"
check_tool nvim --version
if [[ -L "$HOME/.config/nvim" ]]; then
  target="$(readlink "$HOME/.config/nvim")"
  case "$target" in
    *nvim-lazyvim) status_ok "nvim profile" "LazyVim" ;;
    *nvim-restricted) status_ok "nvim profile" "restricted" ;;
    *) status_ok "nvim profile" "$target" ;;
  esac
else
  status_miss "nvim profile" ""
fi
check_tool code --version 1

section "Modern CLI"
check_pinned_version eza "eza-linux-$asset_arch"
check_tool bat --version
check_tool fd --version
check_tool rg --version
check_tool fzf --version
check_tool zoxide --version
check_pinned_version lazygit "lazygit-linux-$asset_arch"
check_pinned_version delta "delta-linux-$asset_arch"
check_tool atuin --version 1
check_tool direnv --version

section "Languages"
check_tool python3
check_pinned_version uv "uv-linux-$asset_arch"
check_tool go version
check_tool rustc --version
check_tool cargo --version

section "DevOps"
check_tool docker --version
check_tool docker-compose --version 1
check_tool git --version

section "AI / Assistant"
check_tool claude --version 1

section "Font"
if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "FiraCode Nerd Font"; then
  status_ok "FiraCode Nerd" "installed"
elif ls "$HOME/Library/Fonts/" /Library/Fonts/ 2>/dev/null | grep -iq "firacode.*nerd"; then
  status_ok "FiraCode Nerd" "installed"
else
  status_miss "FiraCode Nerd" ""
fi

section "Zsh plugins"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  if [[ -d "$HOME/.local/share/zsh/plugins/$p" ]]; then
    status_ok "$p" "installed"
  else
    status_miss "$p" ""
  fi
done

section "tmux TPM"
[[ -d "$HOME/.tmux/plugins/tpm" ]] && status_ok "TPM" "installed" || status_miss "TPM" ""

printf "\n%sLegend:%s %s+%s present  %sx%s missing  %s-%s optional\n\n" \
  "$BOLD" "$RESET" "$GREEN" "$RESET" "$RED" "$RESET" "$YELLOW" "$RESET"
