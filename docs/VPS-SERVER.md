# Debian VPS bootstrap and ownership

Dotfiles owns the portable user shell, editor, Git, SSH client, tmux, tools,
their installation scripts, and the optional Debian 13 base policy for APT,
journal retention and administrator journal access. The separate `homelab-infra`
repository owns this host's SSH daemon, UFW, Fail2ban, WireGuard, Caddy,
application services, health checks and backups. Neither repository contains
credentials or host keys.

## New Debian 13 VPS

First create a regular sudo-capable account, authorize its SSH key, and confirm
an independent provider-console login. Keep that SSH session open during host
network changes. Clone with an already working GitHub key:

```sh
git clone git@github.com:HtFilia/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh --profile server --editor-languages python,shell --system-baseline --dry-run
./scripts/bootstrap.sh --profile server --editor-languages python,shell --system-baseline --configure-shell
./scripts/verify.sh --profile server
```

Review the preview, package and shell prompts before accepting them. The default
server toolset includes Zsh/Starship, navigation/search, Git/delta/LazyGit,
tmux, Neovim, local Atuin, ncdu, htop, tealdeer and Ghostty terminfo. It does
not install fonts or containers. Editor languages remain optional; this host
selects Python and shell. To add selected editor languages later, pass their
comma-separated list on bootstrap or run
`./scripts/setup-editor.sh python shell` after installing prerequisites.

`--system-baseline` is explicit and Debian 13 only. It backs up existing APT and
journal settings under `/var/backups/dotfiles-system`, migrates the identical old
homelab journal drop-in, and adds the administrator to `systemd-journal`. Sign
in again before checking journal access. If existing settings differ, it stops
for review. It does not manage SSH, networking, the firewall or application services.

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

Application and security provisioning follows `homelab-infra` documentation
after user setup. The dotfiles bootstrap requires a working sudo account and
GitHub SSH access. The administrator identity, authorized keys, service secrets,
provider networking and backup destinations remain private inputs.
Its current offsite backup is intentionally deferred. Local database dumps and
dotfiles snapshots do not substitute for offsite recovery. Do not enable daily
Proton Drive backups until a backup, repository check and isolated restore have
all passed. Review service/backup health manually at least weekly.

## Baseline scope and rollback

The optional baseline installs `unattended-upgrades` and `logrotate` when absent,
enables their native timers plus daily APT refresh, restricts unattended upgrades
to Debian origins, and disables automatic reboot. Caddy and other third-party
updates stay manual. Journal policy is stored in `system/debian/`, separately
from the Chezmoi home tree.

An administrator running from a root console can use
`./scripts/server-baseline.sh --user ACCOUNT --dry-run` followed by `--apply`.
User configuration and tool installers should still run as that account.

For rollback, select the backup path printed by the baseline. Restore each
saved configuration to its original `/etc/apt/apt.conf.d/` or
`/etc/systemd/journald.conf.d/` location. Remove a new managed file only when it
was absent from that backup (the managed files are `20auto-upgrades`,
`52dotfiles-unattended`, and `20-dotfiles-retention.conf`). Restore the legacy
`20-homelab-retention.conf` if saved. Check `apt-config dump`, then restart
`systemd-journald` and flush the journal. Use `timers-before` to restore only
timer states changed by the baseline. If `systemd-journal` was absent from
`groups-before`, remove only that supplementary group with
`sudo gpasswd -d ACCOUNT systemd-journal`; never replace all account groups.
Delete the user's `~/.local/state/dotfiles/system-baseline` marker after rollback.
Installed Debian dependencies need not be removed for configuration rollback.

Pinned binaries and Neovim plugins are versioned in the repository. Debian
package patch versions follow the configured Debian mirrors. Explicit Mason
editor provisioning uses its current registry, so language-tool versions are
not fully locked; rerunning setup ensures presence without upgrading installed
Mason tools. Offsite backups remain a separate, deferred project.

## Email notification setup

Follow [OVH email activation](OVH-EMAIL.md) for the OVH Control Panel, mailbox
password, VPS configuration, phone delivery test and troubleshooting steps.
Notification code and private settings remain owned by `homelab-infra`.
