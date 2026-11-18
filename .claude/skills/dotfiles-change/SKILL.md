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
| Binary not packaged (pinned GitHub release) | `home/.chezmoiexternal.toml.tmpl`, with a checksum and a comment giving the reason |
| Config file | the matching path under `home/` (`dot_` = `.`, `.tmpl` = template, guard with the machine's variables), plus its machine-local override: the tool's own include of a local file if it has one, otherwise the managed text in `home/.chezmoitemplates/managed/` and a wrapper calling `local-merge`. Add its row to `docs/LOCAL-OVERRIDES.md`; `tests/repo.sh` fails without it. A file the tool writes itself (like `~/.gitconfig`) is `create_` or merged by a `modify_` script, never plainly managed |
| Alias or shell helper | the zsh files under `home/`; aliases that replace standard commands stay off when `CLAUDECODE=1` |
| Colours (Plasma, Kitty, nvim) | `Dusk.colors`, `kitty/dusk.conf` and `nvim/lua/dusk_palette.lua` are the output of a palette generator kept outside this repository (the user's private instructions say where): never edit them by hand, change the palette and regenerate. tmux, Starship, yazi, fzf and fastfetch carry Dusk hex values by hand, and `tests/repo.sh` refuses a hex value that is not in the palette |

The repository is public: no secrets, host names or employer details, even
in templates.

Key bindings, in any tool: typable on a French AZERTY keyboard, so no digit
row and none of `[ ] { } | \ ~`. Check a new tool's default bindings too and
rebind the ones that break the rule.

## 2. Everything that describes the change

Three places, no more:

- The source itself (step 1). The comment beside a pinned binary in
  `.chezmoiexternal.toml.tmpl` is its documentation.
- `home/dot_claude/dotfiles-tools.md.tmpl`: the one reference for tools,
  aliases and helpers, read by Claude Code and linked from the README. The
  container test fails when the zshrc defines an alias or helper that this
  file does not name.
- `scripts/verify.sh`: add new commands to the right machine's list.

Touch a guide in `docs/` only when the change alters what it explains
(`SHELL.md`, `GIT.md`, `TERMINALS.md`, `VISUALS.md`, `EDITORS.md`, …), the
README only when the install steps change, and a navi cheat sheet
(`home/dot_local/share/navi/cheats/dotfiles/*.cheat`) only for a command
worth recalling with Ctrl+G. Extend `tests/` when the change adds behaviour.

## 3. Check

```sh
just diff                  # only the expected files change
just check                 # ShellCheck, shfmt, gitleaks over the history, rendered templates
just test fedora-perso     # or the scenario the change targets; `just test-all` for all
```

Run the container test for every machine the change touches.

## 4. Commit and ship

- Branch per change, Conventional Commits (`feat:`, `fix:`, `docs:`,
  `test:`, …).
- Only when the user asks: merge into `main`, push, then watch CI with
  `gh run watch`; every scenario must pass.
- Then `chezmoi apply` on the current machine (it rewrites files in `~`
  without backups, so show `chezmoi diff` first) and `scripts/verify.sh`.
  Package changes need sudo: the user runs the apply when the package script
  is involved.
- Give the user any manual step that remains (log out, restart plasmashell,
  `tldr --update`, …).
