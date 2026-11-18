#!/usr/bin/env bash
# The VS Code modify_ scripts keep what VS Code wrote, let the dotfiles win
# over it, and let settings.local.json / keybindings.local.json win over the
# dotfiles. Needs chezmoi and node; uses a throwaway HOME.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
user_dir="$home/.config/Code/User"
mkdir -p "$user_dir"
for kind in settings keybindings; do
  chezmoi --source "$root" execute-template \
    <"$root/home/dot_config/Code/User/modify_$kind.json.tmpl" >"$home/$kind.sh"
done
# merge KIND < deployed file: what chezmoi would write.
merge() { HOME="$home" sh "$home/$1.sh"; }
# value FILE KEY: a setting from a merged file, comments stripped.
value() { HOME="$home" node -e "$(sed -n '/^function parseJsonc/,/^}/p' "$root/home/.chezmoitemplates/vscode/merge.js")
  const v = parseJsonc(require('fs').readFileSync('$1', 'utf8'), '$1')['$2']; process.stdout.write(v === undefined ? '' : String(v));"; }

first="$(merge settings </dev/null)"
printf '%s\n' "$first" >"$user_dir/settings.json"
check 'a new machine gets the dotfiles settings' 14 "$(value "$user_dir/settings.json" editor.fontSize)"

# VS Code writes a key of its own and changes one the dotfiles set, keeping
# the comment header, as its JSONC editor does.
sed -i 's/"editor.fontSize": 14/"editor.fontSize": 20/; s/^{$/{\n  "telemetry.telemetryLevel": "off", \/\/ set in the UI/' "$user_dir/settings.json"
merge settings <"$user_dir/settings.json" >"$home/out.json"
check 'a key written in VS Code stays' off "$(value "$home/out.json" telemetry.telemetryLevel)"
check 'the dotfiles win over VS Code for their keys' 14 "$(value "$home/out.json" editor.fontSize)"

printf '{\n  // this machine\n  "editor.fontSize": 18,\n  "local.only": true,\n}\n' >"$user_dir/settings.local.json"
merge settings <"$home/out.json" >"$home/out2.json"
check 'settings.local.json wins over the dotfiles' '18|true' \
  "$(value "$home/out2.json" editor.fontSize)|$(value "$home/out2.json" local.only)"
check 'a second apply changes nothing' "$(cat "$home/out2.json")" "$(merge settings <"$home/out2.json")"

merge keybindings </dev/null >"$user_dir/keybindings.json"
managed_count="$(grep -c '"key"' "$user_dir/keybindings.json")"
sed -i 's/^\[$/[\n  { "key": "ctrl+alt+u", "command": "ui.added" },/' "$user_dir/keybindings.json"
printf '[ { "key": "ctrl+alt+l", "command": "local.added" } ]\n' >"$user_dir/keybindings.local.json"
merged_keys="$(merge keybindings <"$user_dir/keybindings.json")"
check 'keybindings: the dotfiles, then VS Code, then the local file' \
  "$((managed_count + 2))|ui.added|local.added" \
  "$(grep -c '"key"' <<<"$merged_keys")|$(grep -o '"[a-z]*\.added"' <<<"$merged_keys" | tr -d '"' | paste -sd '|')"
printf '%s\n' "$merged_keys" >"$user_dir/keybindings.json"
check 'keybindings: a second apply changes nothing' "$merged_keys" "$(merge keybindings <"$user_dir/keybindings.json")"
((failures == 0))
