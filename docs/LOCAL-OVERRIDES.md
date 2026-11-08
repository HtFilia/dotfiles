# Local overrides

Every setting belongs to one of three layers:

- **Common**: a plain file in `home/`, identical everywhere.
- **Context**: a template that varies with the profile, context, gaming answer
  or operating system.
- **Machine**: a local file that is not in this repository.

chezmoi never creates, changes or deletes a local file; the managed configs
include them only when they exist. `.gitignore` refuses them if one is ever
copied into the repository.

| Tool | Extension point | Local file |
|---|---|---|
| zsh | Sourced before the integrations, and at the end of `.zshrc` | `~/.zshrc.settings`, `~/.zshrc.local` |
| zsh (non-interactive) | Sourced at the end of `.zshenv` | `~/.zshenv.local` |
| Git | `[include]`, last in `.gitconfig` | `~/.gitconfig.local` |
| SSH | `Include` at the top; the first value wins | `~/.ssh/config.local` |
| tmux | `source-file -q`, last line | `~/.tmux.conf.local` |
| Kitty | `globinclude kitty.d/*.conf`, last line | `~/.config/kitty/kitty.d/*.conf` |
| Neovim | LazyVim imports all of `lua/plugins/`; `options.lua` ends with `pcall(require, "config.local")` | `lua/plugins/local.lua`, `lua/config/local.lua` |
| Starship, atuin, ripgrep | No include: point `STARSHIP_CONFIG`, `ATUIN_CONFIG_DIR` or `RIPGREP_CONFIG_PATH` at a copy, in `~/.zshrc.settings` | Your copy of the file |
| htop | `create_` prefix: deployed once, never overwritten | `~/.config/htop/htoprc` itself |
| VS Code | None | VS Code profiles, or the project's `.vscode/settings.json` |

`tests/overrides.sh` checks each row on every test machine.

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
export STARSHIP_CONFIG="$HOME/.config/starship.local.toml"

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
