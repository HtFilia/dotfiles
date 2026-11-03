# Kitty and tmux

Kitty is the terminal on the three workstations; tmux runs sessions on every
machine, including the VPS. Kitty owns fonts, rendering, tabs and local splits.
tmux owns sessions, panes and processes that must survive a disconnect.

## Kitty

`~/.config/kitty/kitty.conf` sets Fira Code 12 with stylistic set 1, the
Melange palette, a 97 % opaque background blurred on macOS and KDE Plasma,
100 000 lines of scrollback, copy on select and shell integration. Kitty draws
Nerd Font symbols from its bundled font, so no patched font is installed. On
Linux a fontconfig file makes that bundled font available to other
applications; macOS installs the same symbols font with Homebrew. VS Code uses
it after Fira Code, so Starship and eza icons render in its terminal too.

Splits use the `splits` layout: `Ctrl-Shift-d` splits right, `Ctrl-Shift-e`
splits down and `Ctrl-Alt-arrows` move between splits. New tabs keep the
current directory. Left Option acts as Alt on macOS; right Option still types
accented characters. The full list is in [keybindings](KEYBINDINGS.md).

Machine-specific settings, such as a font size for one screen, go in
`~/.config/kitty/kitty.d/*.conf`, which Kitty loads last.

## Remote hosts

Programs on a remote host need the `xterm-kitty` terminfo entry. The VPS
installs Debian's `kitty-terminfo` package. For another host, install that
package there or connect once with `kitten ssh HOST`, which copies the entry.

## tmux

Prefix is Ctrl-a; Ctrl-a Ctrl-a passes the prefix through. New panes/windows use
the current pane's directory. Indices start at one, windows renumber, mouse and
focus events are enabled, and copy mode uses vi bindings.

The advertised terminal is `tmux-256color`; the `xterm-kitty` terminal features
provide true color, extended keys, styled underlines, hyperlinks and clipboard
access. `set-clipboard external` lets OSC 52 copy reach Kitty from a remote
server without X11 utilities.

Local bindings belong in `~/.tmux.conf.local`. No plugin manager, reboot
restoration plugins, or automatic attachment are part of the base.
`tm [NAME]` creates or attaches a session when you want one.
