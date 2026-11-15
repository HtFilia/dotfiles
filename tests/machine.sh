#!/usr/bin/env bash
# Checks for a machine where `chezmoi init --apply` has just run: acceptance,
# idempotence, ShellCheck on the scripts rendered for this machine, and the
# zsh helpers. Used by tests/container.sh.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH
step() { printf '\n== %s\n' "$*"; }

step 'Acceptance checks'
bash "$root/scripts/verify.sh"

step 'A second apply changes nothing'
pending="$(chezmoi status)"
[[ -z "$pending" ]] || {
  printf 'chezmoi status after the first apply:\n%s\n' "$pending"
  exit 1
}
chezmoi apply --no-tty
difference="$(chezmoi diff --no-pager)"
[[ -z "$difference" ]] || {
  printf '%s\n' "$difference"
  exit 1
}
echo 'chezmoi status and chezmoi diff are empty.'

source_dir="$(chezmoi source-path)"
if [[ -L "$HOME/.local/share/chezmoi" || ! -w "$source_dir" ]]; then
  echo 'Skipping chezmoi update and re-add: the source is a read-only working tree.'
else
  step 'chezmoi update pulls and applies'
  chezmoi update --no-tty
  [[ -z "$(chezmoi diff --no-pager)" ]] || {
    echo 'chezmoi update left differences'
    exit 1
  }
  echo 'chezmoi update succeeded and left nothing to apply.'

  step 'chezmoi re-add copies a changed file back into the source'
  printf -- '--sort=path\n' >>"$HOME/.config/ripgrep/config"
  chezmoi re-add "$HOME/.config/ripgrep/config"
  grep -qx -- '--sort=path' "$source_dir/dot_config/ripgrep/config" || {
    echo 're-add did not update the source'
    exit 1
  }
  git -C "$source_dir" checkout -- dot_config/ripgrep/config
  chezmoi apply --no-tty
  [[ -z "$(chezmoi diff --no-pager)" ]] || {
    echo 'restoring after re-add left differences'
    exit 1
  }
  echo 'chezmoi re-add updated the source; the test change was reverted.'

  step 'The pre-commit hook refuses a staged secret'
  [[ "$(git -C "$source_dir" config core.hooksPath)" == .githooks ]] || {
    echo 'chezmoi apply did not enable .githooks'
    exit 1
  }
  # A random token in GitHub's format, made here so that none is committed.
  token="ghp_$(head -c 200 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | cut -c1-36)"
  printf 'token = "%s"\n' "$token" >"$source_dir/leak-test.toml"
  git -C "$source_dir" add leak-test.toml
  if git -C "$source_dir" hook run pre-commit >/dev/null 2>&1; then
    refused=0
  else
    refused=1
  fi
  git -C "$source_dir" rm -q -f --cached leak-test.toml
  rm -f "$source_dir/leak-test.toml"
  ((refused)) || {
    echo 'the pre-commit hook accepted a staged token'
    exit 1
  }
  echo 'The hook refused the commit.'
fi

step 'Scripts rendered for this machine pass ShellCheck'
for template in "$(chezmoi source-path)"/run_*.tmpl; do
  rendered="$(chezmoi execute-template <"$template")"
  [[ -n "${rendered//[[:space:]]/}" ]] || continue
  shellcheck --shell=bash - <<<"$rendered"
  echo "ok - ${template##*/}"
done

step 'zsh helpers'
bash "$root/tests/shell-functions.sh"

step 'The tools reference names every alias and helper'
# The aliases that ~/.zshrc adds to those of a zsh without it (the system's
# and zsh's own), and the functions it defines (a leading _ marks an
# internal one).
empty="$(mktemp -d)"
# shellcheck disable=SC2016
list_aliases='print -l -- ${(ko)aliases}'
names="$({
  comm -23 <(env -u CLAUDECODE zsh -ic "$list_aliases" 2>/dev/null | sort -u) \
    <(ZDOTDIR="$empty" zsh -ic "$list_aliases" 2>/dev/null | sort -u)
  sed -nE 's/^([a-z][a-z0-9_-]*)\(\) \{.*/\1/p' "$HOME/.zshrc"
} | sort -u)"
rmdir "$empty"
missing=()
while IFS= read -r name; do
  # Named alone, or followed by its arguments: `fh` or `fh [QUERY]`.
  grep -qF -e "\`$name\`" -e "\`$name " "$HOME/.claude/dotfiles-tools.md" || missing+=("$name")
done <<<"$names"
((${#missing[@]} == 0)) || {
  printf 'not in dotfiles-tools.md: %s\n' "${missing[*]}"
  exit 1
}
echo "ok - $(wc -l <<<"$names") aliases and helpers are documented"

step 'Local overrides'
bash "$root/tests/overrides.sh"

step 'Neovim language servers'
bash "$root/tests/editor.sh"
