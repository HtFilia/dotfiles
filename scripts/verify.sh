#!/usr/bin/env bash
# shellcheck disable=SC2016
# Read-only acceptance checks for installed tools and managed leaf files.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/profile.sh
. "$SCRIPT_DIR/profile.sh"
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
profile="$(dotfiles_profile "$profile")" || exit 1
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
if [[ -f "$HOME/.local/state/dotfiles/materialize" ]] && [[ "$(cat "$HOME/.local/state/dotfiles/materialize")" == file ]]; then
  for target in .zshenv .zshrc .tmux.conf .gitconfig .config/atuin/config.toml; do
    source_file="$SCRIPT_DIR/../home/$(printf '%s' "$target" | sed -e 's#^\.config/#dot_config/#' -e 's#^\.local/#dot_local/#' -e 's#^\.#dot_#' -e 's#/\.#/dot_#g')"
    check "$target matches source" cmp -s "$source_file" "$HOME/$target"
  done
fi
check 'Zsh syntax' zsh -n "$HOME/.zshrc"
check 'Completion permissions' zsh -fc 'autoload -Uz compaudit; [[ -z "$(compaudit 2>/dev/null)" ]]'
check 'bat Gruvbox theme' bash -c 'bat --list-themes | rg -x gruvbox-dark >/dev/null'
check 'Starship configuration' bash -c 'TERM=xterm-256color STARSHIP_LOG=error starship prompt >/dev/null'
check 'tmux terminfo' bash -c 'infocmp -x tmux-256color >/dev/null 2>&1'
# Terminfo output is useful on failure but verbose on success; hide via wrapper below.
if [[ "$profile" == server ]]; then
  if [[ -f "$HOME/.local/state/dotfiles/source" ]]; then
    source_root="$(cat "$HOME/.local/state/dotfiles/source")"
    if [[ -d "$source_root/home" ]] && available chezmoi; then
      check 'all managed server files match source' bash -c \
        'diff=$(DOTFILES_PROFILE=server chezmoi --config /dev/null --config-format toml --source "$1" --destination "$2" --mode "$3" diff --no-pager) || exit; [[ -z "$diff" ]]' \
        _ "$source_root/home" "$HOME" "$(cat "$HOME/.local/state/dotfiles/materialize" 2>/dev/null || printf file)"
    fi
  fi
  check 'Ghostty terminfo' bash -c 'infocmp -x xterm-ghostty >/dev/null 2>&1'
  for tool in atuin ncdu tldr htop gitleaks actionlint; do check "$tool available" available "$tool"; done
  check 'tldr pages available' bash -c 'tldr tar >/dev/null 2>&1'
  check 'system diagnostic commands' bash -c 'for tool in ip ss dig ping ps; do command -v "$tool" >/dev/null || exit 1; done'
  if [[ -f "$HOME/.local/state/dotfiles/editor-languages" ]]; then
    read -ra server_languages < "$HOME/.local/state/dotfiles/editor-languages"
    for language in "${server_languages[@]}"; do
      case "$language" in
        go) check 'Go editor runtime pin' asset_version_matches go go-linux-amd64 version ;;
        node|shell) check 'Node editor runtime pin' asset_version_matches node node-linux-x86_64 --version ;;
      esac
    done
  fi
  if [[ -f "$HOME/.local/state/dotfiles/system-baseline" ]]; then
    for timer in apt-daily.timer apt-daily-upgrade.timer logrotate.timer; do
      check "$timer enabled" systemctl is-enabled --quiet "$timer"
      check "$timer active" systemctl is-active --quiet "$timer"
    done
    for policy in 20auto-upgrades 52dotfiles-unattended; do
      check "$policy baseline policy" cmp -s "$SCRIPT_DIR/../system/debian/$policy" "/etc/apt/apt.conf.d/$policy"
    done
    check 'journal retention policy' cmp -s "$SCRIPT_DIR/../system/debian/20-dotfiles-retention.conf" /etc/systemd/journald.conf.d/20-dotfiles-retention.conf
    check 'persistent journal directory' test -d /var/log/journal
    check 'system journal group membership'  bash -c 'id -nG "$(id -un)" | tr " " "\n" | rg -qx systemd-journal'
  fi
