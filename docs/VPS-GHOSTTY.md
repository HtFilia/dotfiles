# VPS with Ghostty on macOS

The VPS produces the prompt and application output. Ghostty on the Mac renders
the font, palette, windows and keyboard events. Fonts installed on the VPS do not
change what you see over SSH.

## Server installation

Run as the regular account you use for SSH:

```bash
git clone https://github.com/HtFilia/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh --profile server --configure-shell --yes
./scripts/verify.sh --profile server
```

The server profile supports Debian/Ubuntu on x86_64. It installs Debian packages
for Zsh, tmux, fzf, zoxide, direnv, ripgrep, fd and bat, and checksum-pinned
releases of Starship, eza, delta, lazygit, Chezmoi, just and Neovim. Neovim lives in
a versioned directory under `~/.local/opt`. Desktop configurations are excluded.
Ghostty's v1.3.1 terminfo capabilities are vendored from upstream at an exact
commit and compiled with `tic` into `~/.terminfo`; this also covers distributions
whose ncurses package does not include the entry.
It installs neither a terminal GUI nor fonts, Docker or language runtimes, and
does not run a system upgrade. Existing uv, Node and other runtimes remain usable.
Optional atuin/mise are activated if already installed; atuin requires no cloud
account for local history. Use `--no-shell-plugins` to omit pinned Zsh plugins/TPM.

Administrative installs use sudo and may ask for your password. If an
administrator has already installed the required apt packages, run
`scripts/install-server.sh --skip-packages` for only the user tools, then install
plugins using `scripts/pinned-plugins.sh` and apply the server profile.

Apply subsequent changes with:

```bash
./scripts/apply-dotfiles.sh --profile server --dry-run
./scripts/apply-dotfiles.sh --profile server
```

The apply wrapper stores a tar backup of existing managed files in
`~/.local/state/dotfiles/backups/<timestamp>.<random>/targets.tar` before writing.
Bootstrap uses `--force` after making this backup, so the initial install does
not require answering individual file-conflict prompts. Git identity belongs in
`~/.gitconfig.local`; an existing file is preserved. Personal shell overrides
belong in `~/.zshrc.local` and tmux overrides in `~/.tmux.conf.local`.

Reconnect over SSH after changing the login shell, or run `exec zsh -l` in your
current terminal. The prompt should show `fibo` and the remote host, with a
Gruvbox palette, Git status and a two-line prompt.

## Mac installation

If this updated repository is on your Mac:

```bash
bash ~/.dotfiles/scripts/setup-mac-ghostty.sh
```

Alternatively copy the prepared bundle from this VPS (replace `YOUR_VPS` with
your usual SSH hostname, alias or address):

```bash
scp fibo@YOUR_VPS:~/.local/share/dotfiles/mac-ghostty.tar.gz ~/Downloads/
tar -xzf ~/Downloads/mac-ghostty.tar.gz -C ~/Downloads
bash ~/Downloads/mac-ghostty/setup-mac-ghostty.sh
```

The helper requires [Homebrew](https://brew.sh), installs the FiraCode Nerd Font
cask and installs/updates Ghostty. It validates the supplied configuration before
replacing files and saves previous Ghostty configs under
`~/.local/state/dotfiles/backups/ghostty-*`. It applies only terminal settings,
not the full workstation bootstrap. Quit and reopen Ghostty after installation
to refresh the font and shell integration, then reconnect to your VPS.

The canonical configuration is `~/.config/ghostty/config.ghostty` (or the
corresponding `$XDG_CONFIG_HOME` path). Compatibility includes cover older
`config` paths and macOS Application Support paths. The theme matches Starship,
tmux, bat, delta and Neovim. The font is `FiraCode Nerd Font Mono`, size 14.
Left Option acts as Alt for shell word movement and tmux shortcuts; right Option
keeps macOS character entry available. Set `macos-option-as-alt = false` if both
Option keys are needed for your keyboard layout.

`shell-integration-features` includes `ssh-env` and `ssh-terminfo`, available in
Ghostty 1.2+. These wrap interactive SSH to copy terminfo with a fallback on
other servers. They do not apply to scp, rsync or SSH launched by another program.
Avoid adding a permanent `TERM=xterm-256color` override for this VPS: its proper
Ghostty terminfo is installed. No SSH daemon configuration change is required
for the installed theme and color support.

## Check the connection

After reconnecting in Ghostty:

```bash
echo "$SHELL $TERM $COLORTERM"
infocmp -x xterm-ghostty >/dev/null
~/.dotfiles/scripts/verify.sh --profile server
ls
tmux new-session -A -s main
```

Outside tmux expect `TERM=xterm-ghostty`; inside tmux expect `tmux-256color`.
Both shells advertise `COLORTERM=truecolor`. tmux uses Ctrl-a as the prefix:
Ctrl-a followed by `|` or `-` splits panes; `h/j/k/l` selects panes; `d` detaches.
Ctrl-a then Enter enters copy mode, `v` begins selection and `y` copies. tmux's
OSC 52 clipboard sends that copy to Ghostty on the Mac without requiring X11 or
`xclip` on the VPS. Client clipboard permissions still apply. Zsh uses Ctrl-r for
history search (atuin when installed, fzf otherwise), Ctrl-t to find a file, and
Alt-c to find a directory. fzf and zoxide initialize automatically.

Missing glyphs mean the font must be installed/selected on the Mac. Run
`ghostty +list-fonts` there to confirm its family name. A future server lacking
Ghostty terminfo can be fixed from the Mac with the official manual method:

```bash
infocmp -x xterm-ghostty | ssh YOUR_SERVER -- tic -x -
```

## Rollback

Switch the VPS back to Bash with `chsh -s /bin/bash` and reconnect. To restore
preexisting files from a specific backup, inspect it first with
`tar -tf /path/to/targets.tar`. Archive entries may be symlinks. Move the current
managed targets aside before extracting the archive into `$HOME` so restoring
does not write through the current managed symlinks. Newly created configs that
were absent before installation are not in the backup; move those aside as well.
Installed packages do not need removal to restore the previous shell.

On the Mac, inspect the `ghostty-*` backup and copy the relevant `xdg-*` and
`macos-*` configs back to their original paths. Quit and reopen Ghostty.

## Sources checked on 2026-09-12

- [Ghostty configuration reference](https://ghostty.org/docs/config/reference)
- [Ghostty terminfo and SSH setup](https://ghostty.org/docs/help/terminfo)
- [Ghostty SSH integration and limitations](https://ghostty.org/docs/features/ssh)
- [tmux clipboard support](https://github.com/tmux/tmux/wiki/Clipboard)
- [Chezmoi managed files](https://www.chezmoi.io/reference/commands/managed/)

Asset pins were refreshed against upstream GitHub releases, Node's published
checksum inventory and Go's download metadata. Debian package versions follow
Debian's supported repository rather than replacing every package with upstream
builds. Neovim's existing plugin lock remains pinned, with LazyVim's default
alternative-theme dependency recorded to complete the lock; update it intentionally
after checking plugin compatibility rather than dropping the lock.
