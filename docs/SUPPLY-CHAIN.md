# Supply chain and reproducibility

## Platform packages

Homebrew and apt provide their native trust/update mechanisms. Brewfile and
Linux installer lists declare package intent, not a complete version lock.
Supported distributions supply maintained base tools; direct assets fill gaps.
macOS/Linux package versions can differ without indicating a broken installation.

## Direct assets

`scripts/pinned-assets.sh` records exact versions, HTTPS URLs, filenames and
SHA256 hashes. Downloads use temporary files and hashes are checked before
installation/extraction. Cache paths include asset and version; a stale or corrupt
cache is replaced only by a newly verified download. Hashes authenticate against
the reviewed manifest, not independently against the publisher's signing key.

[`ASSET-MANIFEST.md`](ASSET-MANIFEST.md) is generated with `just assets`. Edit the
shell manifest, not the generated table. Cargo's optional tokei build uses an
exact version and `--locked`, with crates.io's dependency integrity mechanisms.

## Executed plugins and editor tools

Zsh/TPM checkouts have exact commits and installers reject dirty checkouts and
propagate Git errors. Zsh checks ownership and directory permissions before
sourcing plugin entrypoints. Neovim pins its manager/distribution/theme and locks
its plugin graph; missing plugins may be downloaded on first launch, and plugin
build hooks execute upstream code. lazy.nvim drift is explicitly rejected.

Mason's registry and language packages are another download/execution boundary.
Only explicit editor setup requests tools/parsers. Existing packages remain until
an intentional update; their releases are not covered by the direct-asset manifest.
VS Code extensions update through VS Code and may access external services.
Do not confuse a plugin lock with a complete operating-system/environment lock.

## Vendored terminfo

`assets/terminfo/xterm-ghostty.terminfo` contains Ghostty v1.3.1 capabilities from
commit `332b2aefc6e72d363aa93ab6ecfc86eeeeb5ed28`, upstream
`src/terminfo/ghostty.zig`, with its upstream license. Server installation compiles
it locally with `tic` and needs no terminfo downloader. Its SHA256 is
`325413188d4aa06cbe8ab3a714cdd7264f506094db5ed50e14316f3a95601b78`.

## Update procedure

Obtain metadata from the publisher, review the version/URL/hash changes together,
regenerate inventory, run `just check`, `just dry-run`, `just workflow` and
`just security` when their tools are installed. Exercise changed assets on a
disposable supported host. Keep snapshots/revisions for rollback. Personal secret
files, accounts and SSH keys belong outside tracked source.
