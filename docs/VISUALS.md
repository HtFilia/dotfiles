# Operator appearance

Operator is the palette of Kitty, tmux, Starship, fzf and the MangoHud overlay.
Each tool keeps its colours in its own configuration file; there is no theme
switcher. Neovim, VS Code, and the syntax highlighting in bat and delta keep
Gruvbox Material.

Fira Code is the font everywhere. Nerd Font symbols come from the font bundled
with Kitty, shared with other applications on Linux through fontconfig and
installed from Homebrew on macOS; see [Kitty and tmux](TERMINALS.md). SSH
servers need no fonts.

htop uses its built-in Black Night scheme, a compact process list sorted by
CPU, CPU, memory and swap meters, and a 500 ms refresh. chezmoi deploys
`htoprc` once and never overwrites it, so settings saved with F2 stay on that
machine.
