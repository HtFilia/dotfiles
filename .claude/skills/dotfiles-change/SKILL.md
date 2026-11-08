---
name: dotfiles-change
description: Add, change or remove a tool, alias, package or config file in this chezmoi dotfiles repository, end to end — source files, the tools file Claude Code reads, docs, cheat sheets, checks, container test, commit, then merge, CI and apply when asked. Use for any change to what the dotfiles install or configure.
---

# Change the dotfiles

The repository sets up three machines (Fedora workstation, Debian 13
workstation, Debian 13 server) (`chezmoi data`: profile, context,
gaming). Decide first which machines a change targets; ask if unclear
("Fedora only?" is a common answer). The source root is `home/`
(`.chezmoiroot`).

## 1. Source

| Change | Where |
|---|---|
| Package from dnf, APT or COPR | `home/.chezmoidata/packages.yaml`, in the list for the right OS and profile/context/gaming |
| Binary not packaged (pinned GitHub release) | `home/.chezmoiexternal.toml.tmpl`, with a checksum; add a row to `docs/SUPPLY-CHAIN.md` |
| Config file | the matching path under `home/` (`dot_` = `.`, `.tmpl` = template, guard with the machine's variables) |
| Alias or shell helper | the zsh files under `home/`; aliases that replace standard commands stay off when `CLAUDECODE=1` |
| Plasma colours | `home/dot_local/share/color-schemes/MelangeDark.colors` |

The repository is public: no secrets, host names or personal details, even
in templates.

## 2. Everything that describes the change

- `home/dot_claude/dotfiles-tools.md.tmpl`: what Claude Code is told about
  the tools (table rows, interactive tools that must not be started, aliases).
- `docs/`: the matching guide (`SHELL.md`, `ALIASES.md`, `GIT.md`,
  `TERMINALS.md`, `VISUALS.md`, …) and the README if the install steps change.
- navi cheat sheets: `home/dot_local/share/navi/cheats/dotfiles/*.cheat`.
- `scripts/verify.sh`: add new commands to the right machine's list.
- `tests/`: extend the checks that cover the change (`tests/machine.sh`,
  `tests/shell-functions.sh`, `tests/overrides.sh`).

## 3. Check

```sh
chezmoi diff                                  # only the expected files change
shellcheck <changed scripts>; shfmt -d <changed scripts>
tests/repo.sh                                 # includes gitleaks over the history
tests/container.sh --worktree fedora-perso    # or the scenario the change targets
```

Run the container test for every machine the change touches.

## 4. Commit and ship

- Branch per change, Conventional Commits (`feat:`, `fix:`, `docs:`,
  `test:`, …).
- Only when the user asks: merge into `master`, push, then watch CI with
  `gh run watch`; every scenario must pass.
- Then `chezmoi apply` on the current machine (it rewrites files in `~`
  without backups, so show `chezmoi diff` first) and `scripts/verify.sh`.
  Package changes need sudo: the user runs the apply when the package script
  is involved.
- Give the user any manual step that remains (log out, restart plasmashell,
  `tldr --update`, …).
