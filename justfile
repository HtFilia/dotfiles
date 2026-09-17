set shell := ["bash", "-uc"]

check:
    for file in scripts/*.sh tests/*.sh; do bash -n "$file"; done
    for file in home/dot_zsh*; do zsh -n "$file"; done
    shellcheck scripts/*.sh tests/*.sh
    bash tests/script-contracts.sh

dry-run:
    tmp_dir="$(mktemp -d)"; trap 'rm -rf "$tmp_dir"' EXIT; ./scripts/apply-dotfiles.sh --dry-run --destination "$tmp_dir"

verify:
    ./scripts/verify.sh

audit: check dry-run verify

# These checks use already-installed tools and do not install dependencies.
security:
    gitleaks git --redact --no-banner

workflow:
    actionlint

assets:
    ./scripts/asset-manifest.sh > docs/ASSET-MANIFEST.md

editor *languages:
    ./scripts/setup-editor.sh {{languages}}

update:
    ./scripts/update-dotfiles.sh

# Upgrade packages and managed user tools; --skip-packages avoids sudo.
tools-update *options:
    ./scripts/update-tools.sh {{options}}

lab *options:
    python3 home/dot_local/share/dotfiles/workbooks/lab.py {{options}}
