# Runtimes and project environments

Corporate Node/npm, Go and Rust come from existing authorized APT sources, with
user launchers explicitly pointing to `/usr/bin`. Their distro versions can differ
from `master`; project compatibility is AGENTS.md C05. pnpm and Biome use pinned
GitHub binaries. System Python stays APT-owned. Explicit `scripts/setup-python.sh`
installs the pinned GitHub CPython 3.14.7 build as `python3.14` when C14 is accepted.

Project lockfiles remain authoritative. Internal npm/Python registry settings live
in host-owned `~/.config/dotfiles/corporate.env` and native package-manager config.
Unset registries fail closed. See [CORPORATE.md](CORPORATE.md) for credentials,
trust settings and editor package closures.

uv remains available with interpreter downloads disabled. For an already supplied
interpreter, use `uv venv --python /path/to/python`. mise retains project activation
with automatic installation disabled. Old rustup shell initialization is omitted.
Cargo defaults to offline and Go to local toolchains with no module proxy; C12 must
establish authorized project dependency acquisition before enabling online builds.
No public registry or direct Go fallback is assumed.

direnv, `.python-version`, `pyproject.toml`, `uv.lock`, `go.mod`, Cargo.lock and
reviewed project configuration keep their normal roles. Runtime constraints must
be met through an authorized source; they are not silently overridden by bootstrap.
