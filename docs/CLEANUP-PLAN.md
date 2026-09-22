# Dotfiles cleanup: target state and proposed commits

Status: approved; implementation in progress.

## Objective

Make the repository smaller, clearer, and easier to maintain while preserving
the owner's workstation and SSH-server workflows. Prefer deletion and explicit
native configuration to new frameworks. Keep macOS, supported Debian/Ubuntu,
WSL, and the server profile.

## Agreed target state

- Operator is the only visual style. Its appearance lives directly in the
  Starship, tmux, and Ghostty configs. Keep one Operator Windows Terminal scheme
  and the narrowly scoped WSL settings helper if needed to apply it.
- No style selector, saved style choice, generated theme overrides, alternate
  palettes, CRT shader, workbooks, or `deck` dashboard.
- htop is the system monitor, with an explicit native config for a compact,
  readable dark-terminal layout, useful CPU/memory meters, and a target refresh
  interval of 500 ms. Verify settings against the installed/supported htop
  versions. No replacement dashboard or theme framework.
- btop, chafa, viu, cmatrix, and cava are no longer provisioned or required.
- Bats, Linuxbrew probing, Podman fallback aliases, and the manual `~/.fzf`
  compatibility path are removed. Keep the distro fzf integration needed by
  supported server packages.
- Linux uses distro tmux. Remove its custom source build, asset pin, and build
  dependencies that have no remaining consumer. macOS continues using Homebrew.
- Remove TPM provisioning and initialization after checking the current local
  tmux config for actual plugin declarations. Do not silently disable discovered
  local plugins; report that conflict before the dependent removal.
- Prettier, Biome, and ESLint are no longer globally provisioned by this repo.
  Remove their VS Code extensions/settings and explicit Mason/global npm
  provisioning. Retain TypeScript language support and pnpm. Project lockfiles,
  dependencies, and project formatter choices remain outside this cleanup.
- Git identity has one authority: `.gitconfig.local`. Bootstrap preserves an
  existing identity and the tracked config does not override it afterward.
- Node and its companion commands resolve through stable installed launchers;
  shell config does not embed a runtime version. Diagnose the existing Node PATH
  workaround before replacing it, preserving working project/runtime behavior.
- Tool updates honor the saved workstation/server profile. `--skip-packages`
  performs no apt, Homebrew, or package-repository setup. Missing prerequisites
  produce an actionable error rather than bypassing the flag.
- Each managed Linux workstation executable has one intended installation
  owner. Preserve pinned versions where currently required; avoid requesting
  redundant distro copies. Servers retain their explicit distro package list.
- Unsupported Linux ARM download entries and bootstrap's incomplete-checkout
  clone fallback are removed.

## Clean bootstrap and upgrade contract

An old machine must be able to pull the new repository and run bootstrap without
leaving identifiable obsolete dotfiles active. Merely deleting source files is
not sufficient: Chezmoi exclusions and source deletion do not cover every old
target or generated file.

Implement a small explicit retirement list for this transition, integrated with
apply/bootstrap, rather than a generic migration framework or arbitrary cleanup
engine. Each feature-removal commit adds its own known obsolete targets.

Required behavior:

1. Discover and classify obsolete targets before changing them. Use exact paths,
   known historical contents, and validated link destinations. The source checkout
   may have moved; unfamiliar links are not automatically trusted.
2. Back up eligible targets and their readable contents before removing them.
   Preserve the existing private backup and recovery model.
3. Remove a symlink only when it can be identified as an obsolete managed link;
   remove a regular file only when it matches known old managed/generated content.
   Never delete a whole application directory containing unrecognized files.
4. Preserve modified or unrecognized files and clearly report them as unresolved
   cleanup. Do not claim the machine is fully reconciled when these remain.
5. Apply the same rules to workstation-to-server transitions for known desktop
   targets. Preserve local override files and application-owned user data.
6. Dry runs show retirement actions without persistent writes. Repeated bootstrap
   and apply runs are harmless. Handle dangling old links as well as regular files.
7. Ordinary apply and the installed configuration updater use the same retirement
   path. A separate manual migration command must not be required.

Examples to inventory during implementation include generated style selections
and overrides, alternate style files, obsolete installed helper commands,
workbook files, btop config, and desktop settings retired by a server transition.
Inspect actual historic targets before finalizing the list; do not infer broad
directory deletion from these examples.

