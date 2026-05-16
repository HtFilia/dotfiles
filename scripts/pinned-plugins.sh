#!/usr/bin/env bash
# Pinned shell/tmux plugin repositories.

pinned_plugin_field() {
  local key="$1" field="$2"
  case "$key:$field" in
    zsh-autosuggestions:repo) printf '%s\n' 'https://github.com/zsh-users/zsh-autosuggestions.git' ;;
    zsh-autosuggestions:dir) printf '%s\n' 'zsh-autosuggestions' ;;
    zsh-autosuggestions:commit) printf '%s\n' '85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5' ;;

    zsh-syntax-highlighting:repo) printf '%s\n' 'https://github.com/zsh-users/zsh-syntax-highlighting.git' ;;
    zsh-syntax-highlighting:dir) printf '%s\n' 'zsh-syntax-highlighting' ;;
    zsh-syntax-highlighting:commit) printf '%s\n' '1d85c692615a25fe2293bdd44b34c217d5d2bf04' ;;

    tmux-tpm:repo) printf '%s\n' 'https://github.com/tmux-plugins/tpm.git' ;;
    tmux-tpm:dir) printf '%s\n' 'tpm' ;;
    tmux-tpm:commit) printf '%s\n' '99469c4a9b1ccf77fade25842dc7bafbc8ce9946' ;;

    *) return 1 ;;
  esac
}

install_pinned_plugin() {
  local key="$1" base_dir="$2" repo dir commit dst actual
  repo="$(pinned_plugin_field "$key" repo)" || return 1
  dir="$(pinned_plugin_field "$key" dir)" || return 1
  commit="$(pinned_plugin_field "$key" commit)" || return 1
  dst="$base_dir/$dir"

  mkdir -p "$base_dir"
  if [[ ! -d "$dst/.git" ]]; then
    git clone --quiet "$repo" "$dst"
  fi
  git -C "$dst" fetch --quiet --depth=1 origin "$commit"
  git -C "$dst" checkout --quiet --detach "$commit"
  actual="$(git -C "$dst" rev-parse HEAD)"
  [[ "$actual" == "$commit" ]]
}
