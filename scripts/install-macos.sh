#!/usr/bin/env bash
# Homebrew-native workstation installation, with independent CLI fallbacks.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install-report.sh
. "$SCRIPT_DIR/install-report.sh"
start_colima=0 skip_fonts=0 skip_docker=0
methods="${DOTFILES_INSTALL_METHODS:-}"
tools="${DOTFILES_TOOLS:-}"
while (( $# )); do
  case "$1" in
    --start-colima) start_colima=1 ;;
    --skip-fonts) skip_fonts=1 ;;
    --skip-docker) skip_docker=1 ;;
    --methods) [[ $# -ge 2 ]] || exit 2; methods="$2"; shift ;;
    --tools) [[ $# -ge 2 ]] || exit 2; tools="$2"; shift ;;
    -h|--help) printf 'Usage: %s [--tools recommended|all|LIST] [--methods native,github] [--start-colima] [--skip-fonts] [--skip-docker]\n' "$0"; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
[[ -z "$methods" ]] || validate_install_methods "$methods"
if ! command -v python3 >/dev/null; then
  [[ ",${methods:-native}," == *,native,* ]] || { printf 'Python is required when native installs are disabled.\n' >&2; exit 1; }
  brew install python
fi
selection_args=()
[[ -z "$tools" ]] || selection_args+=(--tools "$tools")
[[ -z "$methods" ]] || selection_args+=(--methods "$methods")
selection_exclusions=()
(( ! skip_fonts )) || selection_exclusions+=(font-fira-code-nerd-font)
(( ! skip_docker )) || selection_exclusions+=(docker docker-compose docker-buildx colima lazydocker)
if (( ${#selection_exclusions[@]} )); then selection_args+=(--exclude "$(IFS=,; printf '%s' "${selection_exclusions[*]}")"); fi
resolve_tool_selection ${selection_args[@]+"${selection_args[@]}"} --save
methods="$DOTFILES_INSTALL_METHODS"
if ! tool_selected docker; then skip_docker=1; fi
if [[ ",$methods," == *,source,* ]] && ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  printf 'Finish Command Line Tools installation, then rerun.\n'
  exit 2
fi
report_init
trap report_location EXIT
if [[ ",$methods," == *,native,* ]]; then report_optional brew-index brew update; fi
args=(--only "$DOTFILES_TOOLS" --methods "$methods" --reinstall)
exclusions=()
(( ! skip_fonts )) || exclusions+=(font-fira-code-nerd-font)
(( ! skip_docker )) || exclusions+=(docker docker-compose docker-buildx colima lazydocker)
if (( ${#exclusions[@]} )); then args+=(--exclude "$(IFS=,; printf '%s' "${exclusions[*]}")"); fi
python3 "$SCRIPT_DIR/install-tools.py" "${args[@]}"
if [[ ",$methods," == *,native,* ]] && tool_selected rustup && command -v rustup-init >/dev/null 2>&1 && ! rustup show active-toolchain >/dev/null 2>&1; then
  report_optional rust-toolchain rustup-init -y --no-modify-path --default-toolchain stable
fi
if (( ! skip_docker )) && [[ ",$methods," == *,native,* ]] && command -v brew >/dev/null; then
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
