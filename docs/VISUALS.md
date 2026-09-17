# Terminal styles

The default style is **operator**: deep green graphite surfaces, teal structure,
blue repository context, and amber attention states. Its two-line prompt makes
the active project and repository state easy to scan, while tmux can hold a
shell, monitor, and system card together. **classic** restores the original
Gruvbox setup. **studio** is the quieter graphite profile; **neon** and **matrix**
remain available as legacy profiles.

```sh
dotfiles-style operator
exec zsh
dotfiles-style studio
exec zsh
dotfiles-style classic
exec zsh
dotfiles-style matrix
exec zsh
```

The style selector writes small local override files. It does not edit the
managed theme sources. Run it once after first deployment to initialize the
tmux and Ghostty overrides. New Zsh sessions read the selection. A running tmux
session can be refreshed with `Ctrl-a r`. Reload Ghostty's configuration through
its normal reload action. Nerd Font glyphs require a Nerd Font installed on the
machine rendering the terminal; WSL fonts belong on Windows.

## The workspace layout and optional effects

```sh
deck             # isolated tmux socket: shell, btop and system card
deck info        # fastfetch system card
deck rain        # decorative Matrix animation; q exits
deck spectrum    # cava audio spectrum; Ctrl-c exits
```

The workspace uses its own `dotfiles-deck` tmux socket and a three-pane layout:
the main pane is a normal shell, the lower-left pane is `btop`, and the
lower-right pane is a system card followed by a shell. The Operator status bar
stays at the top and labels the active pane, session, host and clock. Detach with
`Ctrl-a d`. It does not kill or rearrange other tmux sessions.

Resource displays contain real local information; digital rain is pure
decoration. Nothing launches at shell startup. Cava needs an audio input source
and may require host/audio configuration on WSL.

For optional subtle static CRT scan lines in Ghostty:

```sh
dotfiles-style operator --crt
```

Run the selector again without `--crt` to remove the effect. It uses a local
GLSL shader and disables its animation loop. Ghostty shaders are not Windows
Terminal shaders. The [Ghostty reference](https://ghostty.org/docs/config/reference)
documents shader and transparency support; blur depends on the platform/compositor.

## Windows Terminal on WSL

The repository includes four Windows Terminal color schemes in
`home/dot_config/dotfiles/windows-terminal.json`. The merge helper changes only
matching WSL profiles' appearance and the named Dotfiles schemes; it creates a
backup beside the settings file first. It requires valid JSON settings.

```sh
python3 scripts/setup-windows-terminal.py \
  '/mnt/c/Users/YOUR_NAME/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json' \
  --profile Debian --style operator
```

Add `--crt` for Windows Terminal's experimental retro effect. Omit it to disable
that effect. The helper accepts `operator`, `studio`, `neon`, and `matrix`; keep the existing
Windows Terminal scheme selected when you want a classic Gruvbox host palette.
The Linux style selector does not silently edit Windows settings. Alternatively,
merge the schemes manually and choose them under the profile's Appearance page.
See [Windows Terminal appearance settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance).

No existing font preference is replaced by the merge helper. To undo all host
changes, restore the helper's settings backup.
