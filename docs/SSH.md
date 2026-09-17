# SSH hosts and identities

The managed private `~/.ssh/config` defines GitHub explicitly and includes
`~/.ssh/config.local` for machine-specific hosts. GitHub uses `~/.ssh/github`
with `IdentitiesOnly yes` and `IdentityAgent none`, so Git can authenticate
without first adding that key to an SSH agent. Existing key files are not
managed.

Example, adapted to your own key and host:

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes
  IdentityAgent none
  AddKeysToAgent no

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
an interactive shell. Your repository uses `git@github.com:HtFilia/dotfiles.git`;
the update helper requires an SSH origin. Git rewrites GitHub HTTPS and git
protocol URLs to `git@github.com:` through the managed Git config, so new and
existing GitHub remotes use SSH automatically.

Host verification remains OpenSSH's default. Verify fingerprints through a
trusted channel for new or changed servers. Agent forwarding is not globally
enabled. Key generation, agents, passphrases, hardware keys, and server-daemon
policy remain choices of your existing account/OS setup.

Ghostty's integration and the server profile's vendored terminfo provide correct
terminal capabilities without weakening SSH settings. Fonts belong on the client;
see [VPS and Ghostty](VPS-GHOSTTY.md).
