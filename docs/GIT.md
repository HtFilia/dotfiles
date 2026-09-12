# Git configuration

The default branch name is `main`. Neovim edits commit messages and merge files;
delta pages diffs with the built-in Gruvbox syntax theme. Delta and Neovim must
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

Global ignores cover OS/editor debris and generated caches. Project lockfiles,
runtime pins, shared `.vscode` files, and vendored code remain visible. Put
project-specific build-output and secret policies in each repository.

## Identity and authentication

`~/.gitconfig.local` is included last. Apply creates it privately when both a
name and email are supplied; existing files are preserved.

```sh
git config --file ~/.gitconfig.local user.name 'Your Name'
git config --file ~/.gitconfig.local user.email 'you@example.com'
```

Use conditional includes in that file for work/personal identities. Configure
credential helpers or signing there according to your existing account setup.
The dotfiles repository's origin and update workflow use GitHub SSH:
`git@github.com:HtFilia/dotfiles.git`. Other upstream plugin/download URLs do not
require GitHub account authentication. See [SSH](SSH.md).

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
