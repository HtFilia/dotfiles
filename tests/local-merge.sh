#!/usr/bin/env bash
# The configs merged at apply time (home/.chezmoitemplates/local-merge):
# unchanged without a local file, every managed value kept with one, and the
# local values winning. Needs chezmoi; uses a throwaway HOME.
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
touch "$home/chezmoi.toml"
data='{"chezmoi":{"os":"linux","arch":"amd64","osRelease":{"id":"fedora","versionID":"44"}},"profile":"workstation","context":"perso","gaming":true,"systemBaseline":false}'
chezmoi_here() { HOME="$home" chezmoi --config "$home/chezmoi.toml" --source "$root/home" "$@"; }
# render SOURCE: the deployed content of a source file under home/.
render() { chezmoi_here execute-template --override-data "$data" <"$root/home/$1"; }
# as_json FORMAT FILE: the parsed values, keys sorted, comments ignored.
as_json() { chezmoi_here execute-template "{{ include \"$2\" | from$1 | toJson }}"; }
# local_file PATH CONTENT: write a local file under the throwaway HOME.
local_file() { mkdir -p "$(dirname "$home/$1")" && printf '%s\n' "$2" >"$home/$1"; }

# source | local file | format for parsing
merged=(
  'dot_config/starship.toml.tmpl|.config/starship.local.toml|Toml'
  'dot_config/yazi/yazi.toml.tmpl|.config/yazi/yazi.local.toml|Toml'
  'dot_config/yazi/theme.toml.tmpl|.config/yazi/theme.local.toml|Toml'
  'dot_config/yazi/keymap.toml.tmpl|.config/yazi/keymap.local.toml|Toml'
  'dot_config/tealdeer/config.toml.tmpl|.config/tealdeer/config.local.toml|Toml'
  'dot_config/navi/config.yaml.tmpl|.config/navi/config.local.yaml|Yaml'
  'dot_config/fastfetch/config.jsonc.tmpl|.config/fastfetch/config.local.jsonc|Jsonc'
)
for entry in "${merged[@]}"; do
  IFS='|' read -r source local format <<<"$entry"
  name="managed/$(sed -n 's/.*includeTemplate "managed\/\([^"]*\)".*/\1/p' "$root/home/$source")"
  check "$source: deployed unchanged without a local file" \
    "$(chezmoi_here execute-template --override-data "$data" "{{ includeTemplate \"$name\" . }}")" "$(render "$source")"
  render "$source" >"$home/before"
  # An empty local file (comments only for JSON) must keep every value.
  empty='# nothing'
  [[ "$format" == Jsonc ]] && empty='{}'
  local_file "$local" "$empty"
  render "$source" >"$home/after"
  check "$source: a local file keeps every managed value" "$(as_json "$format" "$home/before")" "$(as_json "$format" "$home/after")"
  rm "$home/$local"
done

local_file .config/starship.local.toml $'[character]\nsuccess_symbol = "[>](bold green)"'
render dot_config/starship.toml.tmpl >"$home/out"
check 'Starship: the local value wins, the rest of the table stays' '[>](bold green)|true' \
  "$(chezmoi_here execute-template "{{ \$c := include \"$home/out\" | fromToml }}{{ \$c.character.success_symbol }}|{{ hasKey \$c.character \"error_symbol\" }}")"

local_file .config/ripgrep/config.local '--no-hidden'
check 'ripgrep: local flags follow the managed ones' '--no-hidden' "$(render dot_config/ripgrep/config.tmpl | tail -1)"

local_file .config/yazi/keymap.local.toml $'[mgr]\nprepend_keymap = [ { on = "<A-x>", run = "quit" } ]'
render dot_config/yazi/keymap.toml.tmpl >"$home/out"
check 'yazi: local keys come first and the managed ones stay' "quit|$(($(grep -c 'on = ' "$root/home/.chezmoitemplates/managed/yazi-keymap.toml") + 1))" \
  "$(chezmoi_here execute-template "{{ \$k := (include \"$home/out\" | fromToml).mgr.prepend_keymap }}{{ (index \$k 0).run }}|{{ len \$k }}")"

local_file .config/fastfetch/config.local.jsonc '{ "logo": { "source": "debian" }, "modules": ["os"] }'
render dot_config/fastfetch/config.jsonc.tmpl >"$home/out"
check 'fastfetch: the local logo and modules replace the managed ones' '{"source":"debian"}|["os"]|true' \
  "$(chezmoi_here execute-template "{{ \$c := include \"$home/out\" | fromJsonc }}{{ toJson \$c.logo }}|{{ toJson \$c.modules }}|{{ hasKey \$c \"display\" }}")"
((failures == 0))
