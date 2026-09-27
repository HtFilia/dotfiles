#!/usr/bin/env bash
# Debian/Ubuntu server packages shared by installation and previews.
# shellcheck disable=SC2034
dotfiles_server_packages=(
  ca-certificates curl git openssh-client python3 zsh tmux ncurses-bin ncurses-term less man-db
  bsdextrautils util-linux unzip xz-utils fzf zoxide direnv ripgrep fd-find bat jq
  atuin ncdu tealdeer htop shellcheck shfmt bats
  iproute2 bind9-dnsutils iputils-ping procps
)

dotfiles_server_editor_packages() {
  local language
  for language in "$@"; do
    case "$language" in
      lua|python|go|rust|node|shell) ;;
      *) printf 'Unknown editor language: %s\n' "$language" >&2; return 2 ;;
    esac
  done
  for language in "$@"; do
    case "$language" in
      python) printf '%s\n' build-essential python3 python3-venv ;;
      lua|go|rust|node|shell) printf '%s\n' build-essential ;;
    esac
  done | awk '!seen[$0]++'
}
