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

## render-dotfiles.py: "machine.yaml not found"

The machine config hasn't been created yet. Run the renderer once interactively:

```bash
python3 ~/.dotfiles/scripts/render-dotfiles.py apply
# → prompts for name, email, machineType, hostname
# → saves to ~/.config/dotfiles/machine.yaml
```

## Dotfile symlink points to wrong file

Preview what will be linked before applying:

```bash
python3 ~/.dotfiles/scripts/render-dotfiles.py apply --dry-run
```

Force overwrite existing files:

```bash
python3 ~/.dotfiles/scripts/render-dotfiles.py apply --force
```

## I want to uninstall this setup on a machine

Remove the symlinks and the machine config:

```bash
# Remove symlinked dotfiles (the source files in the repo are untouched)
python3 ~/.dotfiles/scripts/render-dotfiles.py apply --dry-run  # review first
rm ~/.zshrc ~/.gitconfig ~/.tmux.conf   # remove whichever you want
rm ~/.config/dotfiles/machine.yaml      # remove machine config
```
