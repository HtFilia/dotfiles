set shell := ["bash", "-uc"]

check:
    for file in scripts/*.sh tests/*.sh; do bash -n "$file"; done
    for file in home/dot_zsh*; do zsh -n "$file"; done
    shellcheck scripts/*.sh
    bash tests/script-contracts.sh

dry-run:
    tmp_dir="$(mktemp -d)"; trap 'rm -rf "$tmp_dir"' EXIT; ./scripts/apply-dotfiles.sh --dry-run --destination "$tmp_dir"

verify:
    ./scripts/verify.sh

audit: check dry-run verify
