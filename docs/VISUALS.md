# Operator terminal appearance

Operator is the single native theme for Starship, tmux and Kitty. Apply the
dotfiles, restart Zsh, and reload Kitty and tmux configuration. No style-selection command or generated override is needed.
Editors and Git syntax highlighting retain Gruvbox.

Fonts belong on the terminal client; SSH servers do not need fonts. Left Option
sends Alt on macOS while right Option remains available for accented characters.

## Upgrade

`chezmoi apply` deletes the old style files, saved choices, generated overrides
and CRT shader listed in `.chezmoiremove`.

## htop

The native htop config uses Black Night, a compact process list sorted by CPU,
CPU/memory/swap meters, and a 500 ms refresh interval. These settings are supported
by the [htop 3.2.2 settings parser](https://github.com/htop-dev/htop/blob/3.2.2/Settings.c)
and [color scheme definitions](https://github.com/htop-dev/htop/blob/3.2.2/CRT.h).
Adjust further with F2. chezmoi deploys `htoprc` once and never overwrites it,
so settings saved by htop stay on that machine.