Clean bootstrap does not mean automatic package uninstallation. Remove obsolete
packages from manifests and acceptance checks, but do not purge existing apt or
Homebrew packages, globally installed extensions, Mason packages, or user data.
They may have other consumers. Identify obsolete user-local executables that
shadow intended replacements (especially tmux); retire them only with verified
ownership and a backup. Report other leftover installations separately.

Keep Git-pull and configuration application conceptually distinct. Symlinked
workstation files change as soon as Git updates their sources; a later bootstrap
cannot reconstruct their pre-pull contents. Retain the snapshot-before-pull
updater as the preferred path. Existing `UPDATE` compatibility can remain: its
few lines are inexpensive and removing it does not improve reconciliation.

## What remains intentionally

- Bash installers and Chezmoi; workstation symlinks and server file deployment.
- Snapshot/restore support, private local overrides, download checksums, atomic
  binary replacement, plugin pins, and completion permission checks.
- Minimal noninteractive `.zshenv` and the existing interactive integrations where
  they have a current purpose: Starship, fzf, zoxide, atuin, direnv, and mise.
- Git/delta, Neovim/LazyVim, VS Code, SSH configuration, Ghostty terminfo, and
  explicit editor provisioning.
- The Mac-only Ghostty setup workflow, with historical config-path compatibility
  retained unless actual supported-version checks justify removing it safely.
- Python behavioral tests, ShellCheck, platform CI, and the narrow historical
  secret-scan exception.
- Other CLI tools and short interactive helpers unless separately confirmed
  unused. Removing a workbook does not prove all tools it demonstrated are unused.
- Small local duplication where sharing it would introduce an installer framework.

## Proposed atomic commits

Every commit includes its directly affected documentation, manifest inventory,
and verification changes. Each must leave the repository usable on its own.
Run focused tests for behavior changes; use existing checks for simple deletion.
Do not combine unrelated cleanups merely because they touch the same file.

### 1. `docs: correct stale setup and runtime guidance`

Correct known behavior mismatches and avoid duplicating runtime versions in
prose. Preserve this approved target-state document as the implementation guide.
Risk: low. Validation: compare documentation against the current code.

### 2. `chore: remove unsupported Linux ARM asset metadata`

Delete unused Node/Go/Chezmoi Linux ARM entries and unreachable architecture
branches; regenerate the asset inventory. Preserve Apple Silicon Homebrew support.
Risk: low. Validation: existing manifest and script checks.

### 3. `refactor: require a complete checkout for bootstrap`

Remove bootstrap's clone fallback and its now-unused repository parameters;
fail clearly when required checkout files are missing. Preserve the installed
updater's useful checkout resolution.
Risk: low. Validation: complete checkout, incomplete checkout, and help paths.

### 4. `fix: make local Git identity authoritative`

Remove the trailing tracked identity. Preserve or migrate the current effective
identity before removal where needed; do not leave an existing machine unable
to commit merely because its local identity file was absent.
Risk: low to medium. Validation: effective identity from a deployed config,
existing local identity preservation, and fresh setup.

### 5. `fix: preserve existing server runtime launchers on fallback`

Keep the recent download-recovery behavior but remove unnecessary relinking of
already available runtimes, avoiding self-referencing local symlinks.
Risk: low to medium. Validation: download failure with system executables and
with existing user-local launchers; no package fallback under skip-packages.

### 6. `fix: respect profiles and package boundaries during tool updates`

Read the existing saved profile, dispatch explicitly, and honor skip-packages
across every package-manager path. Preserve explicit Docker/font exclusions
through supported update arguments; do not invent a persistent preference system.
Keep server editor provisioning explicit rather than expanding a server update
into a workstation install.
Risk: medium. Validation: stubbed Linux workstation, server, WSL, and macOS
dispatch; no package calls with skip-packages; no unrequested server runtimes.

### 7. `feat: retire known obsolete managed files safely`

Add the minimal retirement mechanism described above and tests for its contract.
Initially exercise known profile-transition targets; subsequent commits extend
the explicit list with the features they remove.
Risk: medium because deletion is involved. Validation: isolated old-machine
fixtures covering exact matches, edits, moved checkouts, dangling links, private
backups, restore, dry run, repeat apply, and workstation-to-server transition.

### 8. `refactor: make Operator the only terminal style`

