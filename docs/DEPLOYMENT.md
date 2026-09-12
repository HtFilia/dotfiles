# Deployment, snapshots and recovery

`apply-dotfiles.sh` uses this repository's `home/` as Chezmoi source state.
`dot_` encodes leading dots; private files/templates and `symlink_` entries use
Chezmoi's native naming. Server exclusions remove desktop settings. macOS routes
VS Code's native User directory to the shared configuration source.

## Materialization

Workstations default to `symlink`: managed ordinary files point into the checkout.
Editing or pulling source changes those files immediately, without another apply.
Servers default to `file`: application configuration remains independent until
apply. Explicit `symlink_` source entries, including macOS VS Code's directory,
remain symlinks in either mode. Templates are rendered files.

Profile and mode are persisted under `~/.local/state/dotfiles` for subsequent
apply and verification. Override with `--profile` and `--materialize`.
Files excluded by a new profile are not automatically deleted; review desktop
files manually when switching an existing workstation to server.

```sh
./scripts/apply-dotfiles.sh --dry-run
./scripts/apply-dotfiles.sh --profile server --materialize file
./scripts/apply-dotfiles.sh --destination /tmp/example-home --force
```

Dry runs use temporary Chezmoi state and leave destination state untouched.
`--force` permits overwriting modified targets after backup. Use previews when
making changes to an existing environment.

## Snapshots

Each write saves existing managed targets under
`~/.local/state/dotfiles/backups/<timestamp>.<random>/`:

- `targets.tar` preserves files and link metadata.
- `contents.tar` dereferences existing links into independent content snapshots.
- `source-revision` records the available source Git revision.

Dangling links have metadata but no readable content snapshot. Files absent
before deployment are not in the archive. Snapshots may contain personal local
settings; backup directories and archives are private. Retention is manual:
inspect timestamps and remove snapshots you no longer need.

```sh
./scripts/apply-dotfiles.sh --snapshot-only
./scripts/update-dotfiles.sh
```

The update command snapshots before `git pull --ff-only` and applies afterward.
It requires a clean checkout and SSH GitHub origin. For a manual source update,
take a snapshot first; an apply after the pull cannot recover previous linked
contents. Keep server file materialization when deliberate activation matters.

## Restore

Inspect an archive before restoring:

```sh
tar -tf /path/to/backup/contents.tar
./scripts/restore-dotfiles.sh /path/to/backup
```

The helper restores independent regular-file contents and replaces leaf links.
It refuses symlinked parent directories; move such a managed directory aside
first. Newly created configuration absent from the snapshot requires separate
review. Restoring files does not uninstall packages or change your login shell.
Use trusted archives created by these scripts, not arbitrary downloaded tarballs.
