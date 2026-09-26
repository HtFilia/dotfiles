#!/usr/bin/env bash
# Shared profile resolution for bootstrap, updates, apply, and verification.
dotfiles_profile() {
  local explicit="${1:-}" state="${2:-$HOME/.local/state/dotfiles/profile}" selected
  selected="$explicit"
  [[ -n "$selected" ]] || selected="${DOTFILES_PROFILE:-}"
  if [[ -z "$selected" && -f "$state" ]]; then
    IFS= read -r selected < "$state" || true
  fi
  selected="${selected:-workstation}"
  case "$selected" in workstation|server) printf '%s\n' "$selected" ;; *) printf 'Invalid dotfiles profile: %s\n' "$selected" >&2; return 1 ;; esac
}
