# Runtimes and project environments

Each machine gets one default version of a runtime from its package manager.
Projects that need a specific version declare it in version-controlled files.

| Runtime | Fedora | Debian 13 | macOS | Project control |
|---|---|---|---|---|
| Python | system `python3`, uv | `python3`; uv on the work workstation | uv | `pyproject.toml`, `uv.lock`, `.python-version` |
| Node | `nodejs24` | `nodejs` 20 and `npm` | `node` | lockfile, `engines`, `packageManager` |
| Go | `golang` | not installed | `go` | `go.mod`, including its `toolchain` line |
| Rust | rustup, stable toolchain | rustup, stable toolchain (work workstation) | rustup, stable toolchain | `rust-toolchain.toml`, `Cargo.lock` |

## Python

`uv init`, `uv add`, `uv sync` and `uv run` cover project work; `uv run` uses
the project's environment without activation. uv also installs Python
versions, so a project can use a version the system does not ship:

```sh
uv python pin 3.14
uv add --dev pytest ruff
uv run pytest
```

`uvx` runs a command-line tool in a throwaway environment, and `uv tool
install` keeps one. `activate` enters an existing `.venv` or `venv`. direnv
loads an approved `.envrc` when you enter a project; read it before
`direnv allow`.

## Rust

On the first `chezmoi apply` of a workstation, a run-once script asks rustup
for the stable toolchain, with rustfmt and Clippy. `rustup update` upgrades
it; a project's `rust-toolchain.toml` selects another version when you build
there.

## Node and Go

Node comes with npm everywhere. Respect each project's package manager and
lockfile; use `npx` or `corepack` rather than global installs. Go reads the
`toolchain` line of `go.mod` and downloads that version when it is newer than
the installed one. Binaries from `go install` land in `$GOBIN` (default
`~/go/bin`), which is on PATH.
