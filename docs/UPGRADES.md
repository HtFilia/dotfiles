# Tool versions and updates

Standalone release pins were reviewed on **2026-09-16**. Use:

```sh
just tools-update
just tools-update --skip-packages  # system packages already handled; no apt/sudo
just verify
```

`just update` continues to update configuration only. `just tools-update` updates
the supported OS packages and provisions the versions recorded in this checkout.
It does not silently rewrite pins to whatever upstream publishes next week.
Review newer versions and checksums in `scripts/pinned-assets.sh`, regenerate
`docs/ASSET-MANIFEST.md` with `just assets`, and test before committing changes.

On Linux, direct binary tools install under `~/.local/bin`. Replacement is atomic
and replaces existing symlinks rather than overwriting their targets in `/usr`.
Tmux builds from its pinned release using a compiler, libevent, ncurses and byacc.
`scripts/extra-tools.tsv` declares additional executables and archive members.
Debian/Ubuntu packages follow the latest available versions in the configured
supported distribution repositories; they are not all the latest upstream source
releases. This deliberately preserves distro ownership of system components.

macOS runs `brew update` and `brew bundle install`, allowing upgrades even when
all declared tools were already installed. Homebrew formula/cask versions follow
Homebrew. Windows host application updates are separate from WSL package updates.

The current runtime selections are Node 26.9.0, Go 1.27.1, managed Python 3.14.7,
pnpm 12.4.2 and Biome 2.5.14. Existing rustup installations update their stable
toolchain; project `rust-toolchain.toml` overrides still win. Python is installed
with uv under the user account; `/usr/bin/python3` remains owned by the distro.
Node moves from the previous Node 24 baseline to current stable Node 26. Projects
requiring Node 24 should declare that version with mise. Lockfiles are not rewritten.

pnpm is installed explicitly into the versioned Node prefix, rather than leaving
an unhydrated Corepack shim. Python project packages and arbitrary third-party
global tools are not mass-upgraded; their project lockfiles remain authoritative.

New direct assets use publisher GitHub release SHA256 digests where available.
jless 0.9.0 has no publisher digest in its release metadata; its recorded checksum
was computed from the official HTTPS release artifact during this review. That
provides repeatable integrity against this reviewed manifest, not an independent
publisher signature. All downloads are checked against their recorded hashes.

After a bat upgrade, rebuild user syntax caches with `bat cache --build` if needed.
After a tealdeer installation, explicitly run `tldr --update` to populate examples.
Restart shells to discard cached executable paths. Existing tmux servers can keep
running their old executable until their sessions finish; the cockpit uses its own
socket, avoiding disruption to existing sessions.

## The sd release label

The official sd v1.1.0 release still reports `sd 1.0.0` because its workspace
metadata retains that package version. Verification therefore checks the expected
reported string and the SHA256 of the binary extracted from the v1.1.0 archive.
It does not accept an arbitrary old sd 1.0.0 binary.
