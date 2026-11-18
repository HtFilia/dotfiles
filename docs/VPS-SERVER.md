# Debian VPS

Dotfiles owns the portable user shell, editor, Git, SSH client, tmux, tools,
their packages, and the optional Debian 13 base policy for APT,
journal retention and administrator journal access. A separate, private
infrastructure repository owns everything else on the host: the SSH daemon,
networking, the firewall and the application services. Neither repository
contains credentials or host keys.

## New Debian 13 VPS

First create a regular sudo-capable account, authorize its SSH key, and confirm
an independent provider-console login. Keep that SSH session open during host
network changes. Then, as that account, follow the
[Debian install](../README.md#debian-13-work-workstation-and-vps) and answer
`server` and `perso`. Afterwards run `chsh -s "$(command -v zsh)"` and
`scripts/verify.sh` from `chezmoi cd`.

The server toolset is Zsh/Starship, navigation and search tools, Git/delta/
LazyGit, tmux, Neovim, Node, ncdu, htop, tealdeer, ShellCheck,
gitleaks, actionlint and Kitty terminfo. It installs no fonts, desktop
applications or containers. Neovim gets the Python and shell language servers
([editors](EDITORS.md#language-servers)).

Answer `systemBaseline` with `true` to apply the system baseline described
below. It does not manage SSH, networking, the firewall or application services.

chezmoi keeps local identities and SSH hosts in `.gitconfig`,
`.gitconfig.local` and `.ssh/config.local` untouched. Server files are independent copies, so a Git
pull alone does not activate new configuration.

## Changes and recovery

A daily user timer, `dotfiles-update.timer`, pulls this repository and applies
its file changes (`chezmoi update --exclude=scripts`). It never runs the
scripts, which need sudo, and it stops instead of overwriting a managed file
that was edited on the server. `sudo loginctl enable-linger $USER` lets it run
without an open session; `journalctl --user -u dotfiles-update` shows its runs.

```sh
sudo apt update && sudo apt upgrade   # packages
chezmoi diff                          # preview configuration changes
just vps-update                       # from `chezmoi cd`: pull, apply, run changed scripts with sudo, verify
```

Pinned binaries (chezmoi, Neovim, actionlint) change when their entry in
`home/.chezmoiexternal.toml.tmpl` changes.

Application and security provisioning follows the infrastructure
repository's documentation after user setup. The dotfiles install requires a
working sudo account; it clones over HTTPS and needs no GitHub key.

## System baseline

With `systemBaseline = true`, `run_onchange_after_30-debian-baseline.sh`
installs `unattended-upgrades` and `logrotate` when absent, enables their
timers and the daily APT refresh, restricts unattended upgrades to Debian
origins without automatic reboot, keeps a persistent journal limited to 500 MB,
1 GB free and 30 days, and adds the administrator to `systemd-journal`. Sign
in again before reading system logs. Caddy and other third-party software
update manually.

The policy files live in `home/.system/debian/`, which chezmoi reads but never
deploys into `$HOME`. Editing one changes the script, so the next
`chezmoi apply` installs it again; `scripts/verify.sh` compares the installed
files with the repository. Files replaced by the script are copied first to
`/var/backups/dotfiles-system/baseline.*`. Setting `systemBaseline = false`
stops further changes; it does not undo the baseline.

To roll back, restore the files saved in that backup directory to
`/etc/apt/apt.conf.d/` or `/etc/systemd/journald.conf.d/`, delete a managed
file that the backup does not contain (`20auto-upgrades`,
`52dotfiles-unattended`, `20-dotfiles-retention.conf`), check `apt-config dump`,
restart `systemd-journald` and flush the journal. Remove only the
supplementary group with `sudo gpasswd -d ACCOUNT systemd-journal` if the
baseline added it. Installed packages can stay.

Debian package versions follow the Debian mirrors.