fi
if [[ "$(uname -s)" == Linux ]]; then
  for pair in starship:starship-linux-x86_64 eza:eza-linux-x86_64 delta:delta-linux-x86_64 lazygit:lazygit-linux-x86_64 chezmoi:chezmoi-linux-amd64 just:just-linux-x86_64 nvim:neovim-linux-x86_64; do
    check "${pair%%:*} pin" asset_version_matches "${pair%%:*}" "${pair#*:}"
  done
  if [[ "$profile" == server ]]; then
    check 'gitleaks pin' asset_version_matches gitleaks gitleaks-linux-x64 version
    check 'actionlint pin' asset_version_matches actionlint actionlint-linux-amd64
  fi
fi
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  directory="$HOME/.local/share/zsh/plugins/$plugin"
  if [[ -d "$directory" ]]; then
    check "$plugin pin and clean checkout" plugin_matches "$plugin" "$HOME/.local/share/zsh/plugins"
  else printf 'optional - %s\n' "$plugin"; fi
done
if [[ "$(cat "$HOME/.local/state/dotfiles/shell-plugins" 2>/dev/null || true)" == installed || ( -d "$HOME/.local/share/zsh/plugins/zsh-autosuggestions" && -d "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting" ) ]]; then
  check 'Zsh plugins actually load' zsh -ic '(( ${+functions[_zsh_autosuggest_start]} && ${+functions[_zsh_highlight]} ))'
fi
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  check 'TPM pin and clean checkout' plugin_matches tmux-tpm "$HOME/.tmux/plugins"
fi
if available atuin && [[ -f "$HOME/.config/atuin/config.toml" ]]; then
  check 'Atuin local editable history' python3 -c 'import pathlib,tomllib; p=pathlib.Path.home()/".config/atuin/config.toml"; c=tomllib.loads(p.read_text()); assert c.get("auto_sync") is False and c.get("update_check") is False and c.get("enter_accept") is False'
fi
if [[ "$profile" == workstation ]]; then
  for tool in uv uvx mise yazi ya yq sd dust duf hyperfine watchexec xh lazydocker gitleaks actionlint go node npm python3 rustc cargo shellcheck shfmt bats pnpm biome ouch zstd sponge ts vidir parallel chafa ov hexyl dua broot czkawka_cli xcp viu vivid pastel tldr jc jless fastfetch cmatrix cava; do
    check "$tool available" available "$tool"
  done
  if [[ "$(uname -s)" == Linux ]]; then
    for pair in uv:uv-linux-x86_64 uvx:uv-linux-x86_64 mise:mise-linux-x86_64 yazi:yazi-linux-x86_64 yq:yq-linux-amd64 sd:sd-linux-x86_64 dust:dust-linux-x86_64 duf:duf-linux-x86_64 hyperfine:hyperfine-linux-x86_64 watchexec:watchexec-linux-x86_64 xh:xh-linux-x86_64 lazydocker:lazydocker-linux-x86_64 actionlint:actionlint-linux-amd64 node:node-linux-x86_64; do
      check "${pair%%:*} pin" asset_version_matches "${pair%%:*}" "${pair#*:}"
    done
    while IFS=$'\t' read -r tool key _member; do
      [[ -n "$tool" && "$tool" != \#* ]] || continue
      argument=--version
      [[ "$tool" != tmux ]] || argument=-V
      check "$tool extra pin" asset_version_matches "$tool" "$key" "$argument"
    done < "$SCRIPT_DIR/extra-tools.tsv"
    check 'pnpm executes' pnpm --version
    check 'Go pin'  asset_version_matches go go-linux-amd64 version
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
  check 'editor tool manifest exists' test -s "$HOME/.local/state/dotfiles/editor-tools"
  check 'selected editor parsers load' env DOTFILES_EDITOR_LANGUAGES="$(cat "$HOME/.local/state/dotfiles/editor-languages")" nvim --headless -u NONE "+lua dofile('$SCRIPT_DIR/verify-parsers.lua')"
  while IFS= read -r tool; do
    check "editor tool $tool" test -x "$HOME/.local/share/nvim/mason/bin/$tool"
  done <"$HOME/.local/state/dotfiles/editor-tools"
fi
printf '%s verification failure(s).\n' "$failures"
(( failures == 0 ))
