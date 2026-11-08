# SSH hosts and identities

The managed, private `~/.ssh/config` starts with `Include ~/.ssh/config.local`,
so hosts and identities for one machine come first and win, then defines
GitHub. chezmoi never touches `config.local` or any key.

## GitHub key

The key depends on the machine's context:

| Context | Key |
|---|---|
| `perso` | `~/.ssh/github` |
| `travail` | `~/.ssh/github_work` |

Protect the key with a passphrase. `AddKeysToAgent yes` adds it to the session
agent on first use, so the passphrase is asked once per session:

- Fedora KDE starts an agent and sets `SSH_AUTH_SOCK` for the session.
- Debian starts `ssh-agent` for graphical sessions through systemd.

```sh
ssh-keygen -t ed25519 -f ~/.ssh/github -C "github $(hostname)"
ssh -T git@github.com    # authenticates; GitHub offers no shell
```

Git clones and fetches GitHub repositories over HTTPS and pushes over SSH (see
[Git](GIT.md)), so a machine without a key can still clone, run
`chezmoi update` and install Neovim plugins.

## Other hosts and accounts

Put servers in `~/.ssh/config.local`:

```sshconfig
Host dev-vps
    HostName your-server.example
    User your-user
    IdentityFile ~/.ssh/id_ed25519_vps
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

A second GitHub account on the same machine uses a host alias there; see
[local overrides](LOCAL-OVERRIDES.md#ssh-a-second-github-account).

```sh
chmod 700 ~/.ssh && chmod 600 ~/.ssh/config.local
```

Host key verification keeps OpenSSH's defaults: check fingerprints of new or
changed servers through a trusted channel. Agent forwarding is not enabled.
Sessions opened from Kitty need the `xterm-kitty` terminfo entry on the server;
see [Kitty and tmux](TERMINALS.md#remote-hosts).
