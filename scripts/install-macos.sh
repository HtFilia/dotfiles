#!/usr/bin/env bash
# Homebrew-native workstation installation, with independent CLI fallbacks.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install-report.sh
. "$SCRIPT_DIR/install-report.sh"
start_colima=0 skip_fonts=0 skip_docker=0
methods="${DOTFILES_INSTALL_METHODS:-native,github,source}"
while (( $# )); do
  case "$1" in
    --start-colima) start_colima=1 ;;
    --skip-fonts) skip_fonts=1 ;;
    --skip-docker) skip_docker=1 ;;
    --methods) [[ $# -ge 2 ]] || exit 2; methods="$2"; shift ;;
    -h|--help) printf 'Usage: %s [--methods native,github,source] [--start-colima] [--skip-fonts] [--skip-docker]\n' "$0"; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
validate_install_methods "$methods"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  printf 'Finish Command Line Tools installation, then rerun.\n'
  exit 2
fi
command -v brew >/dev/null || { printf 'Homebrew is required; install from https://brew.sh.\n' >&2; exit 1; }
command -v python3 >/dev/null || brew install python
python3 "$SCRIPT_DIR/install-tools.py" --methods "$methods" --dry-run >/dev/null
report_init
trap report_location EXIT
report_optional brew-index brew update
# Brewfile remains authoritative for the selection; catalog supplies fallback recipes.
selection="$(python3 - "$SCRIPT_DIR/.." "$skip_fonts" "$skip_docker" <<'PY'
import json,re,sys
from pathlib import Path
root=Path(sys.argv[1])
packages=set(re.findall(r'^(?:brew|cask) "([^"]+)"', (root/'Brewfile').read_text(),re.M))
if sys.argv[2]=='1': packages.discard('font-fira-code-nerd-font')
if sys.argv[3]=='1': packages -= {'docker','docker-compose','docker-buildx','colima','lazydocker'}
catalog=json.loads((root/'scripts/tool-catalog.json').read_text())
print(','.join(t['name'] for t in catalog if t.get('brew') in packages))
PY
)"
python3 "$SCRIPT_DIR/install-tools.py" --only "$selection" --methods "$methods" --reinstall
if command -v rustup-init >/dev/null 2>&1 && ! rustup show active-toolchain >/dev/null 2>&1; then
  report_optional rust-toolchain rustup-init -y --no-modify-path --default-toolchain stable
fi
if (( ! skip_docker )); then
  mkdir -p "$HOME/.docker/cli-plugins"
  brew_prefix="$(brew --prefix)"
  for plugin in docker-compose docker-buildx; do
    target="$brew_prefix/opt/$plugin/bin/$plugin"
    [[ ! -x "$target" ]] || ln -sfn "$target" "$HOME/.docker/cli-plugins/$plugin"
  done
  if (( start_colima )) && command -v colima >/dev/null; then
    report_optional colima-start colima start --cpu 2 --memory 4 --disk 60
    report_optional colima-service brew services start colima
  fi
fi
printf 'macOS tool installation complete; review optional failures in the report.\n'
