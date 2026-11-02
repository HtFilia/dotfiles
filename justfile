set shell := ["bash", "-uc"]

check:
    for file in scripts/*.sh tests/*.sh; do bash -n "$file"; done
    for file in home/dot_zsh*; do zsh -n "$file"; done
    shellcheck scripts/*.sh tests/*.sh
    bash tests/script-contracts.sh

diff:
    chezmoi diff

verify:
    ./scripts/verify.sh

audit: check diff verify

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
    chezmoi update

# Upgrade packages and managed user tools; --skip-packages avoids sudo.
tools-update *options:
    ./scripts/update-tools.sh {{options}}
