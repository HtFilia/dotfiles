# Supply Chain Model

This repository has three trust boundaries.

## Platform package managers

Homebrew and apt are trusted through their native repository and signing
mechanisms. macOS package intent is declared in the root `Brewfile`; Linux
package intent lives in `scripts/install-debian.sh`.

## Direct downloads

Direct downloads are used only when the platform package manager is not a good
fit for the expected developer experience. Each asset is pinned by exact URL,
filename, version, and SHA256 in `scripts/pinned-assets.sh`.

Installers refuse to extract cached or downloaded files when the checksum does
not match.

## Git-based plugins

Zsh plugins and tmux TPM are cloned from GitHub and checked out to exact
commits listed in `scripts/pinned-plugins.sh`.

Shell startup is defensive: plugin files are sourced only when they are under
the expected plugin directory, owned by the current user, and not group/world
writable.

## Manual installers

Some tools publish shell installers. This repository does not run those
installers automatically. Tools such as AI assistants can be installed manually
from their official channels when the user accepts their trust model.

## Update checklist

```bash
bash -n scripts/*.sh
shellcheck scripts/*.sh
bash tests/script-contracts.sh
./scripts/apply-dotfiles.sh --dry-run --destination "$(mktemp -d)"
./scripts/verify.sh
```
