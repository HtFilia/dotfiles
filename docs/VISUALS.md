# Operator terminal appearance

Operator is the single native theme for Starship, tmux, Ghostty, and the supplied
Windows Terminal scheme. Apply the dotfiles, restart Zsh, and reload Ghostty and
tmux configuration. No style-selection command or generated override is needed.
Editors and Git syntax highlighting retain Gruvbox.

Fonts belong on the terminal client. WSL uses fonts installed on Windows;
SSH servers do not need fonts. Left Option sends Alt on macOS while right Option
remains available for accented characters.

## Windows Terminal

The optional helper applies Operator to the named WSL profile and preserves
other profiles and font choices. It backs up settings first and requires JSON
without comments:

```sh
python3 scripts/setup-windows-terminal.py '/path/to/settings.json' --profile Debian
```

Windows settings are not modified by Linux bootstrap. Existing unrelated schemes
are left alone. Restore the helper's backup to undo its changes.

## Upgrade

Apply retires recognizable old style files, saved choices, generated overrides,
and the CRT shader after backing them up. Modified files are preserved and
reported for review. Native configs no longer load old style overrides.
