# Debian VPS

Dotfiles owns the portable user shell, editor, Git, SSH client, tmux, tools,
their packages, and the optional Debian 13 base policy for APT,
journal retention and administrator journal access. The separate, private
`homelab-infra` repository owns this host's SSH daemon, UFW, Fail2ban, WireGuard, Caddy,
application services, health checks and backups. Neither repository contains
credentials or host keys.

## New Debian 13 VPS

First create a regular sudo-capable account, authorize its SSH key, and confirm
an independent provider-console login. Keep that SSH session open during host
network changes. Then, as that account, follow the
[Debian install](../README.md#debian-13-work-workstation-and-vps) and answer
`server` and `perso`. Afterwards run `chsh -s "$(command -v zsh)"` and
`scripts/verify.sh` from `chezmoi cd`.

The server toolset is Zsh/Starship, navigation and search tools, Git/delta/
LazyGit, tmux, Neovim, Node, local Atuin, ncdu, htop, tealdeer, ShellCheck,
gitleaks, actionlint and Kitty terminfo. It installs no fonts, desktop
applications or containers. Editor languages stay optional; this host uses
Python and shell: `"$(chezmoi source-path)/../scripts/setup-editor.sh" python shell`.

Answer `systemBaseline` with `true` to apply the system baseline described
below. It does not manage SSH, networking, the firewall or application services.

chezmoi keeps local identities and SSH hosts in `.gitconfig.local` and
`.ssh/config.local` untouched. Server files are independent copies, so a Git
pull alone does not activate new configuration.

## Changes and recovery

```sh
sudo apt update && sudo apt upgrade   # packages
chezmoi diff                          # preview configuration changes
chezmoi update                        # pull, apply, run changed package scripts
```

Pinned binaries (chezmoi, Neovim, actionlint) change when their entry in
`home/.chezmoiexternal.toml.tmpl` changes.

Application and security provisioning follows `homelab-infra` documentation
after user setup. The dotfiles install requires a working sudo account; it
clones over HTTPS and needs no GitHub key. The administrator identity, authorized keys, service secrets,
provider networking and backup destinations remain private inputs.
Its current offsite backup is intentionally deferred. Local database dumps and
local copies do not substitute for offsite recovery. Do not enable daily
Proton Drive backups until a backup, repository check and isolated restore have
all passed. Review service/backup health manually at least weekly.

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

Debian package versions follow the Debian mirrors. Mason language tools follow
Mason's registry, so they are not fully pinned. Offsite backups remain a
separate, deferred project.

## Email notification setup

Follow [OVH email activation](OVH-EMAIL.md) for the OVH Control Panel, mailbox
password, VPS configuration, phone delivery test and troubleshooting steps.
Notification code and private settings remain owned by `homelab-infra`.
