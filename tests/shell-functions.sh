#!/usr/bin/env bash
# Behaviour of the zsh helpers and Git settings deployed on this machine.
set -euo pipefail
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
# check LABEL DETAIL COMMAND...: report whether COMMAND succeeds.
check() {
  local label="$1" detail="$2"
  shift 2
  if "$@"; then printf 'ok - %s\n' "$label"; else printf 'FAIL - %s (%s)\n' "$label" "$detail"; failures=$((failures + 1)); fi
}

# Print a function definition from the deployed ~/.zshrc.
zsh_function() {
  awk -v name="$1()" 'index($0, name) == 1 { found = 1 } found { print } found && /^}$/ { exit }' "$HOME/.zshrc"
}
repository() {
  rm -rf "$work/repo" && git init -q "$work/repo"
}

repository
for name in 'space name.txt' '-leading.txt' 'colon:name.txt'; do printf 'needle\n' >"$work/repo/$name"; done
(cd "$work/repo" && zsh -fc "$(zsh_function fga)"$'\nfzf() { cat; }\nfga')
staged="$(git -C "$work/repo" diff --cached --name-only | sort | tr '\n' '|')"
check 'fga stages names with spaces, dashes and colons' "staged $staged" \
  test "$staged" = '-leading.txt|colon:name.txt|space name.txt|'

repository
printf 'needle\n' >"$work/repo/file.txt"
(cd "$work/repo" && zsh -fc "$(zsh_function fga)"$'\nfzf() { return 130; }\nfga') || true
check 'cancelling fga stages nothing' 'files were staged' \
  test -z "$(git -C "$work/repo" diff --cached --name-only)"

mkdir -p "$work/search"
printf 'needle\n' >"$work/search/space:name.txt"
printf '#!/bin/sh\nprintf "%%s\\n" "$@" >"%s/arguments"\n' "$work" >"$work/editor"
chmod +x "$work/editor"
(cd "$work/search" && EDITOR="$work/editor" zsh -fc "$(zsh_function frg)"$'\nfzf() { sed -n 1p; }\nfrg needle')
opened="$(tr '\n' '|' <"$work/arguments")"
check 'frg opens the file at the matching line' "editor received $opened" \
  test "$opened" = '+1|--|./space:name.txt|'

command="$(git config --file "$HOME/.gitconfig" mergetool.nvim.cmd)"
arguments="$(LOCAL='local file' REMOTE='remote file' MERGED='merged file' sh -c "nvim() { printf '%s\n' \"\$@\"; }; $command" | head -4 | tr '\n' '|')"
check 'git mergetool quotes file names' "nvim received $arguments" \
  test "$arguments" = '-d|local file|remote file|merged file|'

repository
hidden=()
for path in Cargo.lock .python-version .vscode/tasks.json vendor/code.go; do
  git -C "$work/repo" check-ignore -q "$path" && hidden+=("$path")
done
check 'the global ignore keeps lockfiles, runtime pins and shared editor files' "hidden: ${hidden[*]:-}" \
  test "${#hidden[@]}" -eq 0

(( failures == 0 ))
