# Kitty and tmux

Kitty is the terminal on the three workstations; tmux runs sessions on every
machine, including the VPS. Kitty owns fonts, rendering, tabs and local splits.
tmux owns sessions, panes and processes that must survive a disconnect.

## Kitty

`~/.config/kitty/kitty.conf` sets Fira Code 12 with stylistic set 1, the
Melange palette, a 97 % opaque background blurred on KDE Plasma,
100 000 lines of scrollback, copy on select and shell integration. Kitty draws
Nerd Font symbols from its bundled font, so no patched font is installed;
`symbol_map` pins the icon codepoints to it, so that no other installed font
covering them (Jomolhari on Fedora) draws an icon instead. A
fontconfig file makes that bundled font available to other applications.
VS Code uses
it after Fira Code, so Starship and eza icons render in its terminal too.

Splits use the `splits` layout: `Ctrl-Shift-d` splits right, `Ctrl-Shift-e`
splits down and `Ctrl-Alt-arrows` move between splits. New tabs keep the
current directory. The full list is in [keybindings](KEYBINDINGS.md).

Kitty always starts zsh. A desktop session started before `chsh`
keeps `SHELL=/bin/bash` until the next login, and Kitty would otherwise open
bash, without the zsh prompt, aliases or helpers.

Machine-specific settings, such as a font size for one screen, go in
`~/.config/kitty/kitty.d/*.conf`, which Kitty loads last.

## Remote hosts

Programs on a remote host need the `xterm-kitty` terminfo entry. The VPS
installs Debian's `kitty-terminfo` package. For another host, install that
package there or connect once with `kitten ssh HOST`, which copies the entry.

## Kittens (Fedora)

On Fedora, zsh inside Kitty (not inside tmux) has three aliases: `s HOST`
runs `kitten ssh`, `icat FILE` shows an image in the terminal and `kd A B`
runs Kitty's side-by-side diff. `~/.config/kitty/ssh.conf` gives windows
connected with `kitten ssh` a red-tinted background
(`ssh-remote.conf`) until they disconnect, so a remote shell is obvious.
`Ctrl-Shift-p` then `u` labels the URLs on screen to open one; `f`, `l`, `w`
and `h` after the same prefix pick a path, line, word or hash, as in Kitty's
defaults. `Ctrl-Shift-e`, the default for URLs, opens a split here.

## tmux

Prefix and split keys are the defaults (Ctrl-b, `"` and `%`). New panes/windows use
the current pane's directory. Indices start at one, windows renumber, mouse and
focus events are enabled, and copy mode uses vi bindings.

The advertised terminal is `tmux-256color`; the `xterm-kitty` terminal features
provide true color, extended keys, styled underlines, hyperlinks and clipboard
access. `set-clipboard external` lets OSC 52 copy reach Kitty from a remote
server without X11 utilities.

Local bindings belong in `~/.tmux.conf.local`. No plugin manager, reboot
restoration plugins, or automatic attachment are part of the base.
`tm [NAME]` creates or attaches a session when you want one.
