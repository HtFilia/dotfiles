#!/usr/bin/env bash
# Repository-wide checks: workflow lint, secret scan, ShellCheck on the
# repository scripts and on the package scripts rendered for every machine,
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
shellcheck scripts/*.sh tests/*.sh

step 'Templates rendered for each machine'
machines=(
  'fedora workstation perso true false'
  'debian workstation travail false false'
  'debian server perso false true'
  'debian server perso false false'
  'darwin workstation perso false false'
)
for machine in "${machines[@]}"; do
  read -r os profile context gaming baseline <<<"$machine"
  case "$os" in
    darwin) facts='"os":"darwin","arch":"arm64"' ;;
    *) facts="\"os\":\"linux\",\"arch\":\"amd64\",\"osRelease\":{\"id\":\"$os\",\"versionID\":\"$([[ $os == debian ]] && echo 13 || echo 44)\"}" ;;
  esac
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

step 'Local override files cannot be committed'
for path in home/dot_zshrc.local home/dot_zshrc.settings home/private_dot_ssh/private_config.local \
    home/dot_config/kitty/kitty.d/screen.conf home/dot_config/nvim/lua/config/local.lua \
    home/dot_config/nvim/lua/plugins/local.lua; do
  git check-ignore -q "$path" || { printf 'not ignored: %s\n' "$path"; exit 1; }
done
echo 'ok - .gitignore covers every local override file'

step 'Dropped platforms are gone'
# .chezmoiremove names the files those platforms left behind, and GitHub's
# Linux runners are called ubuntu-latest.
if git grep -nIiE 'ghostty|ubuntu|wsl|windows terminal|debian 12' -- . \
    ':!docs/MIGRATION.md' ':!home/.chezmoiremove' ':!.github/workflows/ci.yml' ':!tests/repo.sh'; then
  exit 1
fi
echo 'ok - no references outside the documented exceptions'
