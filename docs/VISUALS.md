# Melange appearance

Melange is the palette of Kitty, tmux, Starship, fzf and zsh suggestions (and,
on Fedora, of yazi, navi and fastfetch), and of the Plasma desktop on Linux
workstations: pastel earth tones (clay, amber, sage, teal, lavender, rose) on a warm cocoa
background, with text at 11.8:1 against it. The colours come from
[melange-nvim](https://github.com/savq/melange-nvim). Each tool keeps its
colours in its own configuration file; there is no theme switcher. Neovim,
VS Code, and the syntax highlighting in bat and delta keep Gruvbox Material.

## Plasma

`~/.local/share/color-schemes/MelangeDark.colors` is a KDE colour scheme in
the same palette: cocoa windows and lists, slightly lighter titlebars and
toolbars, a darker panel, and clay for selection and focus. Plasma passes it
on to GTK applications. On a Linux workstation, `chezmoi apply` applies it to
the running Plasma session the first time and again whenever the file
changes. If apply ran outside Plasma, for example over SSH, choose Melange
Dark in System Settings > Colours & Themes > Colours. Choosing another scheme
there is kept until the managed scheme changes.

## Fonts

Fira Code is the font everywhere. Nerd Font symbols come from the font bundled
with Kitty, shared with other applications through fontconfig; see [Kitty and tmux](TERMINALS.md). SSH
servers need no fonts.

## htop

htop uses its built-in Black Night scheme, a compact process list sorted by
CPU, CPU, memory and swap meters, and a 500 ms refresh. chezmoi deploys
`htoprc` once and never overwrites it, so settings saved with F2 stay on that
machine.
