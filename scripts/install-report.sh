#!/usr/bin/env bash
# Shared report lifecycle. Sourced by entrypoints, not an installer itself.
report_init() {
  command -v python3 >/dev/null || { printf 'python3 is required for installation reports.\n' >&2; return 1; }
  if [[ -z "${DOTFILES_REPORT_DIR:-}" ]]; then
    DOTFILES_REPORT_DIR="$(python3 "$SCRIPT_DIR/install-tools.py" --new-report)" || return 1
    export DOTFILES_REPORT_DIR
  fi
}
report_optional() {
  local component="$1"
  shift
  printf '==> %s\n' "$component"
  if python3 "$SCRIPT_DIR/install-tools.py" --step "$component" -- "$@"; then return 0; fi
  printf 'Warning: %s failed; continuing. See %s/report.md\n' "$component" "$DOTFILES_REPORT_DIR" >&2
  return 0
}
report_location() {
  [[ -z "${DOTFILES_REPORT_DIR:-}" ]] || printf 'Installation report: %s/report.md\nJSON report: %s/report.json\n' "$DOTFILES_REPORT_DIR" "$DOTFILES_REPORT_DIR"
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in -h|--help) printf 'Shared installation reporting functions; source from an installer.\n';; *) exit 2;; esac
fi

validate_install_methods() {
  local methods="$1" method seen=,
  local -a values=()
  [[ "$methods" =~ ^(native|github|source)(,(native|github|source))*$ ]] || { printf 'Invalid installation methods: %s\n' "$methods" >&2; return 2; }
  IFS=, read -ra values <<< "$methods"
  for method in "${values[@]}"; do
    [[ "$seen" != *",$method,"* ]] || { printf 'Duplicate installation method: %s\n' "$method" >&2; return 2; }
    seen+="$method,"
  done
}
