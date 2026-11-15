#!/usr/bin/env bash
# Neovim attaches the language servers this machine installs to a file of
# each language. Runs on an installed machine, after the plugins are present.
set -euo pipefail
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
answers="$(chezmoi execute-template '{{ includeTemplate "osid" . }} {{ .profile }} {{ .context }}')"
read -r osid profile context <<<"$answers"
failures=0

# attached FILE: names of the language servers attached to FILE, sorted.
attached() {
  (cd "$work" && nvim --headless "$1" \
    '+lua vim.wait(20000, function() return #vim.lsp.get_clients({ bufnr = 0 }) >= tonumber(vim.env.EXPECTED) end, 200)' \
    '+lua local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 })); table.sort(names); io.write(table.concat(names, ","))' \
    +qa 2>&1)
}
check() {
  local file="$1" expected="$2" actual
  actual="$(EXPECTED="$(tr -cd ',' <<<"$expected," | wc -c)" attached "$file")"
  if [[ "$actual" == "$expected" ]]; then
    printf 'ok - %s: %s\n' "$file" "$expected"
  else
    printf 'FAIL - %s: expected %s, got %s\n' "$file" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

printf 'count: int = 1\n' >"$work/sample.py"
printf '#!/usr/bin/env bash\necho hello\n' >"$work/sample.sh"
check sample.py pyrefly,ruff
check sample.sh bashls
if [[ "$profile" == workstation ]]; then
  printf 'const count: number = 1;\n' >"$work/sample.ts"
  mkdir -p "$work/src"
  printf '[package]\nname = "sample"\nversion = "0.1.0"\nedition = "2021"\n' >"$work/Cargo.toml"
  printf 'fn main() {}\n' >"$work/src/main.rs"
  check sample.ts ts_ls
  check src/main.rs rust_analyzer
fi
if [[ "$osid" == fedora && "$context" == perso ]]; then
  printf 'int main() { return 0; }\n' >"$work/sample.cpp"
  check sample.cpp clangd
fi
((failures == 0))
