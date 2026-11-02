# Migrating an existing machine

A one-time procedure for a machine set up with the former scripts
(`bootstrap.sh`, `apply-dotfiles.sh`, state under `~/.local/state/dotfiles`):
the VPS, which used independent files, and the Mac, which used symlinks into
the checkout. New machines follow the [README](../README.md#install) instead.

Set `old` to the former checkout first: `old=~/.dotfiles` on the Mac,
`old=~/dotfiles` on the VPS.

## 1. Back up

Save the contents of the formerly managed files, following symlinks, and the
old state directory:

```sh
backup=~/dotfiles-backup-$(date +%Y%m%d)
mkdir -p "$backup" && cd ~
for path in .zshrc .zshenv .tmux.conf .gitconfig .ssh/config .config/atuin .config/git \
    .config/htop .config/nvim .config/ripgrep .config/starship.toml .config/tealdeer \
    .config/fastfetch .config/ghostty .config/Code "Library/Application Support/Code/User" \
    .local/state/dotfiles; do
  [ -e "$path" ] && printf '%s\n' "$path"
done >"$backup/paths.txt"
tar -chzf "$backup/home.tar.gz" -T "$backup/paths.txt"
find ~ -maxdepth 6 -path "$old" -prune -o -type l -lname "$old/*" -print >"$backup/old-links.txt"
```

`old-links.txt` lists the symlinks that point into the checkout (Mac only).

## 2. Remove the old symlinks

chezmoi now deploys copies. Delete the links into the old checkout, including
the macOS VS Code `User` directory link, so that nothing writes into the
checkout:

```sh
while IFS= read -r link; do rm -- "$link"; done <"$backup/old-links.txt"
```

## 3. Turn the checkout into chezmoi's source

```sh
git -C "$old" status --short          # must print nothing
git -C "$old" remote set-url origin https://github.com/HtFilia/dotfiles.git
git -C "$old" switch master && git -C "$old" pull --ff-only
mkdir -p ~/.local/share && mv "$old" ~/.local/share/chezmoi
chezmoi init                          # answers: see below
chezmoi diff                          # review everything before applying
chezmoi apply
```

Answer `workstation` and `perso` on the Mac; `server`, `perso` and
`systemBaseline = true` on the VPS, whose baseline files already match. The
first apply installs the packages, replaces the old files with copies, and
deletes the former targets listed in `.chezmoiremove`: Ghostty and Windows
Terminal configs, the Ghostty terminfo entries, retired styles, the
`dotfiles-update` and `UPDATE` commands and, on Debian, the old binaries in
`~/.local/bin` that apt now provides. On the VPS, chezmoi also replaces its
own binary and re-points `~/.local/bin/nvim`.

`~/.gitconfig.local` and `~/.ssh/config.local` stay as they were.

## 4. Delete what the old scripts left

After `scripts/verify.sh` (run from `chezmoi cd`) passes:

```sh
rm -rf ~/.local/state/dotfiles ~/.cache/dotfiles ~/.local/share/zsh/plugins
rm -rf ~/.local/opt/nvim-v* ~/.local/opt/go-* ~/.local/opt/node-*   # VPS
```

On the Mac, the repository no longer installs some casks and formulae; remove
those you do not use, for example:

```sh
brew uninstall --cask ghostty font-fira-code-nerd-font
brew uninstall mise yazi lazydocker broot ov ouch xcp czkawka pastel vivid dua-cli duf \
  jc jless hexyl tokei watchexec sd xh moreutils parallel zstd tree wget pnpm python@3.14
```

Once everything works, delete `$backup`. Its archive restores any former file
with `tar -xzf "$backup/home.tar.gz" -C ~ PATH`.
