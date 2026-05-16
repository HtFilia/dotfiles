# Troubleshooting

## Icons show as boxes or question marks

FiraCode Nerd Font is missing or not selected in the terminal.

- macOS: `brew install --cask font-fira-code-nerd-font`
- Linux: `./scripts/install-fonts.sh`
- WSL: install the font on the Windows host.

## Colors look wrong in tmux or Neovim

Check 24-bit color support inside tmux:

```bash
tmux info | grep Tc
```

Set `TERM=xterm-256color` outside tmux if needed.

## LazyVim fails on first launch

Full mode uses LazyVim and needs network access for plugin installation:

```bash
nvim --headless "+Lazy! sync" +qa
```

Restricted mode intentionally does not use LazyVim:

```bash
./scripts/apply-dotfiles.sh --mode restricted
```

## Offline asset checksum mismatch

Delete the bad file from `~/dotfiles-offline-assets/`, re-download it from the
exact URL in `scripts/offline-manifest.md`, and compare SHA256 before retrying.

## Debian command names differ

Debian installs:

- `bat` as `batcat`
- `fd` as `fdfind`

The installers create symlinks in `~/.local/bin`; ensure that directory is on
`PATH`.

## WSL clipboard aliases do not work

Check Windows interop:

```bash
cat /etc/wsl.conf
```

Windows path interop must be enabled so `clip.exe` and `powershell.exe` are on
`PATH`.

## Git identity is missing

Create or edit `~/.gitconfig.local`:

```ini
[user]
    name = Your Name
    email = you@example.com
```

`~/.gitconfig` includes this file automatically.

## Preview or force dotfile deployment

```bash
./scripts/apply-dotfiles.sh --dry-run --mode full
./scripts/apply-dotfiles.sh --force --mode full
./scripts/apply-dotfiles.sh --mode restricted
```
