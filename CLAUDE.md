# dotfiles

chezmoi dotfiles for three machines (Fedora workstation, Debian 13
workstation, Debian 13 server); the source root is `home/`
(`.chezmoiroot`), so files at the repository root, such as this one and
`.claude/`, are never deployed. `README.md` and `docs/` explain each part.

- Changes: follow the `dotfiles-change` skill (`.claude/skills/`).
- The repository is public: no secrets, host names or employer details, even
  in templates. The author's name and site in the README header are
  deliberate. `tests/repo.sh` runs gitleaks over the history.
- Every key binding the repository configures, in any tool, must be typable
  on a French AZERTY keyboard without the digit row and without
  `[ ] { } | \ ~` (see Decisions).
- Content in English; Conventional Commits (`feat:`, `fix:`, `docs:`,
  `test:`, `refactor:`, `chore:`).
- Default branch `main`. Merge, push and `chezmoi apply` only when the user
  asks. Every CI job must pass.

## Decisions

| Date | Decision | Reason |
|---|---|---|
| 2026-11-15 | Bindings are AZERTY-compatible in every tool, installed now or later; broken ones are fixed, and `tests/repo.sh` lints for them. "No digit row" means the digits only: `(`, `)`, `-`, `=` and `"` are unshifted and allowed. `(` and `)` replace the `[` / `]` prefixes in Neovim and LazyGit. Scope: what the repository binds, the defaults `docs/KEYBINDINGS.md` teaches, and core actions with no other key; not Vim's own grammar. | The digits need Shift and the brackets AltGr on the author's keyboard. |
| 2026-11-15 | No advice to put a passphrase on SSH keys. | The author does not want one yet. |
| 2026-11-15 | The default branch is `main` here and in webfolio (renamed from `master`). | Coherent with `init.defaultBranch` and `git cleanup`. |
| 2026-11-15 | atuin and direnv are removed; fzf's Ctrl-R searches the history. | Unused: no sync server, no `.envrc` in any project. |
| 2026-11-15 | Language servers are installed by uv, rustup, npm and the package manager, pinned; Mason and `scripts/setup-editor.sh` go. Python uses Pyrefly and Ruff. | One pinned install path instead of an unpinned registry. |
| 2026-11-15 | gitleaks runs in a pre-commit hook of this repository only (`.githooks`), enabled by `chezmoi apply`; never a global hook. | Catch a secret before it is pushed, without touching other repositories. |
| 2026-11-15 | Dependabot updates GitHub Actions only; `just outdated` reports stale pinned binaries. | Dependabot cannot recompute the pinned checksums. |
| 2026-11-15 | Machine-specific tools (nvtop…) and the Podman quadlets stay out of this repository. | Not common to the three machines; the quadlets carry home-network details. |
| 2026-11-15 | The palette source and generator live outside this repository, which never names where. Their output (`Dusk.colors`, `kitty/dusk.conf`, `dusk_palette.lua`) is committed here as plain files, and `tests/repo.sh` checks the hand-written colours against them. | This repository is public and stands alone; the palette also serves private projects. |
| 2026-11-15 | The server is managed by chezmoi like the other machines: a daily timer applies file changes, `just vps-update` runs the package scripts that need sudo. | The server was still on the former scripts. |
| 2026-11-15 | `dotfiles-tools.md.tmpl` is the single reference for tools and aliases; `docs/ALIASES.md` merges into it. | A tool change touched seven files. |
| 2026-11-16 | With every machine on chezmoi, the migration guide and the "dropped platforms" test go; `.chezmoiremove` keeps only entries a machine has not applied yet. | They served the move away from the former scripts, now finished. |
| 2026-11-18 | The shared Git settings live in `~/.config/git/config`; `~/.gitconfig` belongs to the machine (`create_`, never changed). For one key the order is dotfiles < `~/.gitconfig.local` < `~/.gitconfig`. A one-time script removes the dotfiles' copy from existing `~/.gitconfig` files. | Each apply reverted the identity and the employer's settings that `git config --global` had written on the work workstation. |
| 2026-11-18 | Every managed config has a machine-local override. Tools that read a second file do so themselves; for the others, chezmoi merges `<name>.local.<ext>` into the managed file at apply time, so a change to that file needs `chezmoi apply`. | Any setting must be overridable on the machine being installed. |
| 2026-11-18 | VS Code: the dotfiles' keys win over the UI on apply, other keys written by the UI stay; `settings.local.json` and `keybindings.local.json` override the dotfiles. | Overrides belong in the local file; the UI must not silently lose them. |
| 2026-11-18 | fastfetch: `config.local.jsonc` replaces the module list and the logo as a whole. | Both are machine-specific. |
