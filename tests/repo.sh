#!/usr/bin/env bash
# Repository-wide checks: workflow lint, secret scan, ShellCheck and shfmt on
# the repository scripts, ShellCheck and on the package scripts rendered for every machine,
# and zsh syntax of each rendered .zshrc. tests/container.sh runs it on
# Fedora, where chezmoi installs actionlint, gitleaks and ShellCheck.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
step() { printf '\n== %s\n' "$*"; }

step 'Workflow lint'
actionlint

step 'Secret scan of the whole history'
gitleaks git --redact --no-banner

step 'Repository scripts'
shellcheck scripts/*.sh scripts/boot-art/*.sh tests/*.sh home/run_*.sh .githooks/*
# Formatting follows .editorconfig (two spaces, indented case branches).
shfmt -d scripts tests .githooks

step 'Templates rendered for each machine'
machines=(
  'fedora workstation perso true false'
  'debian workstation travail false false'
  'debian server perso false true'
  'debian server perso false false'
)
for machine in "${machines[@]}"; do
  read -r os profile context gaming baseline <<<"$machine"
  facts="\"os\":\"linux\",\"arch\":\"amd64\",\"osRelease\":{\"id\":\"$os\",\"versionID\":\"$([[ $os == debian ]] && echo 13 || echo 44)\"}"
  data="{\"chezmoi\":{$facts},\"profile\":\"$profile\",\"context\":\"$context\",\"gaming\":$gaming,\"systemBaseline\":$baseline}"
  render() { chezmoi --source "$root" execute-template --override-data "$data" <"$1"; }
  for template in home/run_*.tmpl; do
    rendered="$(render "$template")"
    [[ -n "${rendered//[[:space:]]/}" ]] || continue
    shellcheck --shell=bash - <<<"$rendered"
  done
  render home/dot_zshrc.tmpl | zsh -n
  printf 'ok - %s\n' "$machine"
done

step 'The Git settings move keeps what the machine set'
bash tests/git-migration.sh

step 'VS Code merges keep the UI and the local files'
bash tests/vscode-merge.sh

step 'Configs merged with a local file at apply time'
bash tests/local-merge.sh

step 'Local override files cannot be committed'
for path in home/dot_zshrc.local home/dot_zshrc.settings home/private_dot_ssh/private_config.local \
  home/dot_config/kitty/kitty.d/screen.conf home/dot_config/nvim/lua/config/local.lua \
  home/dot_config/nvim/lua/plugins/local.lua home/dot_config/Code/User/settings.local.json \
  home/dot_config/starship.local.toml home/dot_config/ripgrep/config.local \
  home/dot_config/lazygit/config.local.yml home/dot_config/fastfetch/config.local.jsonc; do
  git check-ignore -q "$path" || {
    printf 'not ignored: %s\n' "$path"
    exit 1
  }
done
echo 'ok - .gitignore covers every local override file'

step 'Every managed config has a machine-local override'
# Each deployed config, under ~/.config or directly in ~, needs a row in
# docs/LOCAL-OVERRIDES.md naming its path. ~/.local and ~/.claude hold data
# and generated references, not settings.
target_name() { sed -E 's/(^|\/)(create_|private_|executable_|modify_|empty_)+/\1/g; s/(^|\/)dot_/\1./g; s/\.tmpl$//' <<<"$1"; }
missing=()
for source in home/dot_config/* home/dot_* home/private_dot_* home/create_*dot_*; do
  [[ -e "$source" ]] || continue
  case "$source" in home/dot_config | home/dot_local | home/dot_claude) continue ;; esac
  target="$(target_name "${source#home/}")"
  [[ "$target" == .ssh ]] && target=.ssh/config
  # A single file under ~/.config matches its local file too (starship.toml,
  # starship.local.toml).
  [[ "$target" == .config/*.* ]] && target="${target%.*}"
  tilde='~'
  documented="$tilde/$target"
  grep -qF "$documented" docs/LOCAL-OVERRIDES.md || missing+=("$documented")
done
if ((${#missing[@]})); then
  printf 'no row in docs/LOCAL-OVERRIDES.md for: %s\n' "${missing[@]}"
  exit 1
fi
echo 'ok - docs/LOCAL-OVERRIDES.md covers every managed config'

step 'Hand-written colours belong to the Dusk palette'
# The palette is what the three generated files contain; Dusk.colors writes
# its colours as r,g,b.
generated=(home/dot_config/kitty/dusk.conf home/dot_config/nvim/lua/dusk_palette.lua
  home/dot_local/share/color-schemes/Dusk.colors)
palette="$({
  grep -ohiE '#[0-9a-f]{6}' "${generated[@]}"
  grep -oE '=[0-9]+,[0-9]+,[0-9]+$' "${generated[2]}" | tr -d '=' |
    while IFS=, read -r red green blue; do printf '#%02X%02X%02X\n' "$red" "$green" "$blue"; done
} | tr 'a-f' 'A-F' | sort -u)"
# Tints mixed by hand: delta's four diff backgrounds, then the background and
# selection of a Kitty window connected over SSH.
tints=('#2F3A32' '#3D5040' '#45302E' '#5E3B39' '#2E2322' '#4A3534')
strangers="$(grep -noiE '#[0-9a-f]{6}' home/dot_tmux.conf home/.chezmoitemplates/managed/starship.toml \
  home/.chezmoitemplates/managed/yazi-theme.toml home/dot_zshrc.tmpl home/dot_config/git/config \
  home/.chezmoitemplates/managed/fastfetch.jsonc home/dot_config/kitty/ssh-remote.conf |
  tr 'a-f' 'A-F' | grep -vF -f <(printf '%s\n' "$palette" "${tints[@]}") || true)"
if [[ -n "$strangers" ]]; then
  printf 'not in the palette:\n%s\n' "$strangers"
  exit 1
fi
echo 'ok - every hex colour is in the palette or a listed tint'

step 'Configured key bindings are typable on AZERTY'
# The keys each configuration binds: no digit (F1…F12 excepted), none of
# [ ] { } | \ ~. Lines are printed as file:key.
bound_keys() {
  # tmux: the first word after bind and its options.
  sed -nE 's/^bind(-key)?( +-[nr]| +-T +[^ ]+)* +([^ ]+).*/tmux:\3/p' home/dot_tmux.conf
  sed -nE 's/^map +([^ ]+).*/kitty:\1/p' home/dot_config/kitty/kitty.conf.tmpl
  grep -oE 'on *= *("[^"]+"|\[[^]]*\])' home/.chezmoitemplates/managed/yazi-keymap.toml |
    grep -oE '"[^"]+"' | sed 's/^/yazi:/'
  sed -nE 's/^ +[A-Za-z0-9-]+: +(.+)$/lazygit:\1/p' home/dot_config/lazygit/config.yml
  sed -nE 's/^ *"key": *"([^"]+)".*/vscode:\1/p' home/.chezmoitemplates/vscode/keybindings.jsonc
  sed -nE 's/^map\((\{[^}]*\}|"[^"]*"), *"([^"]+)".*/nvim:\2/p' home/dot_config/nvim/lua/config/keymaps.lua
  sed -nE 's/^vim\.g\.map(local)?leader *= *"(.*)"$/nvim:\2/p' home/dot_config/nvim/init.lua
  grep -oE -e "--bind '[^':]+" home/dot_zshrc.tmpl | sed "s/--bind '/fzf:/"
}
keys="$(bound_keys)"
untypable="$(sed -E 's/[Ff][0-9]+//g' <<<"$keys" | grep -nE ':.*[][{}|\\~0-9]' || true)"
if [[ -n "$untypable" ]]; then
  printf 'not typable on AZERTY:\n'
  while IFS=: read -r line _; do sed -n "${line}p" <<<"$keys"; done <<<"$untypable"
  exit 1
fi
echo "ok - $(wc -l <<<"$keys") bound keys"

step 'The repository stands alone'
# It is public: nothing names the private repositories around it, such as the
# one that generates the palette files.
if git grep -nIi 'homelab' -- . ':!tests/repo.sh'; then
  exit 1
fi
echo 'ok - no reference to a private repository'
