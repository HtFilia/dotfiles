# Migrating an existing machine

A one-time procedure for a machine set up with the former scripts
(`bootstrap.sh`, `apply-dotfiles.sh`, state under `~/.local/state/dotfiles`):
the VPS, which used independent files. New machines follow the [README](../README.md#install) instead.

Set `old` to the former checkout first: `old=~/dotfiles`.

## 1. Back up

Save the contents of the formerly managed files and the old state directory:

```sh
backup=~/dotfiles-backup-$(date +%Y%m%d)
mkdir -p "$backup" && cd ~
for path in .zshrc .zshenv .tmux.conf .gitconfig .ssh/config .config/atuin .config/git \
    .config/htop .config/nvim .config/ripgrep .config/starship.toml .config/tealdeer \
    .config/fastfetch .config/ghostty .config/Code .local/state/dotfiles; do
  [ -e "$path" ] && printf '%s\n' "$path"
done >"$backup/paths.txt"
tar -chzf "$backup/home.tar.gz" -T "$backup/paths.txt"
```

## 2. Turn the checkout into chezmoi's source

```sh
git -C "$old" status --short          # must print nothing
git -C "$old" remote set-url origin https://github.com/HtFilia/dotfiles.git
git -C "$old" switch master && git -C "$old" pull --ff-only
mkdir -p ~/.local/share && mv "$old" ~/.local/share/chezmoi
chezmoi init                          # answers: see below
chezmoi diff                          # review everything before applying
chezmoi apply
```

Answer `server`, `perso` and `systemBaseline = true`: the VPS's baseline
files already match. The
first apply installs the packages, replaces the old files with copies, and
deletes the former targets listed in `.chezmoiremove`: Ghostty and Windows
Terminal configs, the Ghostty terminfo entries, retired styles, the
`dotfiles-update` and `UPDATE` commands and the old binaries in
`~/.local/bin` that apt now provides. chezmoi also replaces its own binary and re-points `~/.local/bin/nvim`.

`~/.gitconfig.local` and `~/.ssh/config.local` stay as they were.

## 3. Delete what the old scripts left

After `scripts/verify.sh` (run from `chezmoi cd`) passes:

```sh
rm -rf ~/.local/state/dotfiles ~/.cache/dotfiles ~/.local/share/zsh/plugins
rm -rf ~/.local/opt/nvim-v* ~/.local/opt/go-* ~/.local/opt/node-*
```

Once everything works, delete `$backup`. Its archive restores any former file
with `tar -xzf "$backup/home.tar.gz" -C ~ PATH`.
