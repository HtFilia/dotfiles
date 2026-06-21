#!/usr/bin/env bash
# Check installed tools, dotfile links and active Neovim profile.

set -u

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"
# shellcheck source=scripts/pinned-plugins.sh
. "$SCRIPT_DIR/pinned-plugins.sh"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
if [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  if command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix 2>/dev/null)"
    [[ -d "$brew_prefix/opt/node@24/bin" ]] && export PATH="$brew_prefix/opt/node@24/bin:$PATH"
    [[ -d "$brew_prefix/opt/python@3.14/libexec/bin" ]] && export PATH="$brew_prefix/opt/python@3.14/libexec/bin:$PATH"
    unset brew_prefix
  fi
fi

status_ok() { printf "  %s+%s %-20s %s\n" "$GREEN" "$RESET" "$1" "$2"; }
status_miss() { printf "  %sx%s %-20s %s\n" "$RED" "$RESET" "$1" "${YELLOW}${2:-not installed}${RESET}"; }
status_opt() { printf "  %s-%s %-20s %s\n" "$YELLOW" "$RESET" "$1" "${YELLOW}optional${RESET}"; }
section() { printf "\n%s%s%s\n" "$CYAN$BOLD" "$1" "$RESET"; }

check_tool() {
  local name="$1" version_cmd="${2:---version}" optional="${3:-0}"
  if command -v "$name" >/dev/null 2>&1; then
    local v
    v=$("$name" "$version_cmd" 2>&1 | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1 || true)
    status_ok "$name" "${v:-installed}"
  elif [[ "$optional" == "1" ]]; then
    status_opt "$name" ""
  else
    status_miss "$name" ""
  fi
}

check_bat_theme() {
  local theme="$1"
  if command -v bat >/dev/null 2>&1 && bat --list-themes 2>/dev/null | grep -Fxq "$theme"; then
    status_ok "bat theme" "$theme"
  else
    status_miss "bat theme" "$theme"
  fi
}

asset_arch="$(pinned_asset_arch 2>/dev/null || printf '%s' x86_64)"
asset_go_arch="$(pinned_asset_go_arch 2>/dev/null || printf '%s' amd64)"
os_name="$(uname -s)"

check_pinned_version() {
  local tool="$1" key="$2" version_cmd="${3:---version}"
  if command -v "$tool" >/dev/null 2>&1; then
    local expected out
    expected="$(pinned_asset_field "$key" version 2>/dev/null || true)"
    out="$("$tool" "$version_cmd" 2>&1 | head -1 || true)"
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

check_pinned_plugin() {
  local key="$1" base_dir="$2" dir expected actual
  dir="$(pinned_plugin_field "$key" dir 2>/dev/null || true)"
  expected="$(pinned_plugin_field "$key" commit 2>/dev/null || true)"
  if [[ -n "$dir" && -d "$base_dir/$dir/.git" ]]; then
    actual="$(git -C "$base_dir/$dir" rev-parse HEAD 2>/dev/null || true)"
    if [[ "$actual" == "$expected" ]]; then
      status_ok "$key" "pinned ${expected:0:12}"
    else
      status_miss "$key" "expected ${expected:0:12}, got ${actual:0:12}"
    fi
  else
    status_miss "$key" ""
  fi
}

printf "%s%sDotfiles verification%s\n" "$CYAN" "$BOLD" "$RESET"
printf "%s%s%s on %s %s%s\n" "$CYAN" "$BOLD" "$(date +'%Y-%m-%d %H:%M')" "$(uname -s)" "$(uname -m)" "$RESET"

section "Shell & prompt"
check_tool zsh
if [[ "$os_name" == "Darwin" ]]; then
  check_tool starship --version
else
  check_pinned_version starship "starship-linux-$asset_arch"
fi
check_tool tmux
check_tool just --version
if command -v zsh >/dev/null 2>&1; then
  compaudit_out="$(zsh -fc 'autoload -Uz compaudit; compaudit' 2>/dev/null || true)"
  if [[ -z "$compaudit_out" ]]; then
    status_ok "compaudit" "secure"
  else
    status_miss "compaudit" "insecure paths"
    printf '%s\n' "$compaudit_out"
  fi
fi

section "Editors"
check_tool nvim --version
if [[ -L "$HOME/.config/nvim" ]]; then
  target="$(readlink "$HOME/.config/nvim")"
  if [[ ! -e "$target" ]]; then
    status_miss "nvim profile" "dangling: $target"
  else
    case "$target" in
      *dot_config/nvim) status_ok "nvim profile" "managed" ;;
      *) status_ok "nvim profile" "$target" ;;
    esac
  fi
