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

### Core

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

### Edition

| Action | Keys |
|---|---|
| Move line down/up | `Alt-j` / `Alt-k` |
| Indent / Outdent selection | `>` / `<` (selection is kept) |
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

### Custom functions

| Command | Purpose |
|---|---|
| `fe` | Fuzzy find file + open in `$EDITOR` |
| `fcd` | Fuzzy cd |
| `fga` | Git add with fzf |
| `fkill` | Kill process with fzf |
| `mkcd` | `mkdir` + `cd` |
| `extract` | Universal archive extractor |
