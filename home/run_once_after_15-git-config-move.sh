#!/usr/bin/env bash
# One-time move: the shared Git settings left ~/.gitconfig for
# ~/.config/git/config, so that ~/.gitconfig belongs to the machine. This
# removes from ~/.gitconfig each value the dotfiles set to exactly the same
# thing, and keeps everything else: identities, work settings, changed values.
# tests/git-migration.sh runs it with HOME pointing at a test directory.
set -euo pipefail
user_file="$HOME/.gitconfig"
managed_file="$HOME/.config/git/config"
[[ -f "$user_file" && -f "$managed_file" ]] || exit 0

# Pairs are matched by value, so a multi-valued key such as include.path
# loses only the values the dotfiles also set.
removable=()
while IFS= read -r -d '' entry; do
  [[ "$entry" == *$'\n'* ]] || continue
  key="${entry%%$'\n'*}"
  value="${entry#*$'\n'}"
  if git config --file "$user_file" --fixed-value --get-all "$key" "$value" >/dev/null 2>&1; then
    removable+=("$key" "$value")
  fi
done < <(git config --file "$managed_file" --no-includes --null --list)
((${#removable[@]})) || exit 0

backup="$HOME/.gitconfig.before-xdg"
[[ -e "$backup" ]] || cp -p "$user_file" "$backup"
for ((i = 0; i < ${#removable[@]}; i += 2)); do
  git config --file "$user_file" --fixed-value --unset-all "${removable[i]}" "${removable[i + 1]}" || true
done

# Drop the comment lines copied from the dotfiles, then the section headers
# left with no key, then repeated blank lines.
tidy="$(mktemp)"
awk '
  NR == FNR { line = $0; gsub(/^[ \t]+|[ \t]+$/, "", line); if (line ~ /^[#;]/) managed[line] = 1; next }
  {
    line = $0; gsub(/^[ \t]+|[ \t]+$/, "", line)
    if (line ~ /^[#;]/ && line in managed) next
    if (line ~ /^\[/) { printf "%s", pending; header = $0; pending = ""; next }
    if (line == "" || line ~ /^[#;]/) { if (header != "") pending = pending $0 "\n"; else print; next }
    if (header != "") { print header; header = "" }
    printf "%s", pending; pending = ""
    print
  }
  END { printf "%s", pending }
' "$managed_file" "$user_file" | cat -s | sed '/./,$!d' >"$tidy"
cat "$tidy" >"$user_file"
rm -f "$tidy"
printf 'Moved the shared Git settings out of %s; the former file is %s.\n' "$user_file" "$backup"
