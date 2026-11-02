#!/usr/bin/env bash
# shellcheck disable=SC2016  # single-quoted snippets are expanded by the shell that runs them
# Read-only acceptance checks for this machine, driven by the answers chezmoi
# recorded for it. Exits nonzero when a required tool or file is missing.
set -uo pipefail
case "${1:-}" in
  -h|--help) printf 'Usage: %s\nChecks the tools and files that chezmoi manages on this machine.\n' "$0"; exit 0 ;;
  '') ;;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
esac

PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
for prefix in /opt/homebrew /usr/local; do
  if [[ "$(uname -s)" == Darwin && -x "$prefix/bin/brew" ]]; then
    PATH="$prefix/bin:$prefix/sbin:$PATH:$prefix/opt/rustup/bin"
    break
  fi
done
export PATH

answers="$(chezmoi execute-template '{{ includeTemplate "osid" . }} {{ .profile }} {{ .context }} {{ .gaming }} {{ .systemBaseline }}' 2>/dev/null)" ||
  { printf 'chezmoi has no answers for this machine; run chezmoi init first.\n' >&2; exit 1; }
read -r osid profile context gaming baseline <<<"$answers"
printf 'Machine: %s, %s, %s, gaming=%s, systemBaseline=%s\n' "$osid" "$profile" "$context" "$gaming" "$baseline"

failures=0
check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'ok - %s\n' "$label"
  else
    printf 'FAIL - %s\n' "$label"
    failures=$((failures + 1))
  fi
}
available() { command -v "$1"; }

commands=(zsh git tmux nvim starship lazygit fzf rg fd bat eza zoxide atuin direnv delta jq just
  htop tldr shellcheck shfmt gitleaks actionlint chezmoi node npm)
if [[ "$profile" == workstation ]]; then
  commands+=(kitty gh fastfetch hyperfine dust uv uvx yq rustup)
  case "$osid" in
    fedora) commands+=(podman podman-compose code) ;;
    debian) commands+=(podman podman-compose) ;;
    darwin) commands+=(docker colima code) ;;
  esac
  [[ "$context" == perso && "$osid" != debian ]] && commands+=(go)
fi
[[ "$gaming" == true ]] && commands+=(mangohud gamemoded)
[[ "$profile" == server ]] && commands+=(ncdu ip ss dig ping ps)
for tool in "${commands[@]}"; do
  check "$tool available" available "$tool"
done

check 'managed files match the source state' chezmoi verify
check 'zsh syntax' zsh -n "$HOME/.zshrc"
check 'zsh plugins load' zsh -ic '(( ${+functions[_zsh_autosuggest_start]} && ${+functions[_zsh_highlight]} ))'
check 'completion directories are safe' zsh -fc 'autoload -Uz compaudit; [[ -z "$(compaudit 2>/dev/null)" ]]'
check 'Starship configuration' env TERM=xterm-256color STARSHIP_LOG=error starship prompt
check 'bat Gruvbox theme' bash -c 'bat --list-themes | grep -qx gruvbox-dark'
check 'Neovim meets the LazyVim minimum (0.11.2)' nvim --headless -u NONE '+lua if vim.fn.has("nvim-0.11.2") == 0 then vim.cmd("cquit 1") end' +qa
if [[ "$osid" != darwin ]]; then
  check 'tmux terminfo' infocmp -x tmux-256color
fi
if [[ "$profile" == workstation ]]; then
  check 'Rust toolchain installed' cargo --version
  check 'Kitty configuration loads' kitty +runpy 'from kitty.config import load_config; from kitty.constants import config_dir; import os; load_config(os.path.join(config_dir, "kitty.conf"))'
  if available code >/dev/null 2>&1; then
    if [[ "$osid" == darwin ]]; then settings="$HOME/Library/Application Support/Code/User/settings.json"; else settings="$HOME/.config/Code/User/settings.json"; fi
    check 'VS Code settings deployed' test -f "$settings"
  fi
fi
if [[ "$osid" == debian ]]; then
  check 'fd and bat use the Debian binaries' bash -c '[[ "$(readlink ~/.local/bin/fd)" == /usr/bin/fdfind && "$(readlink ~/.local/bin/bat)" == /usr/bin/batcat ]]'
  check 'nvim is the pinned release' bash -c '[[ "$(readlink ~/.local/bin/nvim)" == "$HOME/.local/opt/nvim/bin/nvim" ]]'
fi
if [[ "$profile" == server ]]; then
  check 'Kitty terminfo' infocmp -x xterm-kitty
fi
if [[ "$baseline" == true ]]; then
  for timer in apt-daily.timer apt-daily-upgrade.timer logrotate.timer; do
    check "$timer enabled and active" bash -c 'systemctl is-enabled --quiet "$1" && systemctl is-active --quiet "$1"' _ "$timer"
  done
  policies="$(chezmoi source-path)/.system/debian"
  check 'APT periodic policy' cmp -s "$policies/20auto-upgrades" /etc/apt/apt.conf.d/20auto-upgrades
  check 'unattended-upgrades policy' cmp -s "$policies/52dotfiles-unattended" /etc/apt/apt.conf.d/52dotfiles-unattended
  check 'journal retention policy' cmp -s "$policies/20-dotfiles-retention.conf" /etc/systemd/journald.conf.d/20-dotfiles-retention.conf
  check 'persistent journal' test -d /var/log/journal
  check 'systemd-journal group membership' bash -c 'id -nG "$(id -un)" | tr " " "\n" | grep -qx systemd-journal'
fi

printf '%s verification failure(s).\n' "$failures"
(( failures == 0 ))
