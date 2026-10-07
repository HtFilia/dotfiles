# Corporate workstation

`environment/corporate` derives from personal `master`. The initial target is
Debian 12/13 x86_64, including Debian under WSL. macOS, Ubuntu and the server
installer are deliberately rejected on this branch until their acquisition and
runtime requirements are established. Existing personal guides for those hosts
describe `master`, not corporate support.

The implementation is ready for an infrastructure pilot, not yet accepted inside
the corporation. [AGENTS.md](../AGENTS.md) is the handoff checklist. All C01–C15
remain open until the infrastructure agent records sanitized evidence there.

## Acquisition and differences

| Component | Corporate source / behavior |
| --- | --- |
| Node, npm, Go, Rust, rustfmt/Clippy, gh | Existing authorized APT sources; no vendor repository, rustup update or automatic Go toolchain fetch |
| Shell/CLI tools, Neovim, pnpm, Biome, tree-sitter | Reviewed GitHub release URLs and SHA256 pins in [ASSET-MANIFEST.md](ASSET-MANIFEST.md); tmux builds from its pinned GitHub source release |
| Python | APT Python remains the default; explicit `scripts/setup-python.sh` supplies pinned GitHub CPython 3.14.7 as `python3.14` |
| Editor tools | APT-owned Go/shell tools, hashed GitHub release artifacts, or a reviewed internal npm/Python closure; no Mason registry |
| Neovim plugins/parsers | Existing GitHub commit lock, explicit setup only; parser source revisions recorded and checked |
| Completion | Blink uses its Lua matcher, preserving completion without downloading a native library at startup; performance/ranking may differ |
| Docker | Existing APT sources only; Compose and Buildx required when selected; WSL engine is host-owned; image acquisition still requires C10 |
| Tokei | Optional APT package with a diagnostic when absent; no Cargo build fallback |
| VS Code / Ghostty | Supplied separately by IT; VSIX provisioning is opt-in and uses reviewed GitHub assets only |
| Configuration | Independent files by default; personal identity and forced SSH rewrite removed; host-local Git/SSH overrides retained |

The existing themes, shell functions, keybindings, workbooks and terminal layouts
are retained. Distro runtime versions can differ from personal versions; C05 must
check actual projects. Selected editor tools are required: a missing closure fails
setup instead of silently skipping a server or formatter.

The pnpm, Biome and tree-sitter hashes were computed from official HTTPS GitHub
release payloads during this implementation. They pin the reviewed bytes, but are
not independent publisher signatures. Other retained hashes keep the repository's
existing provenance; the optional Python pin follows uv's recorded build metadata.
Review publisher checksums/attestations when available before infrastructure
acceptance. Do not assume GitHub API, archive CDN or SSH access from release access.

## Prepare the host

Use a regular account and a checkout on the corporate branch:

```sh
git clone --branch environment/corporate https://github.com/HtFilia/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/corporate-preflight.sh
```

The branch must first be published by its maintainer. Use an approved Git transport;
there is no blanket URL rewrite. Keep corporate CA/proxy configuration in native
Git/curl/npm/Python settings. TLS verification remains enabled. The Python download
helper uses system trust plus standard `SSL_CERT_FILE` / `SSL_CERT_DIR` settings;
HTTPS proxy variables are honored. Existing global/system Git settings are retained.

Create owner-only `~/.config/dotfiles/corporate.env` with infrastructure-supplied
values. This is trusted host-owned shell code sourced by setup and Zsh. Example
placeholders below are intentionally unusable:

```sh
export DOTFILES_NPM_REGISTRY='https://artifactory.example.invalid/npm/'
export DOTFILES_PYTHON_REGISTRY='https://artifactory.example.invalid/python/simple/'
```

Default unset registries point to `registry.invalid`; Python extra-index fallback
is cleared. Package URLs must have the same HTTPS origin as their declared internal
registry, including port. Registry URLs must not contain credentials. Public npm
and PyPI URLs are rejected. Internal redirects cannot leave that origin; reviewed
GitHub releases can redirect only to GitHub's release asset hosts.

