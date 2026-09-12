# SSH hosts and identities

The managed private `~/.ssh/config` includes `~/.ssh/config.local`. Keep actual
hostnames, user accounts, and key paths in that untracked local file. Apply backs up an existing config and copies its host entries into an absent
local include. When a local include already exists, merge any additional host
entries from the backup explicitly. Existing key files are not managed.

Example, adapted to your own key and host:

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes

Host dev-vps
  HostName your-server.example
  User your-user
  IdentityFile ~/.ssh/id_ed25519_vps
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3
```

```sh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config.local
ssh -T git@github.com
git remote -v
```

GitHub's authentication test reports successful authentication but does not offer
an interactive shell. Your repository uses
`git@github.com:HtFilia/dotfiles.git`; the update helper requires an SSH origin.
No global HTTPS-to-SSH rewrite is imposed on other repositories.

Host verification remains OpenSSH's default. Verify fingerprints through a
trusted channel for new or changed servers. Agent forwarding is not globally
enabled. Key generation, agents, passphrases, hardware keys, and server-daemon
policy remain choices of your existing account/OS setup.

Ghostty's integration and the server profile's vendored terminfo provide correct
terminal capabilities without weakening SSH settings. Fonts belong on the client;
see [VPS and Ghostty](VPS-GHOSTTY.md).
