# Dusk appearance

Dusk is the palette of Kitty, tmux, Starship, fzf, zsh suggestions and Neovim
(and, on Fedora, of yazi, navi, fastfetch and htop), and of the Plasma desktop
on Linux workstations: lavender and dusk rose, with sage, amber, sky and teal,
on a warm charcoal background, text at 11.9:1 against it. It is the night
half of the Alpenglow & Dusk palette, whose day half (Alpenglow) colours the
author's web apps; every text colour passes WCAG AA. There is no theme
switcher: the desktop stays dark.

Three files are generated from that palette and should not be edited by hand:
`home/dot_local/share/color-schemes/Dusk.colors` (Plasma),
`home/dot_config/kitty/dusk.conf` (Kitty) and
`home/dot_config/nvim/lua/dusk_palette.lua` (Neovim's base16 colours). tmux,
Starship, yazi, fzf, zsh suggestions and fastfetch carry the same hex values
in their own configuration files. VS Code and the syntax highlighting in bat
and delta keep Gruvbox Material.

## Plasma

`~/.local/share/color-schemes/Dusk.colors` is a KDE colour scheme in the same
palette: charcoal windows and lists, slightly lighter titlebars and toolbars,
a darker panel, and lavender for selection and focus. Plasma passes it on to
GTK applications. On a Linux workstation, `chezmoi apply` applies it to the
running Plasma session the first time and again whenever the file changes.
If apply ran outside Plasma, for example over SSH, choose Dusk in System
Settings > Colours & Themes > Colours. Choosing another scheme there is kept
until the managed scheme changes.

## Neovim

Neovim draws its colours with `mini.base16` from the sixteen base16 slots in
`lua/dusk_palette.lua`, so the editor matches the terminal around it.

## Fonts

Fira Code is the font everywhere. Nerd Font symbols come from the font bundled
with Kitty, shared with other applications through fontconfig; see [Kitty and tmux](TERMINALS.md). SSH
servers need no fonts.

## htop

htop uses its built-in Black Night scheme, a compact process list sorted by
CPU, CPU, memory and swap meters, and a 500 ms refresh. chezmoi deploys
`htoprc` once and never overwrites it, so settings saved with F2 stay on that
machine.
