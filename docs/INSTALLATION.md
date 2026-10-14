# Installation and failure policy

Run `./scripts/bootstrap.sh` as your regular account, without sudo. Linux supports
x86_64 Debian 12/13 and Ubuntu 24.04/26.04. macOS native installation needs Homebrew.
Python 3.11+ is the selector/report runtime and must already be installed. If missing,
bootstrap stops with the native installation command before changing the host.

## One workstation workflow

1. Select tools and allowed installation channels. The terminal picker starts with
   13 required/recommended utilities; `list` shows optional categories. Enter names,
   numbers, a preset, or `recommended,+gh,-fzf`. Git, curl, Python and Chezmoi stay
   selected. `none` means those prerequisites only.
2. Choose the primary method and independently allow or deny native, GitHub-release,
   and source-build fallbacks. New hosts default to `native,github`. Selection is
   saved in `~/.local/state/dotfiles/tool-selection.json`; updates reuse it.
3. Authenticate sudo visibly before native Linux package commands. Bootstrap stays
   under your account. Logged children keep the login session for sudo credentials, use `sudo -n`,
   have stdin disconnected, and
   never wait for a hidden password, package question, or Git credential prompt.
   In unattended use, run `sudo -v` beforehand or use passwordless package access.
4. One installer iterates the selected tools. Each receives the same ordered
   channel policy; failures are recorded before trying the next allowed method.
5. Apply Chezmoi configuration, then generate the installed-tool agent guides.

```sh
./scripts/bootstrap.sh
./scripts/bootstrap.sh --tools rg,jq,fd --install-methods native,github --dry-run
./scripts/bootstrap.sh --tools recommended --install-methods github --yes
./scripts/bootstrap.sh --list-tools
./scripts/update-tools.sh --profile workstation
```

`--interactive` opens the picker explicitly. `--yes` uses saved/default choices
without confirmation. `--dry-run` writes no selection, reports, guides or packages.
The [tool audit](TOOL-AUDIT.md) explains the usefulness of every catalog entry.

## Converging failure paths

| Situation | Result |
|---|---|
| Native disabled | No sudo authentication, APT, Homebrew or build-prerequisite package operations |
| Native authentication denied/unavailable | Record why native packages cannot run; try permitted GitHub/source fallbacks |
| A channel fails or times out | Save its reason and log; try the next permitted channel |
| Optional tool has no successful channel | Report failure; proceed to the next selected tool and apply |
| Failed reinstall, existing tool still works | Report `retained`; keep the working executable |
| Git or Chezmoi unavailable after all attempts | Save report and stop before apply |
| Python unavailable | Stop with prerequisite instructions before selection |
| Apply fails | Save report and return nonzero; do not announce success |
| Guide generation fails | Record optional failure with its log |
| Ctrl-C / termination | Stop active command descendants; save interrupted result and exit |
| Run bootstrap with sudo | Refuse before changing user files |

All noninteractive installer commands share one runner. Output appears both on the
terminal and in the log as it arrives. Quiet commands print elapsed time and their
log location every 15 seconds. The default command limit is 300 seconds; builds
may need an explicit allowance, e.g. `DOTFILES_INSTALL_TIMEOUT=1800 ./scripts/bootstrap.sh`.
Git clones and downloads have shorter independent limits. Version probes have
30-second limits; guide probes use three seconds. A timeout stops the process group
and records a failure. Sudo authentication is visible and limited to 120 seconds.

## Installation channels

| Channel | Recipes and permissions |
|---|---|
| `native` | APT via sudo; Homebrew under the user; publisher packages via npm, isolated Python venvs, Cargo, or reviewed Go/Node distributions |
| `github` | Official GitHub release artifacts only, pinned checksums or publisher SHA256 digest; compatible Linux font artifact |
| `source` | Clone the official repository at the reviewed ref and compile locally; compiler prerequisites through native only when native is allowed |

The policy is a set of installation methods, not a network firewall. Cargo/Go/npm/
Python build dependencies may use other registries. A method with no compatible
recipe is reported as unavailable; it never enables another channel implicitly.
Builds need compatible compilers; macOS source builds need Command Line Tools.
Finish installing those tools and rerun rather than expecting a graphical installer
inside bootstrap. Missing libraries are shown in each build's log.

