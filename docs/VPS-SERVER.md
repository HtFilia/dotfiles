# Debian VPS bootstrap and ownership

Dotfiles owns the portable user shell, editor, Git, SSH client, tmux, tools and
their installation scripts. The separate `homelab-infra` repository owns this
host's SSH daemon, UFW, Fail2ban, WireGuard, Caddy, application services, logs,
health checks and backups. Neither repository contains credentials or host keys.

## New Debian 13 VPS

First create a regular sudo-capable account, authorize its SSH key, and confirm
an independent provider-console login. Keep that SSH session open during host
network changes. Clone with an already working GitHub key:

```sh
git clone git@github.com:HtFilia/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh --profile server --configure-shell
./scripts/verify.sh --profile server
```

Review the profile, package and shell prompts before accepting them. The default
server toolset includes Zsh/Starship, navigation/search, Git/delta/LazyGit,
tmux, Neovim, local Atuin, ncdu, htop, tealdeer and Ghostty terminfo. It does
not install fonts, containers or language runtimes. To add only selected editor
languages, pass `--editor-languages python,shell` on bootstrap or run
`./scripts/setup-editor.sh python shell` after installing prerequisites.

The first `apply-dotfiles.sh` makes private snapshots of existing managed files.
It preserves local identities and SSH hosts in `.gitconfig.local` and
`.ssh/config.local`. Server files are independent copies, so a Git pull alone
does not activate new configuration.

## Changes and recovery

```sh
./scripts/update-tools.sh --profile server --dry-run
./scripts/apply-dotfiles.sh --profile server --dry-run
./scripts/update-dotfiles.sh
./scripts/verify.sh --profile server
```

Use `--skip-packages` for pinned user-tool updates without apt/sudo. The
configuration update command snapshots before pulling and applying. Review
`~/.local/state/dotfiles/backups/` and use `scripts/restore-dotfiles.sh` with a
trusted snapshot when needed. A previous `~/.dotfiles` checkout should be
reviewed manually before deletion; the saved `source` file identifies the active
checkout.

System provisioning follows `homelab-infra` documentation after user setup.
Its current offsite backup is intentionally deferred. Local database dumps and
dotfiles snapshots do not substitute for offsite recovery. Do not enable daily
Proton Drive backups until a backup, repository check and isolated restore have
all passed. Review service/backup health manually at least weekly.
