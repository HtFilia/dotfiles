# Aliases and helper functions

Aliases are interactive conveniences. Run `alias` for the active list and
`functions NAME` to inspect a helper. Many aliases exist only when their tool is
installed. `cc` remains the compiler command.

## Git aliases

| Alias | Action |
|---|---|
| `g`, `gs` | Git; short status |
| `ga`, `gaa` | Add selected paths; add all |
| `gc`, `gcm`, `gca` | Commit; commit with message; amend |
| `gco`, `gcb`, `gb` | Checkout; create branch; branches |
| `gp`, `gpl` | Push; pull with configured rebase behavior |
| `gl`, `gll` | Graph log; graph including all branches |
| `gd`, `gds` | Unstaged; staged diff |
| `gst`, `gstp`, `gstl` | Stash; pop; list |
| `gf`, `gfa` | Fetch; fetch all with branch pruning |
| `grb`, `grbi`, `gcp` | Rebase; interactive rebase; cherry-pick |
| `grs`, `grss`, `grt` | Restore; unstage; print root |
| `lg` | LazyGit |

`gwip` stages all changes and creates a timestamped WIP commit. `gunwip` only
resets a last commit with that exact subject format; review status first.
`groot` enters the repository root; `gclone URL [DIRECTORY]` clones and enters it.
Git's internal aliases are documented in [Git](GIT.md).

## Files and navigation

| Command | Purpose |
|---|---|
| `ls`, `ll`, `la` | eza basic, detailed, detailed including hidden files |
| `lt`, `ltt` | eza trees limited to two/three levels |
| `..`, `...`, `....`, `-` | Parent directories; previous directory |
| `mkd`, `mkcd DIRECTORY` | Create directories; create and enter |
| `dotfiles` | Enter `$DOTFILES_DIR` or `~/.dotfiles` |
| `fe`, `fcd` | Select and edit a file; select and enter a directory |
| `frg PATTERN` | Structured ripgrep matches, fzf selection, open editor at line |
| `fga` | Select unstaged/untracked files and stage them |
| `fh [QUERY]` | Insert a selected history command for editing |
| `yy [ARGS]` | Yazi; adopt its selected directory on exit |
| `tm [NAME]` | Create or attach tmux session, defaulting to directory name |
| `extract ARCHIVE` | Dispatch extraction to installed archive utilities |

File selectors use NUL delimiters; `frg` uses JSON to preserve spaces and colons.
`fe`/`frg` expect `$EDITOR` to name an executable, not a shell command with flags.
The helper `frg` targets Neovim's `+LINE` command-line convention. Universal
extract dispatch does not automatically install rar/7z utilities.

## Development and processes

| Command | Purpose |
|---|---|
| `uvr`, `uvs`, `uva`, `uvp` | uv run/sync/add/pip |
| `pyi`, `pyls` | uv pip install/list |
| `activate` | Activate existing `.venv` or `venv` |
| `serve [PORT] [ADDRESS]` | Python HTTP server, default localhost:8000 |
| `fkill [SIGNAL]` | Select processes; TERM by default, KILL only explicitly |
| `psg QUERY` | Search running process descriptions |
| `ai`, `air` | Claude; resume session, when installed |
| `lzd` | LazyDocker |

## Containers

`d` is Docker when installed, otherwise Podman. `dc` is Compose. Docker aliases:
`dps`/`dpsa` list running/all containers, `di` lists images, `dex` enters a
container, `dlog` follows logs, and `dprune` runs interactive system pruning
without volume removal. Volume cleanup is a separate explicit decision.

## Platform conveniences

macOS: `showfiles`, `hidefiles`, `flushdns`, `brewup`.
Linux: `aptup` updates indexes and interactively upgrades; `apti`, `apts`,
`aptrm`, `aptshow`; `sc`, `scu`, `jcf`, `jcu`, `jcb` for systemd/journald;
`open` uses xdg-open when available. `df`, `du`, and Linux `free` use human units.
WSL: `pbcopy`, `pbpaste`, `explorer`, `winhome` use Windows interoperability.
`winhome` resolves the actual Windows profile rather than assuming matching names.
