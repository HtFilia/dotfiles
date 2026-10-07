# Tool versions and updates

```sh
just tools-update --dry-run
just tools-update --skip-packages
just verify
```

Corporate updates provision checked-in GitHub pins, preserve Docker/editor
selections and use only existing authorized APT sources. `--skip-packages` performs
no apt/sudo action. Whole-system upgrades belong to IT. There is no rustup update,
vendor runtime download, implicit uv interpreter install or crates.io build.

Change release URLs/checksums in `scripts/pinned-assets.sh`, regenerate the asset
inventory with `just assets`, and verify executables before committing. Distro
versions are recorded in `~/.local/state/dotfiles/apt-runtimes.tsv`; editor versions
come from reviewed host manifests. Standalone replacements preserve `.previous`;
runtime/editor prefixes remain available for launcher rollback. Configuration
updates snapshot before fast-forward pull and apply.

See [CORPORATE.md](CORPORATE.md) for source provenance, recovery and merge workflow.
Corporate network/runtime acceptance remains tracked in [AGENTS.md](../AGENTS.md).
The retained sd v1.1.0 release reports 1.0.0; verification checks both that reported
version and the reviewed executable hash, preserving the original special case.