Docker's Linux native recipe installs its official APT service stack; choosing it
is an explicit service-install choice. Bootstrap does not add Docker-group access
or start Colima. WSL uses the Windows host engine. Fonts on WSL also belong on the
Windows terminal host. Optional tools such as fonts are selected in the same picker;
there are no separate skip-fonts/skip-docker toggles.

Packages may be already present with installation origin unknown. Native package
versions follow the configured repositories; reviewed artifact/source replacements
are checked before publication. Existing links are replaced atomically, never
written through into an administrator-owned binary. Verified download caches and
versioned source prefixes support reruns after failure.

## Reports

Each run creates `~/.local/state/dotfiles/install-reports/<timestamp>-<unique>/`:

- `report.md`: tool, status, method, observed version, reasons, and every attempt.
- `report.json`: the same evidence in structured form.
- `<tool>-<method>.log`: command and installer output.

Every result is saved atomically. The report path is printed on success and on
bootstrap failure. Native preparation failure explains how to authenticate again.
A failed native attempt remains visible even when its fallback succeeds.
`LOCAL_BIN` selects the user binary directory; `DOTFILES_DOWNLOAD_DIR` selects the
verified download cache. Add a custom binary location to your persistent PATH.

## Generated agent guides and custom binaries

`~/AGENTS.additional.md` and `~/CLAUDE.additional.md` mention available tools only.
Known binaries receive bounded read-only version probes. Unknown executables in
`~/.local/bin`, `${CARGO_HOME:-~/.cargo}/bin`, `${GOBIN:-${GOPATH:-~/go}/bin}` are
inventoried without execution. Discovery is not a claim that a custom binary works.

Describe custom tools in `~/.config/dotfiles/custom-tools.json`, using
[the example registry](examples/custom-tools.json). A missing executable is omitted.
`--custom-tools FILE` uses and remembers a different registry. Regenerate directly
with `python3 scripts/generate-agent-guides.py`; updates and apply regenerate too.

## Explicit setup and server profile

Bootstrap installs selected tools and applies configuration. Optional plugins,
extensions, editor downloads, shell changes and service starts are separate actions:

```sh
scripts/install-plugin.sh zsh-autosuggestions "$HOME/.local/share/zsh/plugins"
scripts/install-plugin.sh zsh-syntax-highlighting "$HOME/.local/share/zsh/plugins"
scripts/install-plugin.sh tmux-tpm "$HOME/.tmux/plugins"
scripts/setup-editor.sh python shell
colima start
# Install individual VS Code extensions with code --install-extension NAME.
# Change your login shell with chsh after reviewing its installed path.
```

`--profile server` retains the independent SSH/server manifest, with no desktop
catalog. Server-only `--setup-editor`, `--editor-languages LIST`, and
`--system-baseline` are explicit provisioning choices. Preview first:

```sh
./scripts/bootstrap.sh --profile server --editor-languages python,shell --system-baseline --dry-run
```

See [VPS-SERVER.md](VPS-SERVER.md) for ownership and Debian baseline requirements.
`install-server.sh --skip-packages` assumes administrator-provided dependencies.

## Code audit map

| File | Sole responsibility |
|---|---|
| `scripts/bootstrap.sh` | Select → install → apply → guides; server dispatch |
| `scripts/select-tools.py` | Picker and saved tool/channel policy |
| `scripts/tool-catalog.json` | Per-tool recipes, probes, usage and audit rationale |
| `scripts/install-tools.py` | One method loop, command runner, sudo preparation and reports |
| `scripts/generate-agent-guides.py` | Installed-only guides and custom inventory |

`install-report.sh` is small shell glue, not a second installation policy. The
Debian/macOS/extra installer wrappers were removed. Docker, fonts, pinned assets,
and source recipes are leaf operations called through the same bounded runner.
The CI tests exercise all 15 nonempty ordered channel policies, denied credentials,
non-root authentication, hidden-input prevention, streaming, timeout/cancellation,
retention, prerequisites and selected-only behavior on Linux/macOS.
