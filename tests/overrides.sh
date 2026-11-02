#!/usr/bin/env bash
# Each local override point changes behaviour while chezmoi and the source
# checkout stay clean. Runs on an installed machine; removes what it creates.
set -euo pipefail
source_dir="$(chezmoi source-path)"
profile="$(chezmoi execute-template '{{ .profile }}')"
source_status="$(git -C "$source_dir" status --porcelain)"
failures=0
created=()
cleanup() { rm -rf "${created[@]}"; }
trap cleanup EXIT
# write FILE CONTENT: create a local override file and remember it.
write() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
  created+=("$1")
}
check() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf 'ok - %s\n' "$label"
  else
    printf 'FAIL - %s: expected %q, got %q\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

write ~/.zshrc.settings 'export STARSHIP_CONFIG=/tmp/local-starship.toml RIPGREP_CONFIG_PATH=/tmp/local-rg ATUIN_CONFIG_DIR=/tmp/local-atuin'
check 'zsh: ~/.zshrc.settings selects another Starship config' /tmp/local-starship.toml "$(zsh -ic 'print -r -- $STARSHIP_CONFIG' 2>/dev/null)"
check 'zsh: ~/.zshrc.settings selects another ripgrep config' /tmp/local-rg "$(zsh -ic 'print -r -- $RIPGREP_CONFIG_PATH' 2>/dev/null)"
check 'zsh: ~/.zshrc.settings selects another atuin config directory' /tmp/local-atuin "$(zsh -ic 'print -r -- $ATUIN_CONFIG_DIR' 2>/dev/null)"

write ~/.zshrc.local "alias overrides-test='echo from-zshrc-local'"
check 'zsh: ~/.zshrc.local adds an alias' from-zshrc-local "$(zsh -ic 'overrides-test' 2>/dev/null)"

write ~/.zshenv.local 'export OVERRIDES_TEST=from-zshenv-local'
check 'zsh: ~/.zshenv.local reaches non-interactive shells' from-zshenv-local "$(zsh -c 'print -r -- $OVERRIDES_TEST')"

write ~/.gitconfig.local $'[user]\n\tname = Local Person'
check 'Git: ~/.gitconfig.local sets the identity' 'Local Person' "$(git config --global --includes user.name)"

write ~/.ssh/config.local $'Host overrides-test\n  HostName 192.0.2.10\n  User someone'
check 'SSH: ~/.ssh/config.local defines a host alias' 192.0.2.10 "$(ssh -G overrides-test 2>/dev/null | awk '$1 == "hostname" { print $2 }')"
check 'SSH: ~/.ssh/config.local wins over managed defaults' someone "$(ssh -G overrides-test 2>/dev/null | awk '$1 == "user" { print $2 }')"

write ~/.tmux.conf.local 'set -g status-position bottom'
check 'tmux: ~/.tmux.conf.local is loaded last' bottom \
  "$(tmux -L overrides-test -f ~/.tmux.conf new-session -d \; show-options -gv status-position \; kill-server)"

write ~/.config/nvim/lua/config/local.lua 'vim.g.overrides_test = "from-config-local"'
check 'Neovim: lua/config/local.lua runs after the managed options' from-config-local \
  "$(nvim --headless -u NONE '+lua require("config.options"); io.write(vim.g.overrides_test or "")' +qa 2>&1)"

if [[ "$profile" == workstation ]]; then
  write ~/.config/kitty/kitty.d/screen.conf 'font_size 18.0'
  check 'Kitty: kitty.d/*.conf overrides the managed config' 18.0 \
    "$(kitty +runpy 'from kitty.config import load_config; from kitty.constants import config_dir; import os; print(load_config(os.path.join(config_dir, "kitty.conf")).font_size)')"
fi

htoprc=~/.config/htop/htoprc
cp "$htoprc" "$htoprc.orig"
printf 'delay=20\n' >>"$htoprc"
chezmoi apply --no-tty
check 'htop: chezmoi keeps a locally modified htoprc' 1 "$(grep -c '^delay=20$' "$htoprc")"
mv "$htoprc.orig" "$htoprc"

check 'chezmoi diff stays empty with local overrides' '' "$(chezmoi diff --no-pager)"
check 'git status of the source checkout is unchanged' "$source_status" "$(git -C "$source_dir" status --porcelain)"
(( failures == 0 ))
