# ⌨️ Keybindings cheat sheet

Every key the repository binds is typable on a French AZERTY keyboard: no
digit, and none of `[ ] { } | \ ~`, which need Shift or AltGr there.
`tests/repo.sh` refuses a binding that breaks the rule. Where a tool's default
uses such a key, the table gives the replacement.

## tmux

Prefix: **`Ctrl-b`**

| Action | Keys |
|---|---|
| Split side by side | `prefix` + `v` |
| Split top / bottom | `prefix` + `s` |
| New window | `prefix` + `c` |
| Next / Prev window | `Shift-→` / `Shift-←` (no prefix), or `prefix` + `n` / `p` |
| Pick a window or session from a list | `prefix` + `w` |
| Move to pane left/down/up/right | `prefix` + `h`/`j`/`k`/`l` |
| Resize pane | `prefix` + `H`/`J`/`K`/`L` (repeatable) |
| Zoom pane | `prefix` + `z` |
| Copy mode | `prefix` + `Enter` |
| Start selection | `v` (in copy mode) |
| Copy selection | `y` (in copy mode) |
| Paste | `prefix` + `P` |
| Reload config | `prefix` + `r` |

## Neovim

Leader: **`<Space>`**; local leader: **`,`**

`(` and `)` stand in for Vim's `[` and `]` prefixes: `(b` / `)b` previous and
next buffer, `(d` / `)d` diagnostic, `(h` / `)h` Git hunk, `(q` / `)q`
quickfix entry. The sentence motions that `(` and `)` had are gone.

`~/.config/nvim` contains the single managed LazyVim-based profile.
See [editor provisioning](EDITORS.md) for language-tool prerequisites.

### LazyVim

| Action | Keys |
|---|---|
| Save | `Ctrl-s` |
| Find files | `<leader>` + `ff` |
| Live grep | `<leader>` + `/` |
| Recent files | `<leader>` + `fr` |
| Buffers | `<leader>` + `,` |
| Switch buffer | `Shift-h` / `Shift-l` |
| Other buffer | `<leader>` + `bb` |
| Split right / below | `<leader>` + `wv` / `ws` |
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

### Neovim split navigation

These keys move between Neovim splits. Between tmux panes, use the prefix
followed by `h/j/k/l`, or add your preferred navigation plugin explicitly.

| Action | Keys |
|---|---|
| Move pane/split left | `Ctrl-h` |
| Move pane/split down | `Ctrl-j` |
| Move pane/split up | `Ctrl-k` |
| Move pane/split right | `Ctrl-l` |

## Kitty

| Action | Keys |
|---|---|
| New tab in the current directory | `Ctrl-Shift-t` |
| Close split or tab | `Ctrl-Shift-w` |
| Next / Previous tab | `Ctrl-Tab` / `Ctrl-Shift-Tab` |
| Split right | `Ctrl-Shift-d` |
| Split down | `Ctrl-Shift-e` |
| Navigate splits | `Ctrl-Alt-arrows` |
| Zoom a split (cycle to the stack layout) | `Ctrl-Shift-l` |
| Clear screen and scrollback | `Ctrl-Shift-k` |
| Font size + / - / reset | `Ctrl-+` / `Ctrl--` / `Ctrl-Shift-Backspace` |
| Open a URL on screen (Fedora) | `Ctrl-Shift-p`, then `u` |
| Pick a path / line / word / hash on screen | `Ctrl-Shift-p`, then `f` / `l` / `w` / `h` |

## LazyGit

`~/.config/lazygit/config.yml` moves the actions whose default key is a
bracket, a brace, `@` or a backtick.

| Action | Keys |
|---|---|
| Previous / next panel | `h` / `l`, or `Tab` |
| Previous / next tab of a panel | `(` / `)` |
| More / less context around a diff | `Ctrl-a` / `Ctrl-x` |
| Raise / lower the rename similarity threshold | `!` / `;` |
| Command log menu | `Ctrl-g` |
| Files as a tree or a flat list | `Ctrl-v` |
| All keys of the current panel | `?` |

## yazi (Fedora)

| Action | Keys |
|---|---|
| New tab | `t` |
| Previous / next tab | `Alt-h` / `Alt-l` |
| Move the tab left / right | `Alt-Shift-h` / `Alt-Shift-l` |
| Help | `F1` |

## Shell (Zsh)

| Action | Keys |
|---|---|
| Fuzzy file search, with bat preview | `Ctrl-t` (fzf) |
| Fuzzy cd into dir, with tree preview | `Alt-c` (fzf) |
| Hide or show the fzf preview | `Alt-p` |
| History search | `Ctrl-r` (fzf) |
| Accept autosuggestion | `→` (right arrow) or `End` |
| Move back / forward one word | `Ctrl-←` / `Ctrl-→`, `Alt-←` / `Alt-→`, `Alt-b` / `Alt-f` |
| Completion in fzf, with preview (Fedora) | `Tab` (fzf-tab) |
| Previous / next completion group | `<` / `>` |
| Cheat sheets (Fedora) | `Ctrl-g` (navi) |

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
