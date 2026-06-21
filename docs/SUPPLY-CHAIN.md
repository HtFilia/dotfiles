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

Installers refuse to install, copy, or extract cached and downloaded files when
the checksum does not match.

## Language package managers

Cargo is used only where a tool does not publish a suitable Linux binary asset.
At the moment this applies to `tokei`, installed with an explicit version and
`--locked` so Cargo verifies the crate dependency graph from crates.io metadata.

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
just check
just dry-run
just verify
```
