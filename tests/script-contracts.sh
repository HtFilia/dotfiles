#!/usr/bin/env bash
# Lightweight contract tests for the public dotfiles CLI.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

pass() {
  printf 'ok - %s\n' "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  failures=$((failures + 1))
}

contains() {
  local haystack="$1" needle="$2" name="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$name"
  else
    fail "$name"
  fi
}

not_contains() {
  local haystack="$1" needle="$2" name="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    fail "$name"
  else
    pass "$name"
  fi
}

run_script() {
  (cd "$ROOT" && "$@")
}

test_bootstrap_no_restricted_public_contract() {
  local help
  help="$(run_script ./scripts/bootstrap.sh --help)"
  not_contains "$help" "restricted" "bootstrap help does not expose restricted mode"
  not_contains "$help" "--enable-backports" "bootstrap help does not expose backports mode"

  if run_script ./scripts/bootstrap.sh --restricted --help >/tmp/dotfiles-bootstrap-restricted.out 2>&1; then
    fail "bootstrap rejects --restricted"
  else
    pass "bootstrap rejects --restricted"
  fi
}

test_apply_dotfiles_uses_chezmoi_contract() {
  local help tmp_home
  help="$(run_script ./scripts/apply-dotfiles.sh --help)"
  not_contains "$help" "full|restricted" "apply help does not expose full/restricted modes"
  contains "$help" "--destination PATH" "apply help exposes isolated destination"

  tmp_home="$(mktemp -d)"
  if run_script ./scripts/apply-dotfiles.sh --dry-run --destination "$tmp_home" >/tmp/dotfiles-apply-dry-run.out 2>&1; then
    pass "apply dry-run supports isolated destination"
  else
    fail "apply dry-run supports isolated destination"
    sed -n '1,80p' /tmp/dotfiles-apply-dry-run.out >&2 || true
  fi
  rm -rf "$tmp_home"
}

test_single_neovim_profile_contract() {
  [[ -d "$ROOT/home/dot_config/nvim" ]] && pass "single nvim source exists" || fail "single nvim source exists"
  [[ ! -e "$ROOT/home/dot_config/nvim-lazyvim" ]] && pass "legacy nvim-lazyvim source removed" || fail "legacy nvim-lazyvim source removed"
  [[ ! -e "$ROOT/home/dot_config/nvim-restricted" ]] && pass "legacy nvim-restricted source removed" || fail "legacy nvim-restricted source removed"
}

test_docs_no_restricted_contract() {
  if {
    grep -In "restricted" "$ROOT/README.md"
    find "$ROOT/docs" -path "$ROOT/docs/superpowers" -prune -o -type f -name '*.md' -print0 |
      xargs -0 grep -In "restricted"
  } >/tmp/dotfiles-restricted-docs.out 2>&1; then
    fail "public docs do not mention restricted mode"
    sed -n '1,40p' /tmp/dotfiles-restricted-docs.out >&2 || true
  else
    pass "public docs do not mention restricted mode"
  fi
}

test_gruvbox_material_theme_contract() {
  contains "$(cat "$ROOT/extensions.txt")" "sainnhe.gruvbox-material" "VS Code Gruvbox Material extension is installed"
  not_contains "$(cat "$ROOT/extensions.txt")" "enkia.tokyo-night" "VS Code Tokyo Night extension is removed"

  contains "$(cat "$ROOT/home/dot_config/Code/User/settings.json")" '"workbench.colorTheme": "Gruvbox Material Dark"' "VS Code uses Gruvbox Material Dark"
  contains "$(cat "$ROOT/home/dot_config/Code/User/settings.json")" '"gruvboxMaterial.darkContrast": "medium"' "VS Code uses medium Gruvbox contrast"
  contains "$(cat "$ROOT/home/dot_config/Code/User/settings.json")" '"gruvboxMaterial.darkPalette": "material"' "VS Code uses material Gruvbox palette"
  contains "$(cat "$ROOT/home/dot_config/Code/User/settings.json")" '"gruvboxMaterial.darkWorkbench": "material"' "VS Code uses material Gruvbox workbench"

  contains "$(cat "$ROOT/home/dot_zshrc")" 'BAT_THEME="gruvbox-dark"' "shell uses gruvbox-dark for bat"
  contains "$(cat "$ROOT/home/dot_gitconfig")" 'syntax-theme = "gruvbox-dark"' "git delta uses gruvbox-dark"
  contains "$(cat "$ROOT/scripts/verify.sh")" 'check_bat_theme "gruvbox-dark"' "verify checks gruvbox-dark"

  if grep -RInE "Tokyo Night|tokyonight" "$ROOT/home" "$ROOT/extensions.txt" "$ROOT/scripts/verify.sh" >/tmp/dotfiles-tokyo-night.out 2>&1; then
    fail "managed configs do not reference Tokyo Night"
    sed -n '1,40p' /tmp/dotfiles-tokyo-night.out >&2 || true
  else
    pass "managed configs do not reference Tokyo Night"
  fi
}

test_justfile_contract() {
  [[ -f "$ROOT/justfile" ]] && pass "justfile exists" || fail "justfile exists"
  if [[ -f "$ROOT/justfile" ]]; then
    contains "$(cat "$ROOT/justfile")" $'\ncheck:' "justfile exposes check recipe"
    contains "$(cat "$ROOT/justfile")" $'\nverify:' "justfile exposes verify recipe"
    contains "$(cat "$ROOT/justfile")" $'\ndry-run:' "justfile exposes dry-run recipe"
    contains "$(cat "$ROOT/justfile")" $'\naudit:' "justfile exposes audit recipe"
  fi
}

main() {
  test_bootstrap_no_restricted_public_contract
  test_apply_dotfiles_uses_chezmoi_contract
  test_single_neovim_profile_contract
  test_docs_no_restricted_contract
  test_gruvbox_material_theme_contract
  test_justfile_contract

  if (( failures > 0 )); then
    printf '\n%d contract test(s) failed.\n' "$failures" >&2
    exit 1
  fi
}

main "$@"
