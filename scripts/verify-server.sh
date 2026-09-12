#!/usr/bin/env bash
# Fail when required server tools, managed files or terminal support are missing.
# shellcheck disable=SC2016
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
failures=0
check() {
  local label="$1"
  shift
  if "$@"; then printf 'ok - %s\n' "$label"; else printf 'FAIL - %s\n' "$label" >&2; failures=$((failures + 1)); fi
}
for tool in zsh starship tmux chezmoi eza delta lazygit just bat fd rg fzf zoxide direnv nvim; do
  check "$tool available" bash -c 'command -v "$1" >/dev/null' _ "$tool"
done
for target in .zshrc .tmux.conf .gitconfig .config/starship.toml .config/nvim/init.lua; do
  check "$target deployed" test -e "$HOME/$target"
done
check 'Ghostty terminfo' bash -c 'infocmp -x xterm-ghostty >/dev/null 2>&1'
check 'tmux terminfo' bash -c 'infocmp -x tmux-256color >/dev/null 2>&1'
check 'Zsh config syntax' zsh -n "$HOME/.zshrc"
startup_check='(( $+functions[z] )) &&
  if [[ -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    (( $+functions[_zsh_autosuggest_start] ))
  fi &&
  if [[ -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    (( $+functions[_zsh_highlight] ))
  fi'
check 'Zsh startup' script -q -e -c "zsh -lic '$startup_check'" /dev/null
check 'Zsh completion permissions' zsh -fc 'autoload -Uz compaudit; [[ -z "$(compaudit 2>/dev/null)" ]]'
check 'Gruvbox bat theme' bash -c 'bat --list-themes | rg -x gruvbox-dark >/dev/null'
check 'Starship prompt parses' bash -c 'STARSHIP_LOG=error starship prompt >/dev/null'
printf '%s verification failure(s).\n' "$failures"
(( failures == 0 ))
