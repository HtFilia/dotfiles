#!/usr/bin/env bash
# The one-time move of the shared Git settings to ~/.config/git/config keeps
# what the machine set in ~/.gitconfig and removes only the dotfiles' copy.
# Runs anywhere with Git; uses a throwaway HOME.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$root/home/run_once_after_15-git-config-move.sh"
failures=0
check() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf 'ok - %s\n' "$label"
  else
    printf 'FAIL - %s: expected %q, got %q\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

home="$(mktemp -d)"
trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/git"
cp "$root/home/dot_config/git/config" "$home/.config/git/config"
# A machine before the move: the former managed file, then what a work setup
# added with `git config --global`, including a changed value and an extra
# include.
{
  cat "$root/home/dot_config/git/config"
  printf '[user]\n\tname = Work Person\n\temail = person@work.example\n'
  printf '# Added by the work setup\n[http]\n\tproxy = http://proxy.example:3128\n'
  printf '[pull]\n\trebase = false\n'
  printf '[include]\n\tpath = ~/.gitconfig.work\n'
} >"$home/.gitconfig"
original="$(cat "$home/.gitconfig")"

# The value Git uses: with ~/.gitconfig present, `--global` would read only
# that file, so read the effective configuration from outside any repository.
effective() { (cd "$home" && HOME="$home" XDG_CONFIG_HOME="$home/.config" GIT_CONFIG_NOSYSTEM=1 git config "$@"); }
user() { git config --file "$home/.gitconfig" "$@"; }

HOME="$home" bash "$script" >/dev/null
check 'the former file is kept aside' "$original" "$(cat "$home/.gitconfig.before-xdg")"
check 'the work identity stays' 'Work Person' "$(user user.name)"
check 'a work setting stays, with its comment' 'http://proxy.example:3128|1' \
  "$(user http.proxy)|$(grep -c '^# Added by the work setup$' "$home/.gitconfig")"
check 'a changed value stays and wins' 'false|false' "$(user pull.rebase)|$(effective pull.rebase)"
# shellcheck disable=SC2088 # a literal ~, as written in the file
check 'only the extra include stays' '~/.gitconfig.work' "$(user --get-all include.path)"
check 'the shared settings now come from ~/.config/git/config' 'delta|' \
  "$(effective core.pager)|$(user core.pager || true)"
check 'no dotfiles comment or empty section is left' '0' \
  "$(grep -cE '^\[(core|delta|alias)|Dusk' "$home/.gitconfig" || true)"
check 'the effective aliases are unchanged' "$(git config --file "$root/home/dot_config/git/config" alias.cleanup)" \
  "$(effective alias.cleanup)"

after="$(cat "$home/.gitconfig")"
HOME="$home" bash "$script" >/dev/null
check 'a second run changes nothing' "$after" "$(cat "$home/.gitconfig")"

# A new machine: ~/.gitconfig is the create_ stub, which has no managed value.
cp "$root/home/create_empty_dot_gitconfig" "$home/.gitconfig"
rm "$home/.gitconfig.before-xdg"
HOME="$home" bash "$script" >/dev/null
check 'a new machine keeps its stub and gets no copy' "$(cat "$root/home/create_empty_dot_gitconfig")|absent" \
  "$(cat "$home/.gitconfig")|$([[ -e "$home/.gitconfig.before-xdg" ]] && echo present || echo absent)"
((failures == 0))
