# Workstation installation methods and reports

The workstation bootstrap installs each utility independently. A failed download,
missing compiler, unavailable package or incompatible native library is recorded;
the next method is tried and installation continues for optional tools. Git and
Chezmoi are required to apply configuration; Python 3.9+ runs the installer and
report writer. Install Python through APT/Homebrew first if absent. Bash and the
platform package manager are host prerequisites. The existing server installer
keeps its separate package/pin policy.

```sh
# Existing behavior first: reviewed Linux GitHub assets, native package, source.
./scripts/bootstrap.sh --install-methods github,native,source --skip-docker
# Prefer supported distro packages / Homebrew / npm / official runtime archives.
./scripts/bootstrap.sh --install-methods native,github,source
# GitHub downloads and compilation only, with no APT changes for CLI tools.
./scripts/install-tools.py --methods github,source --skip-packages
# One method or a selected subset.
./scripts/install-tools.py --only fd,rg,jq --methods source
./scripts/install-extra-tools.sh --methods github,native,source
./scripts/update-tools.sh --install-methods github,native,source
# Preview: no downloads, package operations, reports or destination writes.
./scripts/install-tools.py --dry-run --methods github,source
```

`DOTFILES_INSTALL_METHODS` provides the same comma-separated ordered subset.
Duplicates and unknown methods are rejected before installation. Linux defaults
to `github,native,source`; the macOS entrypoint defaults to `native,github,source`.
`--reinstall` forces a selected method even when an executable already works.
`--skip-packages` suppresses APT/Homebrew operations; native npm, Cargo and official
Go/Node distribution downloads remain allowed. Source build prerequisites must
already be available when using this option. `bootstrap.sh` normally provisions
best-effort build prerequisites; using a source-only method order does not by
itself suppress those package operations. Use the standalone CLI with
`--skip-packages` for that purpose.

`scripts/tool-catalog.json` is the per-tool selection and recipe catalog.
`Brewfile` remains the authoritative macOS selection. Linux native packages use
maintained distro versions, so an asset pin is a target for the GitHub/source
paths, not a requirement imposed on APT/Homebrew. Native aliases `fdfind` and
`batcat` are wired to `fd` and `bat`. pnpm and Biome use an isolated npm prefix;
Node and npm are checked independently. Companion tools (`uvx`, `ya`, `npm`,
`npx`, `gofmt`) are retained with their main installation.

## Method availability

- **native:** APT on supported Linux, Homebrew on macOS, npm for pnpm/Biome, PyPI for uv,
  Cargo for applicable published crates, or pinned official Go/Node archives.
  An unavailable package is a failed attempt, not a global abort.
- **github:** reviewed `pinned-assets.sh` URLs/checksums where available.
  Selected additional/platform assets are resolved from the official repository's
  latest release and require its SHA256 asset digest; no digest means a failed
  attempt. URL, digest and version are recorded. Cached files are rehashed.
  GitHub tmux release assets are source tarballs and are compiled locally.
- **source:** shallow HTTPS `git clone` from the catalog's official repository
  at a reviewed release ref, followed by a per-tool Cargo/Go/Make/CMake/etc.
  recipe. The resolved commit and actual version are reported. No upstream
  default branch is silently built. Builds run without sudo and install under
  `~/.local`; replacements are checked before public links are changed.

Some upstreams do not publish compatible GitHub binaries or do not host their
canonical source on GitHub (for example GNU utilities). Rust compiler bootstrap
and complete GUI/service builds are not reproduced by a generic `cargo build`.
Such missing recipes are explicitly reported; native packages remain available.
Go source bootstrapping requires an existing compatible Go compiler. Rust builds
require a compiler meeting upstream MSRV. Cargo/Go/npm/Python dependencies and
Neovim bundled dependencies can require access to registries or other hosts:
cloning from GitHub does not make the full build GitHub-only.

Docker Engine's official Linux APT setup remains an isolated, optional service
step, including its repository and Compose/Buildx plugins. It is never replaced
with an incomplete locally compiled daemon. WSL uses the Windows host engine.
Fonts, shell plugins, TPM, VS Code extensions and explicit editor provisioning
are independent reported bootstrap steps. Linux Ghostty/VS Code and Claude Code
retain their existing manual-install policy.

## Reports and exit behavior

Each execution creates a directory under
`~/.local/state/dotfiles/install-reports/<timestamp>-<unique>/`. Bootstrap and its
child installers share that directory through `DOTFILES_REPORT_DIR`. Standalone
runs get their own directory; `--report-dir PATH` selects one explicitly.

- `report.md`: readable summary and all attempts, including failures preceding
  a successful fallback.
- `report.json`: machine-readable tool status, selected method, observed version,
  source URL/commit, required flag and attempt log paths.
- `<tool>-<method>.log`: commands, download/build/installer output and diagnostics.

Reports are saved atomically after each tool, so a later failure preserves earlier
results. Existing executable versions are reported as `already-present` with
installation origin unknown. If an upgrade fails but an executable still works,
it is `retained`. Other results are `installed`, `failed`, `skipped` or `interrupted`. Auxiliary
bootstrap steps use `completed` when their command succeeds.
A failed optional CLI does not change the final exit code; a missing required
Git/Chezmoi does. The report path is printed even if configuration deployment
fails. Read the report before treating a partial bootstrap as fully provisioned.
`scripts/verify.sh` stays a stricter acceptance check and can fail for missing
optional tools or distro versions differing from pins.

`DOTFILES_INSTALL_TIMEOUT` (default 1800 seconds) bounds each build/installer
command. `DOTFILES_DOWNLOAD_TIMEOUT` (default 180 seconds) bounds each curl
transfer; `DOTFILES_BUILD_JOBS` (default 2) bounds compilation concurrency. A timeout
terminates the command's process group before fallback. Temporary builds are
removed; previous published runtimes remain available for manual rollback.
Logs can contain installer output: inspect them before sharing.

## Agent guidance

`AGENTS.additional.md` and `CLAUDE.additional.md` document efficient, bounded,
non-interactive usage of the modern tools. They are included in the repository
and deployed to the user's home through Chezmoi. Repository `AGENTS.md` and
`CLAUDE.md` reference them so agents working here discover them. To enable them
in another project, explicitly refer to the deployed files from that project's
agent instructions; `.additional.md` filenames are not automatically discovered
by all agent clients. Existing global agent instructions are not overwritten.
