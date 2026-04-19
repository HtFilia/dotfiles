#!/usr/bin/env bash
# ============================================================================
# verify.sh — Check which tools are installed and their versions
# ============================================================================

set -u

readonly GREEN=$'\033[0;32m'
readonly RED=$'\033[0;31m'
readonly YELLOW=$'\033[0;33m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

# Ensure ~/.local/bin and ~/.cargo/bin are on PATH for verification
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

status_ok() { printf "  %s✓%s %-18s %s\n" "$GREEN" "$RESET" "$1" "$2"; }
status_miss() { printf "  %s✗%s %-18s %s\n" "$RED" "$RESET" "$1" "${YELLOW}not installed${RESET}"; }
status_opt() { printf "  %s○%s %-18s %s\n" "$YELLOW" "$RESET" "$1" "${YELLOW}optional — not installed${RESET}"; }

section() { printf "\n%s%s%s\n" "$CYAN$BOLD" "$1" "$RESET"; }

check_tool() {
	local name="$1" version_cmd="${2:---version}" optional="${3:-0}"
	if command -v "$name" &>/dev/null; then
		# Get version — first line, first tag that looks like a number
		local v
		v=$("$name" $version_cmd 2>&1 | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1 || true)
		status_ok "$name" "${v:-installed}"
	elif [[ "$optional" == "1" ]]; then
		status_opt "$name" ""
	else
		status_miss "$name" ""
	fi
}

printf "%s%s╭─ Dotfiles verification ─────────────────────────────╮%s\n" "$CYAN" "$BOLD" "$RESET"
printf "%s%s╰─ $(date +'%Y-%m-%d %H:%M') on $(uname -s) $(uname -m) ─╯%s\n" "$CYAN" "$BOLD" "$RESET"

section "Shell & prompt"
check_tool zsh
check_tool starship
check_tool tmux

section "Editors"
check_tool nvim --version
check_tool code --version 1 # optional

section "Modern CLI"
check_tool eza --version
check_tool bat --version
check_tool fd --version
check_tool rg --version
check_tool fzf --version
check_tool zoxide --version
check_tool lazygit --version
check_tool delta --version
check_tool atuin --version 1
check_tool direnv --version

section "Languages"
check_tool python3
check_tool uv --version
check_tool go version
check_tool rustc --version
check_tool cargo --version
check_tool fnm --version 1

section "DevOps"
check_tool docker --version
check_tool docker-compose --version 1
check_tool git --version

section "Dotfiles manager"
check_tool chezmoi --version

section "AI / Assistant"
check_tool claude --version 1

section "Font check"
if ls ~/Library/Fonts/ /Library/Fonts/ 2>/dev/null | grep -iq "firacode.*nerd"; then
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
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
	status_ok "TPM" "installed"
else
	status_miss "TPM" ""
fi

printf "\n%sLegend:%s  %s✓%s present   %s✗%s missing (required)   %s○%s missing (optional)\n\n" \
	"$BOLD" "$RESET" "$GREEN" "$RESET" "$RED" "$RESET" "$YELLOW" "$RESET"
