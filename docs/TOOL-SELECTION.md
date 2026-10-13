# Runtime tool selection and generated agent guides

Run `./scripts/bootstrap.sh` in a terminal. The workstation picker shows the
13-entry recommended set first; optional tools stay behind `list`. Choose the
current selection, a preset, individual names or menu numbers. `recommended,+gh,-fzf`
extends the preset while removing an optional tool. Four deployment prerequisites
remain selected. Selecting `none` means only those prerequisites, not an empty host.

After tool selection choose the first installation method, then independently
allow or deny native, GitHub release artifact and source-clone/build fallbacks.
The displayed order is the exact order applied to each selected utility. The
new-host default is `native,github`; local source builds are opt-in. A source build
still clones a GitHub repository and can need other registries for dependencies.

The [tool audit](TOOL-AUDIT.md) explains each catalog entry and the recommendation.
Only bootstrap prerequisites are universal. Compiler stacks, editors, package
managers, specialist interfaces and visual helpers are optional. Existing tools
are never automatically removed. Tools deselected here may still be available
because they were installed previously or by another workflow.

```sh
# Open the picker explicitly (also useful after an earlier installation).
./scripts/bootstrap.sh --interactive
# List the complete platform-filtered catalog without installation.
./scripts/bootstrap.sh --list-tools
# Unattended recommended set, GitHub artifacts only after prerequisites exist.
./scripts/bootstrap.sh --tools recommended --install-methods github --yes
# Unattended selected tools with no GitHub or source fallback.
./scripts/bootstrap.sh --tools rg,fd,jq,uv --install-methods native --yes
# Preview a small selection without installing or saving preferences.
./scripts/bootstrap.sh --tools rg,jq --install-methods native,github --dry-run
```

A terminal opens the picker automatically when `--tools` was not supplied and
`--yes`/`--dry-run` are absent. `--yes` reuses the saved plan or chooses the
recommended set on a new host. Noninteractive callers should pass `--tools`,
`--install-methods` and `--yes`; the explicit picker rejects a nonterminal input.
Cancellation installs nothing (except an explicitly accepted missing Python
prerequisite needed to open the picker).

The effective selection/order is saved in
`~/.local/state/dotfiles/tool-selection.json`. Updates and standalone platform
installers reuse it. Docker/font skip flags exclude those tools from the saved
plan. Disabling native suppresses APT/Homebrew tool and build-dependency operations;
GitHub/source-only runs need Python and their required archive/build support
already available. Disabling GitHub artifacts does not prohibit a separately
allowed source clone. Native-only bootstrap skips GitHub-fetched fonts on Linux
and GitHub shell plugins. Addons and explicit editor provisioning remain separate
bootstrap options, and their failures appear in the report.

Build prerequisites are optional when the source channel or editor provisioning
is selected, not automatic for the lean native/artifact setup. Project toolchains
must be selected or already available; selecting a prebuilt Go/Rust CLI does not
install a compiler. Managed Python versions are chosen by project workflows,
rather than silently added on every tool update. `--setup-editor` requires selecting
the terminal editor; selected language provisioning also needs its runtimes.

The workstation verifier uses the saved tool list and does not fail because an
unselected gadget is missing. Observed versions/methods are in the installation
report. `scripts/verify.sh --strict-pins` enforces release pins when desired;
native distro packages and source-built binaries can intentionally differ from
artifact versions/checksums. The server profile retains its independent selection
and verification policy.

## Host-specific agent guidance

`AGENTS.additional.md` and `CLAUDE.additional.md` in the deployed home are generated
from actual executable availability after apply/bootstrap/tool updates. They are
independent files, not static Chezmoi source symlinks. Failed/missing catalog
commands are excluded. Pre-existing tools are included if available, regardless
of the current installation wish list. Version probes check known catalog
commands where supported; unknown binaries are never executed for discovery.
The repository's additional files point to this host-specific documentation.
Global and project `AGENTS.md`/`CLAUDE.md` instructions remain under their owners'
control; explicitly reference the generated additional files where needed.

Discovery includes the conventional user-local, Go and Cargo binary directories,
including configured `GOBIN`, `GOPATH` and `CARGO_HOME`. The inventory reports exact
paths. An unknown executable gets an honest “description not registered” entry
instead of a guessed command purpose. Register descriptions/usages in
`~/.config/dotfiles/custom-tools.json`; see
[the example registry](examples/custom-tools.json). Entries only appear when their
executable is actually found. This registry documents existing custom tools; it
does not install arbitrary executables. New installers require an explicit,
reviewed catalog recipe and official repository/ref.

```sh
# Regenerate after installing a custom Go/Rust binary elsewhere.
./scripts/generate-agent-guides.py
# Use a company registry; its path is remembered for future regeneration.
./scripts/generate-agent-guides.py --custom-tools /path/to/company-tools.json
# Inspect without writing files or inventory.
./scripts/generate-agent-guides.py --dry-run
```

The structured host inventory is saved at
`~/.local/state/dotfiles/tool-inventory.json`. Custom paths/descriptions stay on the
host. Generated files are replaced atomically without writing through an old
symlink into the repository. Known binary probes are distinct from unprobed custom
file discovery, so neither the documentation nor inventory invents a successful
installation origin.
