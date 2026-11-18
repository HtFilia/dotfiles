# Local overrides

Every setting belongs to one of three layers:

- **Common**: a plain file in `home/`, identical everywhere.
- **Context**: a template that varies with the profile, context, gaming answer
  or operating system.
- **Machine**: a local file that is not in this repository.

chezmoi never creates, changes or deletes a local file. `.gitignore` refuses
them if one is ever copied into the repository. Every config this repository
deploys has a row below; `tests/repo.sh` fails when a new one does not.

There are three ways a local file takes effect:

- **Read by the tool**: the tool includes the local file itself, so a change
  applies the next time it starts.
- **Merged on apply**: the tool cannot read a second file, so `chezmoi apply`
  merges the local file into the deployed config
  (`home/.chezmoitemplates/local-merge`). Run `chezmoi apply` after editing
  it. Keys are merged deeply and the local value wins; a list set locally
  replaces the managed one, except where the table says otherwise. Without a
  local file the managed config is deployed unchanged. With one, the deployed
  file loses the managed comments and key order, and `chezmoi re-add` no
  longer applies to it.
- **The machine's own file**: chezmoi writes it once, or never, and leaves
  every later change alone.

| Tool | Local file | How |
|---|---|---|
| zsh | `~/.zshrc.settings` (read before `~/.zshrc`'s integrations), `~/.zshrc.local` (read last) | Read by the tool |
| zsh (non-interactive) | `~/.zshenv.local`, at the end of `~/.zshenv` | Read by the tool |
| Git | `~/.gitconfig.local`, included at the end of `~/.config/git/config`; `~/.gitconfig`, read after both, where `git config --global` writes | Read by the tool; `~/.gitconfig` is the machine's own file |
| SSH | `~/.ssh/config.local`, included at the top of `~/.ssh/config`: the first value wins | Read by the tool |
| tmux | `~/.tmux.conf.local`, the last line of `~/.tmux.conf` | Read by the tool |
| Kitty | `~/.config/kitty/kitty.d/*.conf`, the last line | Read by the tool |
| Neovim | `~/.config/nvim/lua/plugins/local.lua`, `~/.config/nvim/lua/config/local.lua` | Read by the tool |
| LazyGit | `~/.config/lazygit/config.local.yml`, through `LG_CONFIG_FILE` | Read by the tool, from a shell started after the file exists |
| fontconfig | any file in `~/.config/fontconfig/conf.d/` | Read by the tool |
| systemd user units (`~/.config/systemd/user`) | `systemctl --user edit UNIT` (a drop-in) | Read by the tool |
| Starship | `~/.config/starship.local.toml` | Merged on apply |
| ripgrep | `~/.config/ripgrep/config.local`: its flags follow the managed ones | Merged on apply |
| yazi | `~/.config/yazi/yazi.local.toml`, `theme.local.toml`, `keymap.local.toml`: local keymaps come before the managed ones | Merged on apply |
| navi | `~/.config/navi/config.local.yaml` | Merged on apply |
| tealdeer | `~/.config/tealdeer/config.local.toml` | Merged on apply |
| fastfetch | `~/.config/fastfetch/config.local.jsonc`: its `logo` and `modules` replace the managed ones as a whole; on Debian, where no fastfetch config is managed, it becomes the config | Merged on apply |
| VS Code | `~/.config/Code/User/settings.local.json`, `keybindings.local.json` | Merged on apply; keys and keybindings added in VS Code's UI stay |
| htop | `~/.config/htop/htoprc` itself | The machine's own file: deployed once |
| User folders | `~/.config/user-dirs.dirs`, `~/.config/user-dirs.conf` | None: the `~/files` layout is the same on every workstation |

`tests/overrides.sh` checks the rows on every test machine, and
`tests/local-merge.sh` checks each merged config.

## Examples

### Git: a work identity for work repositories

`~/.gitconfig.local`:

```ini
[user]
    name = Your Name
    email = you@personal.example
[includeIf "gitdir:~/code/work/"]
    path = ~/.gitconfig.work
```

`~/.gitconfig.work` then holds the work `user.email` and any signing key.

### SSH: a second GitHub account

The managed config sends `github.com` to the context's key (`~/.ssh/github`
or `~/.ssh/github_work`). For another account on the same machine, add an
alias in `~/.ssh/config.local`:

```sshconfig
Host github-other
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_other
    IdentitiesOnly yes
```

Clone with `git clone github-other:OWNER/REPO.git`.

### Kitty: a font size for one screen

`~/.config/kitty/kitty.d/screen.conf`:

```conf
font_size 16.0
```

### fastfetch: this machine's logo and modules

`~/.config/fastfetch/config.local.jsonc`, then `chezmoi apply`:

```jsonc
{
  "logo": { "source": "debian", "padding": { "right": 2 } },
  "modules": ["title", "os", "kernel", "memory", "disk"]
}
```

The managed display settings (colours, separators) stay.

### Starship: one module for this machine

`~/.config/starship.local.toml`, then `chezmoi apply`:

```toml
[hostname]
ssh_only = false
```

### VS Code: a setting for this machine

`~/.config/Code/User/settings.local.json`, then `chezmoi apply`:

```jsonc
{
  "editor.fontSize": 16,
  "http.proxy": "http://proxy.example:3128"
}
```

### Neovim: a plugin for this machine only

`~/.config/nvim/lua/plugins/local.lua`:

```lua
return {
  { "folke/zen-mode.nvim", cmd = "ZenMode" },
}
```

A plugin added this way is not in the managed `lazy-lock.json`; leave the lock
file's changes out of `chezmoi re-add`. Options go in `lua/config/local.lua`,
for example `vim.opt.colorcolumn = "100"`.

### zsh: an environment variable

`~/.zshrc.settings` runs before the integrations, `~/.zshrc.local` after them:

```zsh
# ~/.zshrc.settings
export DOTFILES_ENABLE_COMMAND_OVERRIDES=1

# ~/.zshrc.local
export PROJECTS="$HOME/code"
```

Variables needed by non-interactive commands, such as `ssh host cmd`, belong
in `~/.zshenv.local`.

## Rules

- Never put a secret in this repository, even in a template: it is public, and
  history keeps everything.
- Keep tokens in the desktop keyring and read them when needed, for example
  `secret-tool lookup service github account work` (libsecret).
- No employer information in the repository: no host names, domains, proxies,
  internal repositories or internal tools. The `travail` context carries
  generic differences only; everything specific lives in the local files above.
