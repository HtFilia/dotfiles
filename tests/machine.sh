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
[[ -z "$pending" ]] || { printf 'chezmoi status after the first apply:\n%s\n' "$pending"; exit 1; }
chezmoi apply --no-tty
difference="$(chezmoi diff --no-pager)"
[[ -z "$difference" ]] || { printf '%s\n' "$difference"; exit 1; }
echo 'chezmoi status and chezmoi diff are empty.'

source_dir="$(chezmoi source-path)"
if [[ -L "$HOME/.local/share/chezmoi" || ! -w "$source_dir" ]]; then
  echo 'Skipping chezmoi update and re-add: the source is a read-only working tree.'
else
  step 'chezmoi update pulls and applies'
  chezmoi update --no-tty
  [[ -z "$(chezmoi diff --no-pager)" ]] || { echo 'chezmoi update left differences'; exit 1; }
  echo 'chezmoi update succeeded and left nothing to apply.'

  step 'chezmoi re-add copies a changed file back into the source'
  printf -- '--sort=path\n' >>"$HOME/.config/ripgrep/config"
  chezmoi re-add "$HOME/.config/ripgrep/config"
  grep -qx -- '--sort=path' "$source_dir/dot_config/ripgrep/config" || { echo 're-add did not update the source'; exit 1; }
  git -C "$source_dir" checkout -- dot_config/ripgrep/config
  chezmoi apply --no-tty
  [[ -z "$(chezmoi diff --no-pager)" ]] || { echo 'restoring after re-add left differences'; exit 1; }
  echo 'chezmoi re-add updated the source; the test change was reverted.'
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

step 'Local overrides'
bash "$root/tests/overrides.sh"
