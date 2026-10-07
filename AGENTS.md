# Corporate environment handoff

This file applies to `environment/corporate`. Canonical personal configuration is
on `master`. Keep corporate changes on this branch and merge reviewed `master`
updates into it; never merge this branch back into `master`. Preserve the existing
tools, themes, aliases and keybindings. Use ordinary shell scripts and package
managers; do not add an environment-switching framework.

## Instructions for the agent inside corporate infrastructure

Resolve the questions below using read-only discovery first. Record sanitized
evidence, dates and concrete decisions in this file and `docs/CORPORATE.md`.
Never commit registry credentials, internal certificates, host identifiers or
private endpoints. Store machine-specific settings in host-local files. Do not
disable TLS verification, add public registry fallbacks, or bypass network policy.
Do not mark a question resolved merely because it works outside the corporation.

Authorized acquisition: existing authorized APT repositories, approved GitHub
release assets/source repositories, and internal npm/Python Artifactory. GitHub
API, SSH, archive redirects and workflow artifacts require separate verification.
Cargo registries, Go module proxies, container registries and vendor repositories
are not implicitly authorized.

## Open questions and required evidence

| ID | Question | Evidence / completion criteria | Status |
| --- | --- | --- | --- |
| C01 | Actual Debian release, architecture, desktop/WSL/SSH arrangement? | `/etc/os-release`, `dpkg --print-architecture`, terminal/clipboard checks; current target is Debian 12/13 x86_64 workstation | Open |
| C02 | Are sudo/APT changes allowed, or must an administrator provision packages? | Sanitized APT policy and simulated package install; test `--skip-packages` path | Open |
| C03 | Which GitHub transports and release/archive redirect hosts are permitted? | Clone/fetch, pinned asset download and parser archive tests independently; no dependency on API access | Open |
| C04 | Which corporate CA/proxy settings must Git/curl/npm/Python retain? | TLS succeeds with verification enabled; no credentials in logs | Open |
| C05 | Are distro Node/Go/Rust versions adequate for actual projects? | Representative projects plus recorded compiler versions; if inadequate, establish a fully authorized source-build closure before changing pins | Open |
| C06 | What are the internal npm/Python registry configuration and authentication mechanisms? | Host-local configuration; scoped credentials; public fallback and malicious external tarball rejection tests | Open |
| C07 | Which exact editor npm/Python packages and all transitive distributions are mirrored? | Reviewed npm lockfile and hashed Python wheel manifest; runtime compatibility and offline installation; record chosen versions | Open |
| C08 | Are all six editor languages essential? Are Go editor tools in authorized APT? | LSP, completion, format and diagnostic tests for each selected language; never omit a selected tool silently | Open |
| C09 | Are Ghostty and VS Code already supplied? Which extensions/services are mandatory? | Authorized application source, reviewed VSIX dependencies and runtime downloads; AI service access is separate | Open |
| C10 | Are Docker/Compose/Buildx and container image sources authorized? | CLI/plugin tests and representative workload from an explicitly authorized image source; no vendor APT repository | Open |
| C11 | Can Tokei be installed from authorized APT? | Version plus workbook test; otherwise retain explicit optional diagnostic, no crates.io build | Open |
| C12 | Which Cargo/Go project dependency sources are authorized? | Full transitive closure; no `GOPROXY=direct` or disabled checksum service as a workaround | Open |
| C13 | Do all retained binaries execute on target libc/CPU? | Pinned version/path checks, shared-library checks, shell/editor/workbook parity | Open |
| C14 | Can Python 3.14.7's pinned GitHub build run and find necessary internal wheels? | Explicit interpreter setup, artifact hash and representative venv/package tests; system Python unchanged | Open |
| C15 | Has the full lifecycle passed inside the corporate network? | Fresh host, existing host, repeat setup, interruption/recovery, blocked source and secret-redaction tests | Open |

## Verification and maintenance

Run `just check`, `just workflow`, `just security`, and the corporate offline tests.
Use temporary homes for test deployment; do not apply to the agent's live home.
Full corporate installation is a separate acceptance step, not an offline-test
result. Follow `docs/CORPORATE.md` for registry lock preparation, installation,
rollback and upstream merge commands. Update this checklist after every pilot.

## Evidence from implementation outside corporate infrastructure

Recorded 2026-10-07 on ordinary Debian 13 x86_64. These results do **not** resolve
the corporate checklist:

- `just check`: 52 tests, 51 passed and one personal macOS routing test skipped;
  shell syntax, Zsh syntax and ShellCheck passed. Corporate contracts include
  native offline npm/pip, disabled lifecycle scripts, complete-selection validation,
  checksum/redirect rejection, version failure, staged recovery, prefix reuse,
  changed executable detection, VSIX dependency order, missing-plugin startup,
  and wrong branch/upstream rejection.
- `just dry-run`, actionlint, Python/Lua syntax checks and a redacted working-tree
  secret scan passed. The original personal worktree remained untouched.
- The full APT package list simulated successfully against this host's existing
  Debian 13 sources. No packages were installed into this host.
- pnpm 12.4.2, Biome 2.5.14 and tree-sitter 0.26.1 were downloaded, checksum checked
  and executed in temporary directories. No live dotfiles were applied.
- Fresh Debian 12/13 and repeated workstation provisioning are encoded in CI;
  those jobs have not run for this unpublished branch. No container engine was
  available locally. Actual Artifactory, GUI, project and corporate lifecycle
  tests remain C01–C15 work for the infrastructure agent.

When answering a question, preserve its ID and replace `Open` with the decision,
date and sanitized evidence reference. If blocked, name the missing authorization
or infrastructure capability and its owner; do not invent a fallback.
