# 🔧 Troubleshooting

## Icons / symbols show as `□` or `?`

→ FiraCode Nerd Font isn't installed or isn't selected in your terminal.

- **macOS**: `brew install --cask font-fira-code-nerd-font`
- **Linux**: run `./scripts/install-fonts.sh`
- **WSL**: install [FiraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases) on the **Windows host** and set it in Windows Terminal / Ghostty.

Then configure your terminal to use `FiraCode Nerd Font`.

## Colors look wrong in tmux or Neovim

Ensure your terminal declares 24-bit color support. Inside tmux:

```bash
tmux info | grep Tc
# Should show: 241: Tc: (flag) true
```

If not, set `TERM=xterm-256color` outside tmux (your terminal), not inside.

## LazyVim shows errors on first launch

On the very first `nvim` run, LazyVim installs all its plugins. This can take a minute. Wait for it to finish, then quit and re-open.

If plugins fail to install:

```bash
nvim --headless "+Lazy! sync" +qa
```

Check `:checkhealth` for missing dependencies (node, python, go, rust).

## `zsh compinit: insecure directories`

```bash
compaudit | xargs chmod g-w,o-w
```

## Starship icons are missing

Same as the first issue — it's a Nerd Font problem. Make sure the terminal is using FiraCode Nerd Font (not plain FiraCode).

## tmux: can't resurrect session

```bash
# Inside tmux, run the install keybinding:
prefix + I
# Then save manually once:
prefix + Ctrl-s
```

## Debian: `eza` / `bat` / `fd` commands not found

Debian installs some tools under different names:

- `bat` → `batcat`
- `fd`  → `fdfind`

The installer creates symlinks in `~/.local/bin`. Make sure it's on your `$PATH`:

```bash
echo $PATH | tr ':' '\n' | grep -q "$HOME/.local/bin" || echo "Add ~/.local/bin to PATH"
```

## WSL: `pbcopy` / `pbpaste` not working

Check that Windows path interop is enabled:

```bash
cat /etc/wsl.conf
# Should contain:
# [interop]
# appendWindowsPath = true
```

If `clip.exe` isn't found, Windows `System32` isn't in your WSL `PATH`.

## WSL: clock drift after suspend

```bash
sudo hwclock -s
```

## chezmoi: "template data not found"

You haven't run `chezmoi init` yet, or your `~/.config/chezmoi/chezmoi.toml` is missing.

```bash
chezmoi init  # re-prompts and regenerates the config
```

## chezmoi diff shows changes I didn't make

Your destination file was edited directly, not through chezmoi. Either:

- Accept the current state back into the source: `chezmoi re-add ~/.zshrc`
- Overwrite with what's in the repo: `chezmoi apply --force`

## I want to uninstall a machine from this setup

chezmoi makes this clean:

```bash
chezmoi purge    # Removes source state and the chezmoi binary config
# Managed target files remain — remove them by hand if needed.
```
