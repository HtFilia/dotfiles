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

## Boot splash (Plymouth)

On the Fedora workstation the boot splash is Dusk Ridge: a plum-to-peach dusk
sky behind two ridges, a glow that rises as the system boots, a thin progress
line and twinkling stars. The script draws the scene once per monitor, each at
its own size, and updates every third frame to stay smooth without a GPU.

The sources are in `scripts/boot-art/` (`sky.svg`, `ridges.svg`, `glow.svg`);
`scripts/boot-art/build.sh` renders them at twice the design size to the PNGs
under `home/dot_local/share/boot-theme/plymouth/`, which are committed, so
`chezmoi apply` needs no image tools. Colours are the Dusk values carried by
hand, plus the sunset gradient. `chezmoi apply` deploys the files to
`~/.local/share/boot-theme/`, then
`run_onchange_after_65-plymouth-theme.sh.tmpl` installs the theme into
`/usr/share/plymouth/themes/dusk-ridge` with sudo, makes it the default and
rebuilds the initramfs (about a minute), then checks the theme is inside it.
It needs `plymouth-plugin-script`, which the package script installs. The
splash shows at the next boot. To go back to the stock splash, run
`sudo plymouth-set-default-theme -R bgrt`.

GRUB stays stock on purpose: a graphical GRUB theme on a 4K screen is either
soft (1080p mode) or very slow (native mode), a long-standing GRUB limitation
on UEFI, and the native console mode also leaves Plymouth the full 4K
framebuffer.

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
