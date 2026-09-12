# Zsh startup and customization

`.zshenv` adds `~/.local/bin`, Cargo binaries, and Go binaries using Zsh's
unique PATH array. It runs no external commands and prints nothing, so
noninteractive SSH commands can locate user-installed tools.

`.zshrc` selects the platform using Zsh's built-in OS information and WSL's
inherited environment. It reads `.zshrc.settings`, establishes package-manager
paths, sets pager/history defaults, checks completion permissions with compinit,
loads trusted plugins, and initializes available tool integrations.

Homebrew's prefix is selected from its standard installed locations without
running brew on every startup. Node 24 and Homebrew Python paths are explicit.
uv completion is cached and regenerated when its executable changes.

## Customize

Use `~/.zshrc.settings` for inputs needed during setup:

```zsh
export DOTFILES_ENABLE_COMMAND_OVERRIDES=1
```

That flag enables interactive `cat`/`less` → bat, `grep` → rg, `find` → fd, and
`mkdir` → `mkdir -p`. Their argument semantics differ from the original commands;
leave it unset if that causes friction. Shell scripts do not inherit aliases.

Use `~/.zshrc.local` for final aliases/environment changes and custom widgets.
Syntax highlighting loads after those widgets. Local files execute shell code;
keep them private and review copied content.

`reload` executes a fresh Zsh, rebuilding hooks once. Save active command-line
work before reloading. `zshconfig` and `nvimconfig` open their respective configs.

## Integrations

- Starship displays directory, Git status, runtimes and command duration.
- zoxide provides `z`/`zi`; interactive `cd` aliases to `z`.
- fzf supplies file/directory/history widgets; atuin takes Ctrl-r when installed.
- direnv loads approved `.envrc` files; inspect them before `direnv allow`.
- mise selects project runtime versions when configured and trusted.

History is shared between shells, includes timestamps, and ignores commands
beginning with a space. Do not place secrets directly in command arguments;
atuin and other integrations have their own history policies.

Plugin entrypoints and their directory chains must be owned by the user and not
group/world writable. A pin records checkout intent; it does not replace trusting
upstream code or reviewing plugin updates.

## Performance

Measure on your machine with `time zsh -lic exit` or a temporary `zprof` session.
First-start completion generation differs from warm startup. Measure Starship's
Git status in large repositories before removing useful prompt information.
Completion auditing stays enabled; caching is not a reason to skip permissions.
