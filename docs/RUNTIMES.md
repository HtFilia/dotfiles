# Runtimes and project environments

Machine defaults come from Homebrew on macOS and apt/verified direct downloads
on Linux. Project-specific requirements belong in version-controlled project
files. This separation avoids installing every project's versions globally.

| Runtime | Machine source | Project control |
|---|---|---|
| Python | Homebrew/apt; uv available | `pyproject.toml`, `uv.lock`, `.python-version` |
| Node | Homebrew Node 24/pinned Linux Node 24 | mise version and package-manager lockfile |
| Go | Homebrew/pinned Linux Go | `go.mod`, optional mise version |
| Rust | Homebrew rustup/apt compiler | `rust-toolchain.toml`, Cargo.lock |

mise is available on workstations and activated in Zsh. It does not silently
replace machine defaults without configuration. Example project `mise.toml`:

```toml
[tools]
node = "24.21.0"
```

Trust project configuration only after reviewing it. Use explicit versions for
shared projects; let their CI install those versions too.

## Python

`uv init`, `uv add`, `uv sync`, and `uv run` cover normal project work. `uv run`
uses project dependencies without manual activation. `uvx` invokes isolated CLI
tools; it is a distinct executable supplied alongside uv. Global Python tools
can be installed with `uv tool install` when that is useful.

```sh
uv python install 3.14
uv python pin 3.14
uv add --dev pytest ruff
uv run pytest
```

Keep `.python-version` and lockfiles tracked when they describe project intent.
`activate` is a convenience for an existing virtual environment, not a version
manager. direnv loads approved per-project environments and releases them when
you leave; read `.envrc` before approving it.

## Node, Go and Rust

pnpm is supplied by Homebrew or enabled through available Corepack on Linux.
If Corepack is absent, install your chosen package manager explicitly using the
project's required version. Node installation does not select an unrequested
package manager for every project.

Go binaries installed by `go install` use GOPATH/GOBIN, which remain overrideable.
Linux rustfmt and Clippy come from distro packages; rustup toolchains need their
corresponding components. `rustup override set` stores a local override;
version-controlled `rust-toolchain.toml` is the portable project declaration.

Linux tokei uses a versioned, locked Cargo build only with Rust >=1.85; otherwise
it is skipped as optional. watchexec is already installed for file watching:
`watchexec -e rs -- cargo test` avoids another Cargo watcher dependency.