Obtain temporary `DOTFILES_ARTIFACTORY_TOKEN`, or
`DOTFILES_ARTIFACTORY_USERNAME` / `DOTFILES_ARTIFACTORY_PASSWORD`, through the
approved host credential mechanism. The download helper sends them only to the
internal source. Never commit them or include them in URLs or command arguments.
Native npm/pip settings still apply to ordinary project work; the editor installer
fetches verified packages first and invokes native package managers offline.

Set `DOTFILES_GIT_NAME` and `DOTFILES_GIT_EMAIL` for first deployment, or provide
`~/.gitconfig.local` with the corporate identity. Keep SSH credentials and host
rules in `~/.ssh/config.local`. Existing local identity files are preserved.

APT changes need sudo or administrator provisioning of
`scripts/corporate-packages.sh`. `--skip-packages` performs no apt/sudo changes.
That path still requires the runtimes, compiler and libraries to be installed.

## Reviewed editor inputs

Place inputs under `~/.config/dotfiles/corporate-packages/<language>/`;
`DOTFILES_EDITOR_MANIFEST_DIR` can override that root. Resolve packages inside the
corporation using native npm/pip and the actual internal mirrors. Review the full
closure and compatibility with the distro runtime before using it. No speculative
internal endpoints or package versions are committed to this repository.

| Language | Required executables |
| --- | --- |
| lua | lua-language-server, stylua |
| python | basedpyright-langserver, ruff (Node/npm plus Python venv support required) |
| go | gopls, goimports |
| rust | rust-analyzer (rustfmt/Clippy supplied by APT) |
| node | typescript-language-server, tsc, prettier |
| shell | bash-language-server, shfmt, shellcheck |

Each language directory can combine these native inputs:

- **npm:** `package.json` with exact dependency versions, no root lifecycle scripts,
  and `package-lock.json` v2/v3 with every transitive `resolved` URL internal and
  every integrity value SHA512. No workspace links or Git dependencies. Generate
  the lock using `npm install --package-lock-only --ignore-scripts --audit=false
  --fund=false --registry "$DOTFILES_NPM_REGISTRY"` in a scratch directory, then
  validate it. All lifecycle scripts are disabled during offline installation;
  packages that require them need a separately reviewed artifact path. npm engine
  constraints are enforced against the distro runtime during installation.
- **Python:** `wheels.json` with the complete compatible wheel closure, including
  transitive dependencies. Each record is `{ "filename": "package-1.0.0-py3-none-any.whl",
  "url": "https://artifactory.example.invalid/python/package.whl", "sha256": "<64 hex digits>" }`
  inside `{ "wheels": [...] }`. Download with `pip download --only-binary=:all:
  --index-url "$DOTFILES_PYTHON_REGISTRY"` in the target interpreter environment;
  record the actual artifact URLs and hashes. Installation uses a venv, local
  wheels, `--no-index` and `pip check`; no source builds or public resolution.
- **GitHub artifacts:** `artifacts.json` is a list of records with `tool`, `version`,
  `url`, `sha256`, `member` and `format` (`binary`, `tar.gz`, `tar.xz`, or `zip`).
  `url` must name a reviewed upstream GitHub release asset. `member` is the
  relative executable path, including `tool` for a bare binary. Optional
  `version_args` defaults to `["--version"]`; `reported_version` handles a
  documented mismatch in upstream release metadata. Archives preserve resources;
  unsafe paths are rejected and the executable must report the reviewed version.

APT ownership is checked for existing `/usr/bin` Go/shell tools. Each remaining
selected tool must have exactly one output across the language's native inputs.
Review manifests before download:

```sh
python3 scripts/install-editor-tools.py --check lua python go rust node shell
```

The installer stages each closure in a separate prefix under
`~/.local/opt/dotfiles-editor`, publishes it only after native package checks, and
links executables into `~/.local/bin`. Matching prefixes are reused without fetching
or rebuilding; altered/missing executables are refused. Python venv paths remain
stable through an immutable staging directory and a versioned link. Older prefixes
are retained. Full parser success is required before the editor selection marker
is written. A failed multi-language setup can leave successfully staged tools,
but does not claim completion for the new selection; retry after fixing inputs.

