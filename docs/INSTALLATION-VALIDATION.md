# Installation validation — 2026-10-13

Tests ran in an isolated temporary home on Linux x86_64 (Ubuntu 24.04).
These are test-environment results, not an installation on the owner’s workstation.

22 tools were installed successfully through at least one tested method.
The source builds of shfmt, yq, duf and actionlint used official HTTPS clones and locally compiled Go binaries.
mise also exercised a real native-to-GitHub fallback when Cargo was absent.

Bash/Zsh syntax, ShellCheck, actionlint, whitespace and secret checks passed.
Offline suites: 30 existing tests (27 passed; three skipped for platform/user prerequisites)
and 28 installer tests passed. Skipped integration cases require macOS, Debian 13 or a regular-user bootstrap.
The repository CI retains its macOS and Debian server jobs and runs both offline suites.

APT/Homebrew changes, full Rust/C/C++ builds, Docker service setup and a complete workstation bootstrap were not executed here.
Additional GitHub artifact requests returned HTTP 403. Those failures were recorded while later tools continued.
This does not prove those URLs are unavailable from the workstation; local access policy and upstream responses must be diagnosed there.

| Tool | Test result | Validated installation methods | Observed version | Failed method / reason |
|---|---|---|---|---|
| actionlint | validated | github, source | 1.7.12 |  |
| atuin | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| bat | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| biome | validated | native | Version: 2.5.14 |  |
| broot | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| btop | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| chezmoi | validated | github | chezmoi version v2.72.2, commit 125d00fe730fc9abf456ec312ba85b18c859bc50, built at 2026-09-13T18:23:26Z, built by goreleaser |  |
| czkawka_cli | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| delta | validated | github | delta 0.19.2 |  |
| direnv | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| dua | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| duf | validated | github, source | duf 0.9.1 (b2f01a1ecbfd) (built on 2025-09-08) |  |
| dust | validated | github | Dust 1.2.5 |  |
| eza | validated | github | eza eza - A modern, maintained replacement for ls |  |
| fastfetch | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| fd | validated | github | fd 10.5.0 |  |
| fzf | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| gitleaks | validated | github | 8.30.1 |  |
| go | validated | native | go version go1.27.1 linux/amd64 |  |
| hexyl | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| hyperfine | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| jc | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| jless | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| jq | existing executable | existing / not installed | jq-1.7 | github: Artifact download returned HTTP 403 in this test environment. |
| just | validated | github | just 1.58.0 |  |
| lazydocker | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| lazygit | validated | github | commit=17cb09fa7b08bc96d9f0e81b91f4720fc1a36700, build date=2026-09-13T05:42:30Z, build source=binaryRelease, version=0.65.1, os=linux, arch=amd64, git version=2.51.1 |  |
| mise | validated | github | 2026.9.10 linux-x64 (2026-09-16) | native: Cargo is absent in the test environment. |
| node | validated | native | v26.9.0 |  |
| nvim | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| ouch | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| ov | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| pastel | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| pnpm | validated | native | 12.4.2 |  |
| rg | existing executable | existing / not installed | ripgrep 15.2.0 (rev e89fff89ac) |  |
| sd | validated | github | sd 1.0.0 |  |
| shellcheck | validated | github | ShellCheck - shell script analysis tool |  |
| shfmt | validated | source | 3.10.0 |  |
| starship | validated | github | starship 1.26.0 |  |
| tldr | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| uv | validated | github | uv 0.12.15 (x86_64-unknown-linux-gnu) |  |
| viu | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| vivid | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| watchexec | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| xcp | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| xh | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |
| yazi | validated | github | Yazi |  |
| yq | validated | github, source | yq (https://github.com/mikefarah/yq/) version v4.53.6 |  |
| zoxide | failed | existing / not installed |  | github: Artifact download returned HTTP 403 in this test environment. |

## Reproduce selected checks

```sh
bash tests/script-contracts.sh
./scripts/install-tools.py --only fd,chezmoi --methods github --skip-packages
./scripts/install-tools.py --only shfmt --methods source --skip-packages --reinstall
```

Use a disposable home/environment for live installation tests. These commands intentionally install tools.
For real-machine results, run the normal bootstrap and read its printed report path.
This is a historical record of isolated artifact checks, not a guarantee that every catalog tool installs on every host. Current behavior and the failure policy are documented in [INSTALLATION.md](INSTALLATION.md).

## Runtime selection and guide generation follow-up

The follow-up adds a 13-entry practical default, a terminal picker, persisted
channel/tool selection and host-generated guides. Offline coverage includes
terminal input, optional-channel denial, native operations suppressed even without
`--skip-packages`, selected-only installer dispatch, custom Go/Rust discovery
without execution, and replacing old guide symlinks without editing source files.
The saved custom registry path is reused during later regenerations. Full host
bootstrap and native platform installation still need host validation.

Follow-up check result: 80 offline tests across the three suites, 77 passed and
three skipped for platform/user prerequisites. Bash/Zsh syntax, ShellCheck,
actionlint, whitespace and secret checks passed.
