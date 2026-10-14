#!/usr/bin/env bash
# Select tools and channels once, install once, then apply the configuration.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/profile.sh
. "$SCRIPT_DIR/profile.sh"
# shellcheck source=scripts/preflight.sh
. "$SCRIPT_DIR/preflight.sh"
# shellcheck source=scripts/install-report.sh
. "$SCRIPT_DIR/install-report.sh"

usage() {
  cat <<USAGE
Usage: $0 [--tools recommended|all|none|LIST] [--install-methods native,github,source]
  --interactive           open the tool and fallback picker
  --list-tools            show the catalog and usefulness categories
  --custom-tools FILE     descriptions for your custom Go/Rust/user binaries
  --dry-run               preview without changing the host
  --yes                   use saved/default choices without confirmation
  --profile workstation|server
Server only: --setup-editor, --editor-languages LIST, --system-baseline
Run as your regular user. Native Linux packages request sudo before installation.
Plugins, extensions, shell changes and service starts are explicit standalone setup.
USAGE
}
profile="" tools="" custom_tools="" dry_run=0 interactive=0 list_tools=0 assume_yes=0
setup_editor=0 editor_languages="" system_baseline=0
while (( $# )); do
  case "$1" in
    --profile|--tools|--install-methods|--custom-tools|--editor-languages)
      [[ $# -ge 2 ]] || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
      case "$1" in
        --profile) profile="$2";;
        --tools) tools="$2";;
        --install-methods) export DOTFILES_INSTALL_METHODS="$2";;
        --custom-tools) custom_tools="$2";;
        --editor-languages) editor_languages="$2"; setup_editor=1;;
      esac
      shift;;
    --interactive) interactive=1;;
    --list-tools) list_tools=1;;
    --dry-run) dry_run=1;;
    -y|--yes) assume_yes=1;;
    --setup-editor) setup_editor=1;;
    --system-baseline) system_baseline=1;;
    -h|--help) usage; exit 0;;
    *) printf 'Unknown option: %s. See --help; choose optional tools in the picker.\n' "$1" >&2; exit 2;;
  esac
  shift
done
(( ! list_tools )) || { python3 "$SCRIPT_DIR/select-tools.py" --list; exit; }
profile="$(dotfiles_profile "$profile")" || { printf 'Unknown profile\n' >&2; exit 2; }
export DOTFILES_PROFILE="$profile"
case "$(uname -s)" in
  Linux) preflight_linux "$profile" "$dry_run";;
  Darwin) [[ "$profile" == workstation ]] || { printf 'Server profile requires Linux\n' >&2; exit 2; };;
  *) printf 'Unsupported platform\n' >&2; exit 2;;
esac
(( EUID != 0 || dry_run )) || { printf 'Run bootstrap as your regular user, without sudo.\n' >&2; exit 2; }
if [[ "$profile" == workstation ]]; then
  (( setup_editor == 0 && system_baseline == 0 )) || { printf 'Use scripts/setup-editor.sh or scripts/server-baseline.sh for explicit setup.\n' >&2; exit 2; }
else
  [[ -z "$tools" && "$interactive" == 0 ]] || { printf 'Tool selection is for workstations.\n' >&2; exit 2; }
fi
if [[ "$profile" == server ]]; then
  if grep -qi microsoft /proc/sys/kernel/osrelease; then printf 'Server profile cannot run under WSL.\n' >&2; exit 2; fi
  if [[ -n "$editor_languages" ]]; then
    # shellcheck source=scripts/server-packages.sh
    . "$SCRIPT_DIR/server-packages.sh"
    IFS=, read -ra languages <<< "$editor_languages"
    dotfiles_server_editor_packages "${languages[@]}" >/dev/null
  fi
  (( ! system_baseline )) || bash "$SCRIPT_DIR/server-baseline.sh" --dry-run
fi
# Python runs selection, installation, monitoring and reports; it must exist first.
command -v python3 >/dev/null || { printf 'Python 3 is required. Install it first: sudo apt-get install python3 (Linux), or brew install python (macOS).\n' >&2; exit 1; }
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else "Python 3.11 or newer is required.")'
if [[ "$profile" == workstation ]]; then
  selection_args=()
  [[ -z "$tools" ]] || selection_args+=(--tools "$tools")
  [[ -z "${DOTFILES_INSTALL_METHODS:-}" ]] || selection_args+=(--methods "$DOTFILES_INSTALL_METHODS")
  if (( interactive )) || { [[ -t 0 && -z "$tools" ]] && (( ! assume_yes && ! dry_run )); }; then selection_args+=(--interactive); fi
  resolve_tool_selection ${selection_args[@]+"${selection_args[@]}"}
  printf 'Selected tools: %s\nInstallation order: %s\n' "$DOTFILES_TOOLS" "$DOTFILES_INSTALL_METHODS"
  install_args=(--only "$DOTFILES_TOOLS" --methods "$DOTFILES_INSTALL_METHODS")
else
  install_args=()
  (( ! setup_editor )) || install_args+=(--setup-editor)
  [[ -z "$editor_languages" ]] || install_args+=(--editor-languages "$editor_languages")
fi
if (( dry_run )); then
  if [[ "$profile" == workstation ]]; then python3 "$SCRIPT_DIR/install-tools.py" "${install_args[@]}" --dry-run;
  else
    printf 'would run: scripts/install-server.sh'; printf ' %q' ${install_args[@]+"${install_args[@]}"}; printf '\n'
  fi
  printf 'would apply Chezmoi source and generate installed-tool guides\n'
  exit 0
fi
if (( ! assume_yes )); then
  printf 'Continue with this plan? [y/N]: '
  read -r answer
  [[ "$answer" == y || "$answer" == Y ]] || exit 0
fi
export PATH="${LOCAL_BIN:-$HOME/.local/bin}:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
report_init
finish() {
  local status=$?
  (( status == 0 )) || printf 'Bootstrap stopped (exit %s). See the report and last command above.\n' "$status" >&2
  report_location
  return "$status"
}
trap finish EXIT
if [[ "$profile" == workstation ]]; then
  resolve_tool_selection --tools "$DOTFILES_TOOLS" --methods "$DOTFILES_INSTALL_METHODS" --save
  python3 "$SCRIPT_DIR/install-tools.py" "${install_args[@]}"
else
  # Server provisioning keeps its independent package manifest and reviewed pins.
  # Authenticate before the runner disconnects child stdin; sudo inside is noninteractive.
  python3 -c 'import subprocess; subprocess.run(["sudo", "-v"], timeout=120, check=True)'
  python3 "$SCRIPT_DIR/install-tools.py" --step server-tools -- bash "$SCRIPT_DIR/install-server.sh" ${install_args[@]+"${install_args[@]}"}
  (( ! system_baseline )) || python3 "$SCRIPT_DIR/install-tools.py" --step server-baseline -- bash "$SCRIPT_DIR/server-baseline.sh" --apply
fi
python3 "$SCRIPT_DIR/install-tools.py" --step apply-dotfiles -- bash "$SCRIPT_DIR/apply-dotfiles.sh" --profile "$profile" --force
guide_args=()
[[ -z "$custom_tools" ]] || guide_args+=(--custom-tools "$custom_tools")
report_optional agent-guides python3 "$SCRIPT_DIR/generate-agent-guides.py" ${guide_args[@]+"${guide_args[@]}"}
printf 'Done. Open a new terminal, then run scripts/verify.sh --profile %s\n' "$profile"