For VS Code, provide host-local `vsix.json`: a list of `id`, `version`, `url`,
`sha256`, and `runtime_reviewed: true` records. Review each extension's downloads,
external services and dependency closure. Every dependency/extension-pack member
must be included. Local VSIX identity/version are checked, dependencies install
first, and cycles fail before activation. Extensions unavailable as authorized
GitHub assets remain C09 questions. The old extension ID list is a selection
reference, not an acquisition source. Updates and schema/type downloads are
disabled in managed settings; extension-specific behavior still needs acceptance.

## Install, verify and recover

```sh
./scripts/bootstrap.sh --dry-run --skip-docker
./scripts/bootstrap.sh --yes --skip-docker
# Or after IT provisions packages:
./scripts/bootstrap.sh --yes --skip-packages --skip-docker
# Once selected manifests have passed review:
./scripts/setup-editor.sh python shell
./scripts/install-vscode-extensions.sh
./scripts/verify.sh --profile workstation
```

Bootstrap's `--editor-languages python,shell` provisions that explicit selection;
`--setup-editor` selects all six. Selected manifests are validated before APT/tool
acquisition. `--with-vscode-extensions` is opt-in. Fonts, shell plugins, TPM, login
shell changes and Docker group membership retain their explicit flags. WSL fonts,
clipboard and GUI applications require Windows-host checks.

`just tools-update --dry-run` previews acquisition. `--skip-packages` avoids sudo;
updates preserve the saved Docker and editor selections, use the checked-in pins,
and leave whole-system upgrades to IT. No rustup update, implicit interpreter
install, crates.io build or Go proxy fallback is performed. Cargo is offline and
Go toolchain downloads are disabled; C12 must establish project dependency access.
mise stays available with automatic installation disabled.

Configuration defaults to file materialization. Existing saved symlink mode is
preserved; migrate deliberately with `scripts/apply-dotfiles.sh --materialize file`.
Apply snapshots live targets before writing. Use `scripts/restore-dotfiles.sh`
with a reviewed backup directory for configuration recovery. Standalone executable
replacement preserves `.previous`; runtime/editor prefixes remain available for
manual launcher rollback. Refuse incomplete prefixes, inspect/move them aside,
then retry. These helpers do not roll back APT or uninstall packages.

Run `just check`, `just workflow`, `just security`, and `just dry-run` locally.
Corporate tests use temporary homes, synthetic internal artifacts and native
offline npm/pip; they do not establish real Artifactory access. GitHub-hosted CI
adds fresh Debian workstation provisioning and repeat installation. Its public
container image is a CI fixture, not an authorized corporate image source.

The infrastructure agent must also test existing-host PATH cleanup, offline shell
and editor startup after provisioning, each selected LSP/formatter/parser, Git and
SSH, history/completion/search, tmux/workbooks, clipboard/fonts, interrupted setup,
blocked sources, wrong versions, compiler failure and secret-redaction. Capture
sanitized versions and outcomes beside C01–C15; no network acceptance is inferred
from a local test or an ordinary Debian APT simulation.

## Synchronize from master

Use merge for the shared derivative; retain the corporate patch history. Run this
only from a clean corporate checkout, after reviewing the incoming changes:

```sh
git switch environment/corporate
git fetch origin
git merge --no-ff origin/master
just check
just workflow
git diff origin/master...HEAD -- scripts home docs AGENTS.md
```

Resolve installer/editor conflicts against the authorized acquisition policy.
Reassess each adaptation as master evolves; remove obsolete differences when its
replacement passes corporate acceptance. Propose generally useful fixes separately
against master. Never merge this branch into master or track master as its upstream.
After authorized publication, track `origin/environment/corporate`;
`scripts/update-dotfiles.sh` requires that upstream and uses `git pull --ff-only`.
Branch/origin guards reject accidental updates from personal or detached checkouts.
