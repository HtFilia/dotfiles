set shell := ["bash", "-uc"]

check:
    bash -n scripts/*.sh
    zsh -n home/dot_zshrc
    shellcheck scripts/*.sh
    bash tests/script-contracts.sh

dry-run:
    tmp_dir="$(mktemp -d)"; trap 'rm -rf "$tmp_dir"' EXIT; ./scripts/apply-dotfiles.sh --dry-run --destination "$tmp_dir"

verify:
    ./scripts/verify.sh

audit: check dry-run verify
