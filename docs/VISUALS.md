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
in their own configuration files. bat and delta highlight syntax with the
terminal's ANSI colours (their `ansi` theme), so they follow Dusk too. VS Code
keeps Gruvbox Material.

## Plasma

`~/.local/share/color-schemes/Dusk.colors` is a KDE colour scheme in the same
palette: charcoal windows and lists, slightly lighter titlebars and toolbars,
a darker panel, and lavender for selection and focus. Plasma passes it on to
GTK applications. On a Linux workstation, `chezmoi apply` applies it to the
running Plasma session the first time and again whenever the file changes.
If apply ran outside Plasma, for example over SSH, choose Dusk in System
Settings > Colours & Themes > Colours. Choosing another scheme there is kept
until the managed scheme changes.

## Boot (GRUB and Plymouth)

On the Fedora workstation the boot loader menu and the boot splash share one
scene, Dusk Ridge: a plum-to-peach dusk sky behind two ridges. GRUB shows it
with a translucent menu panel on the right; Plymouth shows it with a glow that
rises as the system boots, a thin progress line and twinkling stars.

The sources are in `scripts/boot-art/` (`scene.svg`, `sky.svg`, `ridges.svg`,
`glow.svg`); `scripts/boot-art/build.sh` renders them to the PNGs under
`home/dot_local/share/boot-theme/`, which are committed, so `chezmoi apply`
needs no image tools. Colours are the Dusk values carried by hand, plus the
sunset gradient. `chezmoi apply` deploys the files to
`~/.local/share/boot-theme/`; two scripts then copy them with sudo:

- `run_onchange_after_60-grub-theme.sh.tmpl` installs the theme into
  `/boot/grub2/themes/dusk-ridge`, generates the Inter fonts, sets `gfxterm`,
  `GRUB_THEME` and a 1080p `GRUB_GFXMODE` in `/etc/default/grub`, and runs
  `grub2-mkconfig`.
- `run_onchange_after_65-plymouth-theme.sh.tmpl` installs the Plymouth theme
  into `/usr/share/plymouth/themes/dusk-ridge`, makes it the default and
  rebuilds the initramfs (about a minute), then checks the theme is inside it.
  It needs `plymouth-plugin-script`, which the package script installs.

Both show at the next boot. To go back to the stock look, remove the
`GRUB_THEME` line and set `GRUB_TERMINAL_OUTPUT="console"` in
`/etc/default/grub`, run `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`, and run
`sudo plymouth-set-default-theme -R bgrt`.

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
