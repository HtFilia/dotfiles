# Ghostty and tmux

Ghostty owns local fonts, rendering, tabs and splits. tmux owns sessions, panes,
working directories and persistent processes on the machine where it runs.
Use Ghostty splits for local presentation and tmux for remote/session persistence
according to your workflow; neither needs to duplicate every layout.

## Ghostty

The managed configuration uses FiraCode Nerd Font Mono, Gruvbox colors, a 64 MiB
scrollback limit, and process-aware close confirmation. Transparency/blur are
personal presentation settings; lower scrollback or disable blur if memory/GPU
use matters on your machine. Copy-on-select writes to the clipboard.

Shell integration provides cursor/title/path information and interactive SSH
terminal capabilities. Left Option acts as Alt on macOS; right Option remains
available for accented characters. Validate supported options with
`ghostty +validate-config`. The standalone Mac helper installs Ghostty/fonts and
backs up both link metadata and readable contents of existing configurations.

## tmux

Prefix is Ctrl-a; Ctrl-a Ctrl-a passes the prefix through. New panes/windows use
the current pane's directory. Indices start at one, windows renumber, mouse and
focus events are enabled, and copy mode uses vi bindings.

The advertised terminal is `tmux-256color`; Ghostty features provide true color,
extended keys and clipboard capabilities. `set-clipboard external` supports
OSC 52 copying to the terminal client without X11 utilities on a remote server.
Client clipboard permissions still apply.

TPM is optional (`bootstrap --with-tpm`). Add selected plugins to
`~/.tmux.conf.local` and use prefix I to install them. TPM updates can change
checkouts; review pin drift rather than assuming updates remain reproducible.
No reboot restoration plugins or automatic tmux attachment are part of the base.
`tm [NAME]` creates or attaches a session when you want one.

[Keybindings](KEYBINDINGS.md) lists the managed shortcuts;
[VPS setup](VPS-GHOSTTY.md) covers the client/server boundary.