else
  status_miss "nvim profile" ""
fi
check_tool code --version 1
check_tool chezmoi --version

section "Modern CLI"
if [[ "$os_name" == "Darwin" ]]; then
  check_tool eza --version
else
  check_pinned_version eza "eza-linux-$asset_arch"
fi
check_tool bat --version
check_bat_theme "gruvbox-dark"
check_tool fd --version
check_tool rg --version
check_tool fzf --version
check_tool zoxide --version
if [[ "$os_name" == "Darwin" ]]; then
  check_tool mise --version
  check_tool yazi --version
  check_tool yq --version
  check_tool sd --version
  check_tool dust --version
  check_tool duf --version
  check_tool hyperfine --version
  check_tool tokei --version
  check_tool watchexec --version
  check_tool xh --version
  check_tool lazydocker --version
else
  check_pinned_version mise "mise-linux-$asset_arch"
  check_pinned_version yazi "yazi-linux-$asset_arch"
  check_pinned_version yq "yq-linux-$asset_go_arch"
  check_pinned_version sd "sd-linux-$asset_arch"
  check_pinned_version dust "dust-linux-$asset_arch"
  check_pinned_version duf "duf-linux-$asset_arch"
  check_pinned_version hyperfine "hyperfine-linux-$asset_arch"
  check_tool tokei --version
  check_pinned_version watchexec "watchexec-linux-$asset_arch"
  check_pinned_version xh "xh-linux-$asset_arch"
  check_pinned_version lazydocker "lazydocker-linux-$asset_arch"
fi
if [[ "$os_name" == "Darwin" ]]; then
  check_tool lazygit --version
  check_tool delta --version
else
  check_pinned_version lazygit "lazygit-linux-$asset_arch"
  check_pinned_version delta "delta-linux-$asset_arch"
fi
check_tool atuin --version 1
check_tool direnv --version

section "Languages"
check_tool python3
if [[ "$os_name" == "Darwin" ]]; then
  check_tool uv --version
else
  check_pinned_version uv "uv-linux-$asset_arch"
fi
check_tool go version
if [[ "$os_name" == "Darwin" ]]; then
  check_tool node --version
else
  check_pinned_version node "node-linux-$asset_arch" --version
fi
check_tool npm --version 1
check_tool pnpm --version 1
check_tool rustc --version
check_tool cargo --version

section "Quality"
check_tool shellcheck --version
check_tool shfmt --version 1
check_tool bats --version 1
check_tool biome --version 1
if [[ "$os_name" == "Darwin" ]]; then
  check_tool actionlint --version
  check_tool gitleaks version
else
  check_pinned_version actionlint "actionlint-linux-$asset_go_arch"
  check_pinned_version gitleaks "gitleaks-linux-x64" version
fi

section "DevOps"
check_tool docker --version
check_tool docker-compose --version 1
check_tool git --version

section "AI / Assistant"
check_tool claude --version 1

section "Font"
if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "FiraCode Nerd Font"; then
  status_ok "FiraCode Nerd" "installed"
elif find "$HOME/Library/Fonts" /Library/Fonts -maxdepth 1 -iname '*firacode*nerd*' -print -quit 2>/dev/null | grep -q .; then
  status_ok "FiraCode Nerd" "installed"
else
  status_miss "FiraCode Nerd" ""
fi

section "Zsh plugins"
check_pinned_plugin zsh-autosuggestions "$HOME/.local/share/zsh/plugins"
check_pinned_plugin zsh-syntax-highlighting "$HOME/.local/share/zsh/plugins"

section "tmux TPM"
check_pinned_plugin tmux-tpm "$HOME/.tmux/plugins"

printf "\n%sLegend:%s %s+%s present  %sx%s missing  %s-%s optional\n\n" \
  "$BOLD" "$RESET" "$GREEN" "$RESET" "$RED" "$RESET" "$YELLOW" "$RESET"
