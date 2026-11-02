#!/usr/bin/env bash
# Checks for a machine where `chezmoi init --apply` has just run: acceptance,
# idempotence, ShellCheck on the scripts rendered for this machine, and the
# zsh helpers. Used by tests/container.sh and by the macOS CI job.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
for prefix in /opt/homebrew /usr/local; do
  if [[ "$(uname -s)" == Darwin && -x "$prefix/bin/brew" ]]; then PATH="$prefix/bin:$PATH"; break; fi
done
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

step 'Scripts rendered for this machine pass ShellCheck'
for template in "$(chezmoi source-path)"/run_*.tmpl; do
  rendered="$(chezmoi execute-template <"$template")"
  [[ -n "${rendered//[[:space:]]/}" ]] || continue
  shellcheck --shell=bash - <<<"$rendered"
  echo "ok - ${template##*/}"
done

step 'zsh helpers'
bash "$root/tests/shell-functions.sh"
