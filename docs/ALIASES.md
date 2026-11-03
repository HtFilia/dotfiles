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
| `tree`, `lt`, `ltt` | eza tree; trees limited to two/three levels |
| `cat FILE` | bat with syntax highlighting, no line numbers, no pager |
| `fd PATTERN` | fd including hidden files, skipping `.git` |
| `..`, `...`, `....`, `-` | Parent directories; previous directory |
| `mkd`, `mkcd DIRECTORY` | Create directories; create and enter |
| `dotfiles` | Open a shell in the chezmoi source checkout (`chezmoi cd`) |
| `fe`, `fcd` | Select and edit a file; select and enter a directory |
| `frg PATTERN` | Structured ripgrep matches, fzf selection, open editor at line |
| `fga` | Select unstaged/untracked files and stage them |
| `fh [QUERY]` | Insert a selected history command for editing |
| `tm [NAME]` | Create or attach tmux session, defaulting to directory name |
| `extract ARCHIVE` | Dispatch extraction to installed archive utilities |

eza lists directories first and shows icons only on a terminal; `ll` and `la`
add a header, Git status, ISO dates and the group only when it differs from
the owner. Piped or redirected, `cat` writes the file unchanged. ripgrep's
managed configuration searches hidden files except `.git`, uses smart case and
shortens lines longer than 200 columns. `grep`, `diff` and, on Linux, `ip`
colour their output. `command NAME` or `\NAME` runs the original command; the
[shell guide](SHELL.md#customize) lists the opt-in replacements for `grep`,
`find` and `less`.

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
| `vi`, `vim`, `top` | Neovim; htop |

## Containers

When Docker is installed, `d` is Docker and `dc` is Compose. Docker aliases:
`dps`/`dpsa` list running/all containers, `di` lists images, `dex` enters a
container, `dlog` follows logs, and `dprune` runs interactive system pruning
without volume removal. Volume cleanup is a separate explicit decision.

## Platform conveniences

Package aliases follow the machine's package manager:

| System | Upgrade | Install | Search | Remove | Show |
|---|---|---|---|---|---|
| Fedora | `dnfup` | `dnfi` | `dnfs` | `dnfrm` | `dnfinfo` |
| Debian | `aptup` | `apti` | `apts` | `aptrm` | `aptshow` |
| macOS | `brewup` | `brewi` | `brews` | `brewrm` | `brewinfo` |

macOS also has `showfiles`, `hidefiles` and `flushdns`. Linux has `sc`, `scu`,
`jcf`, `jcu`, `jcb` for systemd and journald, and `open` for xdg-open. `df`,
`du` and Linux `free` use human units.