Move Operator appearance into native configs; remove alternate styles, selector,
style state handling, generated overrides, and CRT support. Retain only Operator
in Windows Terminal setup. Add exact obsolete targets to retirement handling.
Risk: medium. Validation: fresh and upgraded deployment, source configs parse,
no stale generated overrides win, Windows helper preserves unrelated settings.

### 9. `chore: remove workbooks and deck experiences`

Remove workbook code/data/help page, lab/deck commands and aliases, their tests
and documentation, and cmatrix/cava provisioning. Add their old managed files
to retirement handling. Keep unrelated utility packages.
Risk: low after reconciliation exists. Validation: reference search, fresh/old
deployment, and existing checks.

### 10. `feat: configure htop as the sole managed system monitor`

Add the small native htop config and provision htop for workstation and server.
Remove btop configuration/provisioning/pins, and remove chafa/viu provisioning.
Retire identifiable obsolete managed config. Do not uninstall system packages.
Risk: low to medium. Validation: config compatibility and interactive display
where available; deployment and package-list checks on remaining platforms.

### 11. `chore: remove unused global formatting tools`

Remove Prettier/Biome/ESLint extensions, explicit editor-tool provisioning,
global Biome installation/version checks, and VS Code settings naming them.
Preserve pnpm, language servers, Markdown wrapping, and project formatting choices.
Check the pinned LazyVim config for implicit formatter selection before claiming
all managed references are removed; disable only the relevant automatic behavior.
Risk: medium. Validation: no dangling formatter selections or verification
requirements; editor startup and retained language configuration.

### 12. `chore: remove unused shell compatibility and Bats`

Remove Linuxbrew probing, Podman aliases, manual-fzf fallback, and Bats package
requirements. Preserve distro fzf compatibility, normal Docker behavior, and
Python tests. Avoid unrelated alias cleanup.
Risk: low. Validation: shell syntax and existing regression checks.

### 13. `chore: remove unused TPM support`

After verifying local plugin usage, remove TPM bootstrap flags, pins, startup,
verification, and documentation. An existing TPM checkout is user data: leave it
inert unless its removal is separately justified and backed up.
Risk: conditional on local plugin check. Validation: tmux config loads without
TPM and local config remains preserved.

### 14. `refactor: use distro tmux on Linux`

Remove the custom tmux build, pin, and now-exclusive build prerequisites. Ensure
an old repo-installed `~/.local/bin/tmux` does not shadow distro tmux: identify
and back it up before retiring it; preserve unknown custom builds and report
them. Do not terminate running tmux sessions.
Risk: medium. Validation: supported distro feature compatibility, new executable
resolution, existing-session preservation, old-machine upgrade fixture.

### 15. `chore: remove duplicate workstation package ownership`

For the remaining directly managed tools, remove redundant explicit apt requests
after checking dependency needs. Keep server distro packages and necessary
runtime libraries. Do not automatically uninstall existing apt packages.
Risk: medium. Validation: disposable supported Linux installation, tool resolution,
and focused acceptance checks.

### 16. `fix: resolve Node tools through stable launchers`

Investigate the current uncommitted PATH change and installer assumptions. Repair
launcher setup if required, then remove the version-specific Node PATH entry.
Do not overwrite the user's existing edit without understanding its effect.
Risk: medium. Validation: Node/npm/npx/pnpm resolution in interactive and
noninteractive shells, with and without project mise configuration; repeat setup.

## Acceptance criteria

- Fresh workstation and server deployment reflects the agreed target state.
- An old-checkout upgrade plus bootstrap retires identifiable obsolete managed
  files, preserves custom data, and reports any unresolved remnants explicitly.
- Repeat bootstrap/apply is safe; dry runs do not persist changes.
- Operator renders consistently without a style initialization command.
- htop is configured and distro tmux wins for new Linux invocations.
- No removed feature remains required by installers, verification, docs, or
  shell/editor startup.
- Updates respect profiles and package boundaries; Git identity and Node command
  resolution behave consistently.
- Existing checks pass. Platform-specific checks not executed locally are stated
  explicitly; do not claim full macOS/WSL/package-install coverage from Linux tests.
- No destructive package purge, project dependency change, or local override
  deletion is bundled into the cleanup.

Rollback of source changes uses individual commit reverts. Retired live files
must be recovered from their backups when needed; reverting Git alone does not
restore retired generated/local files or previously installed packages.
