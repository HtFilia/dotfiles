#!/usr/bin/env bash
# shellcheck disable=SC2016
# Read-only acceptance checks for installed tools and managed leaf files.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"
# shellcheck source=scripts/pinned-plugins.sh
. "$SCRIPT_DIR/pinned-plugins.sh"
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
profile="${DOTFILES_PROFILE:-}"
if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help) printf 'Usage: %s [--profile server|workstation]\nExits nonzero for missing required components or pin drift.\n' "$0"; exit 0 ;;
    --profile) [[ $# == 2 ]] || exit 1; profile="$2" ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
fi
if [[ -z "$profile" && -f "$HOME/.local/state/dotfiles/profile" ]]; then
  profile="$(cat "$HOME/.local/state/dotfiles/profile")"
fi
profile="${profile:-workstation}"
[[ "$profile" == server || "$profile" == workstation ]] || exit 1
failures=0
check() {
  local label="$1"
  shift
  if "$@"; then printf 'ok - %s\n' "$label"; else printf 'FAIL - %s\n' "$label" >&2; failures=$((failures + 1)); fi
}
available() { command -v "$1" >/dev/null 2>&1; }
plugin_matches() {
  local plugin="$1" base="$2" directory expected actual
  directory="$base/$(pinned_plugin_field "$plugin" dir)"
  expected="$(pinned_plugin_field "$plugin" commit)"
  actual="$(git -C "$directory" rev-parse HEAD 2>/dev/null)" || return 1
  [[ "$actual" == "$expected" && -z "$(git -C "$directory" status --porcelain)" ]]
}
for tool in zsh starship tmux chezmoi eza delta lazygit just bat fd rg fzf zoxide direnv nvim git jq; do
  check "$tool available" available "$tool"
done
for target in .zshenv .zshrc .tmux.conf .gitconfig .config/starship.toml .config/nvim/init.lua .config/nvim/lazy-lock.json; do
  check "$target deployed" test -f "$HOME/$target"
done
check 'Zsh syntax' zsh -n "$HOME/.zshrc"
check 'Completion permissions' zsh -fc 'autoload -Uz compaudit; [[ -z "$(compaudit 2>/dev/null)" ]]'
check 'bat Gruvbox theme' bash -c 'bat --list-themes | rg -x gruvbox-dark >/dev/null'
check 'Starship configuration' bash -c 'STARSHIP_LOG=error starship prompt >/dev/null'
check 'tmux terminfo' bash -c 'infocmp -x tmux-256color >/dev/null 2>&1'
# Terminfo output is useful on failure but verbose on success; hide via wrapper below.
if [[ "$profile" == server ]]; then
  check 'Ghostty terminfo' bash -c 'infocmp -x xterm-ghostty >/dev/null 2>&1'
fi
if [[ "$(uname -s)" == Linux ]]; then
  for pair in starship:starship-linux-x86_64 eza:eza-linux-x86_64 delta:delta-linux-x86_64 lazygit:lazygit-linux-x86_64 chezmoi:chezmoi-linux-amd64 just:just-linux-x86_64 nvim:neovim-linux-x86_64; do
    check "${pair%%:*} pin" asset_version_matches "${pair%%:*}" "${pair#*:}"
  done
fi
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  directory="$HOME/.local/share/zsh/plugins/$plugin"
  if [[ -d "$directory" ]]; then
    check "$plugin pin and clean checkout" plugin_matches "$plugin" "$HOME/.local/share/zsh/plugins"
  else printf 'optional - %s\n' "$plugin"; fi
done
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  check 'TPM pin and clean checkout' plugin_matches tmux-tpm "$HOME/.tmux/plugins"
fi
if [[ "$profile" == workstation ]]; then
  for tool in uv uvx mise yazi ya yq sd dust duf hyperfine watchexec xh lazydocker gitleaks actionlint go node npm python3 rustc cargo shellcheck; do
    check "$tool available" available "$tool"
  done
  if [[ "$(uname -s)" == Linux ]]; then
    for pair in uv:uv-linux-x86_64 uvx:uv-linux-x86_64 mise:mise-linux-x86_64 yazi:yazi-linux-x86_64 yq:yq-linux-amd64 sd:sd-linux-x86_64 dust:dust-linux-x86_64 duf:duf-linux-x86_64 hyperfine:hyperfine-linux-x86_64 watchexec:watchexec-linux-x86_64 xh:xh-linux-x86_64 lazydocker:lazydocker-linux-x86_64 actionlint:actionlint-linux-amd64 node:node-linux-x86_64; do
      check "${pair%%:*} pin" asset_version_matches "${pair%%:*}" "${pair#*:}"
    done
    check 'Go pin' asset_version_matches go go-linux-amd64 version
    check 'Gitleaks pin' asset_version_matches gitleaks gitleaks-linux-x64 version
  fi
  if available tokei; then check "tokei version" asset_version_matches tokei tokei-cargo --version; else printf "optional - tokei (Rust >=1.85 build)\n"; fi
  if available docker; then
    check 'Docker Compose plugin' docker compose version
    check 'Docker Buildx plugin' docker buildx version
  else printf 'optional - Docker (--skip-docker or WSL host integration)\n'; fi
  if [[ "$(uname -s)" == Darwin ]]; then
    check 'VS Code settings' test -f "$HOME/Library/Application Support/Code/User/settings.json"
  else check 'VS Code settings' test -f "$HOME/.config/Code/User/settings.json"; fi
fi
# Explicit editor provisioning is checked only when its marker exists.
if [[ -f "$HOME/.local/state/dotfiles/editor-languages" ]]; then
  while IFS= read -r tool; do
    check "editor tool $tool" test -x "$HOME/.local/share/nvim/mason/bin/$tool"
  done <"$HOME/.local/state/dotfiles/editor-tools"
fi
printf '%s verification failure(s).\n' "$failures"
(( failures == 0 ))
