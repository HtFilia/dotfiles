# Git configuration

The default branch name is `main`. Neovim edits commit messages and merge files;
delta pages diffs with bat's `ansi` syntax theme, which takes its colours from
the terminal palette (Dusk), on Dusk's soft sage and rose line backgrounds. Delta and Neovim must
be available on PATH for these integrations.

## Daily behavior

Pull rebases local commits and automatically stashes dirty changes during rebase.
Review conflicts when that stash is reapplied. Autosquash supports fixup commits.
Push defaults to the current branch, establishes its upstream on first push, and
includes annotated tags associated with pushed commits. Fetch prunes stale
remote branches; it does not globally prune local tags.

Merge conflicts use `zdiff3`; diff uses histogram and moved-line coloring.
Rerere records conflict resolutions for reuse. Line endings use `autocrlf=input`;
repository-local `.gitattributes` is authoritative for project rules.

The global ignore file lists only operating system and editor files (Finder
metadata, swap and backup files, `.idea/`). Build output, dependencies, logs,
virtual environments and `.env` files stay visible until a repository's own
`.gitignore` excludes them, so each project states its policy.

## Identity and authentication

`~/.gitconfig.local` is included last; chezmoi never creates or changes it.
Values in the local file take precedence over the managed configuration.

```sh
git config --file ~/.gitconfig.local user.name 'Your Name'
git config --file ~/.gitconfig.local user.email 'you@example.com'
```

Use conditional includes in that file for work and personal identities; see
[local overrides](LOCAL-OVERRIDES.md#git-a-work-identity-for-work-repositories).
Configure credential helpers or signing there too.

GitHub remotes keep their HTTPS URLs: clone, fetch and pull need no key, so
`chezmoi init`, `chezmoi update` and plugin managers work on a machine without
one. `pushInsteadOf` sends pushes to `git@github.com:` over SSH with the key
chosen in [SSH](SSH.md). `git remote -v` shows both URLs.

## Internal aliases

`git s`, `lg`, `lga`, `last`, `br`, and `aliases` provide status, logs and discovery.
`git undo` soft-resets one commit; `git amend` amends without editing its message.
These change local history, so check whether a commit has already been shared.

`git cleanup [BASE]` deletes branches merged into the specified base, default
`main`, while preserving main/master/develop. Git refuses deletion of checked-out
branches. This is an explicit cleanup command, not a background operation.

For temporary side-by-side diffs:

```sh
git -c delta.side-by-side=true diff
```

`git mergetool` opens quoted local/remote/merged paths in Neovim diff mode.

## difftastic (Fedora)

`~/.config/git/difftastic`, included before `~/.gitconfig.local`, adds
syntax-aware diffs that compare code structure rather than lines:
`git dft [REV]` runs it as a difftool, `git dlg` shows the log with its
diffs and `git dshow REV` one commit. Plain `git diff` still pages through
delta. Git skips the include on machines where the file is not deployed.
