# ⌨️ Keybindings cheat sheet

## tmux

Prefix: **`Ctrl-a`**

| Action | Keys |
|---|---|
| Split horizontal | `prefix` + `|` |
| Split vertical | `prefix` + `-` |
| New window | `prefix` + `c` |
| Next / Prev window | `prefix` + `n` / `p` |
| Window 1-5 (no prefix) | `Alt-1` … `Alt-5` |
| Move to pane left/down/up/right | `prefix` + `h`/`j`/`k`/`l` |
| Resize pane | `prefix` + `H`/`J`/`K`/`L` (repeatable) |
| Zoom pane | `prefix` + `z` |
| Copy mode | `prefix` + `Enter` |
| Start selection | `v` (in copy mode) |
| Copy selection | `y` (in copy mode) |
| Reload config | `prefix` + `r` |
| Install plugins | `prefix` + `I` |
| Update plugins | `prefix` + `U` |

## Neovim

Leader: **`<Space>`**

`~/.config/nvim` is managed by Chezmoi and points to the single LazyVim-based
profile in `home/dot_config/nvim`.

### LazyVim

| Action | Keys |
|---|---|
| Save | `Ctrl-s` |
| Find files | `<leader>` + `ff` |
| Live grep | `<leader>` + `/` |
| Recent files | `<leader>` + `fr` |
| Buffers | `<leader>` + `,` |
| Switch buffer | `Shift-h` / `Shift-l` |
| File explorer | `<leader>` + `e` |
| Keymap help | `<leader>` + `?` |
| Terminal | `<leader>` + `ft` |
| LazyGit | `<leader>` + `gg` |

### LSP

| Action | Keys |
|---|---|
| Go to definition | `gd` |
| Find references | `gr` |
| Hover docs | `K` |
| Code action | `<leader>` + `ca` |
| Rename | `<leader>` + `cr` |
| Format | `<leader>` + `cf` |
| Diagnostics list | `<leader>` + `xx` |

### Editing

| Action | Keys |
|---|---|
| Paste over without losing clipboard | `p` (in visual mode) |
| Clear search highlight | `Esc` |

### tmux <-> nvim navigation (seamless)

| Action | Keys |
|---|---|
| Move pane/split left | `Ctrl-h` |
| Move pane/split down | `Ctrl-j` |
| Move pane/split up | `Ctrl-k` |
| Move pane/split right | `Ctrl-l` |

## Ghostty

| Action | Keys |
|---|---|
| New tab | `Ctrl-Shift-t` |
| Close tab | `Ctrl-Shift-w` |
| Next / Previous tab | `Ctrl-Tab` / `Ctrl-Shift-Tab` |
| Split right | `Ctrl-Shift-d` |
| Split down | `Ctrl-Shift-e` |
| Navigate splits | `Ctrl-Alt-arrows` |
| Clear screen | `Ctrl-Shift-k` |
| Zoom +/- / reset | `Ctrl-+` / `Ctrl--` / `Ctrl-0` |

## Shell (Zsh)

| Action | Keys |
|---|---|
| Fuzzy file search | `Ctrl-t` (fzf) |
| Fuzzy cd into dir | `Alt-c` (fzf) |
| History search | `Ctrl-r` (atuin) |
| Accept autosuggestion | `→` (right arrow) or `End` |
| Accept autosuggestion word | `Alt-f` or `Ctrl-→` |
| Reject autosuggestion | `Ctrl-g` |

### Custom functions

| Command | Purpose |
|---|---|
| `fe` | Fuzzy find file + open in `$EDITOR` |
| `fcd` | Fuzzy cd |
| `fga` | Git add with fzf |
| `fkill` | Kill process with fzf |
| `frg` | Ripgrep + fzf + bat preview, then open match in `$EDITOR` |
| `fh` | Fuzzy shell history into the current command line |
| `mkcd` | `mkdir` + `cd` |
| `extract` | Universal archive extractor |
| `groot` | cd to the current Git repository root |
| `gclone` | clone a repo and cd into it |
| `gwip` / `gunwip` | create or undo a timestamped WIP commit |
| `serve` | start `python3 -m http.server` |
| `activate` | source `.venv/bin/activate` or `venv/bin/activate` |
