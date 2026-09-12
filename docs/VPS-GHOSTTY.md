# A VPS accessed through Ghostty on macOS

The VPS runs shells/applications; the Mac renders fonts and colors. Installing
fonts on the VPS does not change SSH rendering.

## Server

As your regular SSH user on supported Debian/Ubuntu x86_64:

```sh
git clone git@github.com:HtFilia/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh --profile server --configure-shell --yes
./scripts/verify.sh --profile server
```

The profile installs shell/Git/navigation tools, tmux, pinned Neovim and Ghostty
terminfo. It omits desktop settings, fonts, Docker and runtimes. Neovim lives in
`~/.local/opt/nvim-VERSION`. Configuration materializes as independent files.
TPM and language provisioning are optional. The server's GitHub SSH key/account
must already be configured for cloning this repository.

## Mac client

With this repository already cloned on the Mac:

```sh
bash ~/.dotfiles/scripts/setup-mac-ghostty.sh
```

The helper requires Homebrew, installs Ghostty/FiraCode Nerd Font, validates the
configuration, and backs up existing terminal files. It configures only Ghostty,
not the full workstation. To use a standalone copied helper, copy its config
alongside it or supply `--config /path/to/config.ghostty`. There is no generated
server-side download bundle.

Quit/reopen Ghostty after installation and reconnect. Left Option sends Alt;
right Option retains character entry. Set `macos-option-as-alt = false` if both
Option keys are needed for your layout.

## Check rendering and terminal support

```sh
echo "$SHELL $TERM $COLORTERM"
infocmp -x xterm-ghostty >/dev/null
tmux new-session -A -s main
```

Expect `xterm-ghostty` outside tmux and `tmux-256color` inside. Both receive true
color support. Ghostty's interactive SSH integration supplies terminal environment
and terminfo where supported; scp/rsync and SSH launched by other applications
are separate. Do not permanently replace TERM with an unrelated terminal name.

OSC 52 lets tmux copying reach the Mac clipboard without X11 on the server.
Client clipboard permissions still apply. Missing glyphs are a client font issue;
use `ghostty +list-fonts` on the Mac. For a different server needing terminfo:

```sh
infocmp -x xterm-ghostty | ssh YOUR_SERVER -- tic -x -
```

See [SSH](SSH.md), [terminal bindings](KEYBINDINGS.md), and
[deployment recovery](DEPLOYMENT.md) for local host settings and rollback.
