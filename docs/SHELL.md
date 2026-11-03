# Zsh startup and customization

`.zshenv` adds `~/.local/bin`, Cargo binaries, and Go binaries using Zsh's
unique PATH array, then reads `~/.zshenv.local`. It runs no external commands
and prints nothing, so noninteractive SSH commands can locate user-installed
tools.

`.zshrc` is a chezmoi template rendered for each machine. It reads
`.zshrc.settings`, sets PATH (with Homebrew's prefix on macOS), pager, locale
and history, checks completion permissions with compinit, loads the plugins,
starts the integrations of installed tools, defines aliases and helpers, reads
`.zshrc.local` and finally loads syntax highlighting. Every integration is
guarded with `command -v`, so a machine that lacks a tool still gets a working
shell. uv completion is cached and regenerated when its executable changes.

## Plugins

zsh-autosuggestions and zsh-syntax-highlighting come from packages: under
`/usr/share` on Fedora and Debian, under Homebrew's `share` directory on macOS.
`.zshrc` sources a plugin only if the file and every parent directory belong
to root or to you and are not writable by group or others. If Homebrew's
directories are group-writable, `chmod -R go-w "$(brew --prefix)/share"`
fixes both the plugins and compinit's warning.

## Customize

Use `~/.zshrc.settings` for inputs needed during setup:

```zsh
export DOTFILES_ENABLE_COMMAND_OVERRIDES=1
```

Replacements that accept the original command's everyday arguments are always
on: `ls`/`tree` → eza, `cat` → bat, `vi`/`vim` → Neovim and `top` → htop; see
[aliases](ALIASES.md). The flag adds those whose arguments differ: `less` →
bat, `grep` → rg, `find` → fd, and `mkdir` → `mkdir -p`. Leave it unset if
that causes friction. `command NAME` or `\NAME` runs the original command, and
shell scripts do not inherit aliases.

Point `STARSHIP_CONFIG`, `RIPGREP_CONFIG_PATH` or `ATUIN_CONFIG_DIR` at a
local copy there to replace a managed configuration on one machine. Use
`~/.zshrc.local` for final aliases/environment changes and custom widgets.
Syntax highlighting loads after those widgets. Local files execute shell code;
keep them private and review copied content.

`reload` executes a fresh Zsh, rebuilding hooks once. Save active command-line
work before reloading. `zshconfig` and `nvimconfig` open their respective configs.

## Integrations

- Starship displays directory, Git status, runtimes and command duration.
- zoxide provides `z`/`zi`; interactive `cd` aliases to `z`.
- fzf supplies file/directory/history widgets; atuin takes Ctrl-r when installed.
- direnv loads approved `.envrc` files; inspect them before `direnv allow`.

`.zshrc` also sets `SHELL` to zsh when the desktop session still has the shell
from before `chsh`, so tmux, editors and other programs started from it open
zsh too.

## Claude Code

chezmoi writes `~/.claude/dotfiles-tools.md` for each machine: the tools that
are installed, how they are configured, and the aliases of the interactive
shell. It creates `~/.claude/CLAUDE.md` once, importing that file, and never
overwrites it; personal instructions for Claude go there.

Claude Code copies the aliases of the shell it starts from into the shell that
runs its commands, and sets `CLAUDECODE=1`. With that variable set, `.zshrc`
leaves out the aliases that replace standard commands (`ls`, `cat`, `cd`,
`fd`, `grep` and the opt-in ones), so Claude's commands behave as documented
upstream. A `cd` aliased to zoxide jumps to the most-used matching directory
when the path does not exist, and the next command would run there.

## History

History is shared between shells, includes timestamps, and ignores commands
beginning with a space. Do not place secrets directly in command arguments;
atuin and other integrations have their own history policies.
The managed Atuin configuration disables synchronization and update checks.
Ctrl-r returns the selected command to the prompt so you can edit it before
execution. History remains in Atuin's user data directory on each machine.

## Performance

Measure on your machine with `time zsh -lic exit` or a temporary `zprof` session.
First-start completion generation differs from warm startup. Measure Starship's
Git status in large repositories before removing useful prompt information.
Completion auditing stays enabled; caching is not a reason to skip permissions.
