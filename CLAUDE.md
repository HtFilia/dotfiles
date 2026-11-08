# dotfiles

chezmoi dotfiles for three machines (Fedora workstation, Debian 13
workstation, Debian 13 server); the source root is `home/`
(`.chezmoiroot`), so files at the repository root, such as this one and
`.claude/`, are never deployed. `README.md` and `docs/` explain each part.

- Changes: follow the `dotfiles-change` skill (`.claude/skills/`).
- The repository is public: no secrets, host names or personal details, even
  in templates. `tests/repo.sh` runs gitleaks over the history.
- Content in English; Conventional Commits (`feat:`, `fix:`, `docs:`,
  `test:`, `refactor:`, `chore:`).
- Default branch `master`. Merge, push and `chezmoi apply` only when the user
  asks. Every CI job must pass.
