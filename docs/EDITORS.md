# Neovim and VS Code

## Neovim

The single profile uses a pinned LazyVim distribution and lazy.nvim manager.
`lazy-lock.json` records the plugin graph. A drifted lazy.nvim checkout is refused;
review local changes and restore its pinned commit deliberately. `:Lazy restore`
uses the lock; `:Lazy update` changes unpinned dependencies and the lockfile.
Review resulting changes before committing them.

The active theme is Gruvbox Material. Mason tool installation and Treesitter
parser installation are not automatically requested during ordinary startup.
Configured servers enable only when their executable is available: Lua,
BasedPyright/Ruff, Go, Rust, TypeScript/JavaScript, and Bash.

### Explicit provisioning

Install runtimes first. `bootstrap.sh --setup-editor` installs the pinned Go and
Node runtimes on both workstation and server profiles, plus the server's Python
virtual-environment and compiler prerequisites. Selecting `python` requires
`python3` with virtual environment support because the current Mason registry
installs BasedPyright and Ruff in isolated Python environments:

```sh
sudo apt install python3 python3-venv  # Debian/Ubuntu VPS
./scripts/setup-editor.sh lua python go rust node shell
# Select only languages you use:
./scripts/setup-editor.sh python shell
```

The command restores locked plugins, refreshes Mason's registry, installs the
selected language servers/formatters, installs corresponding Treesitter parsers,
waits for completion, and reports failures. Packages already installed are
preserved. Mason package releases are resolved by its registry at setup time;
these are not covered by the Linux binary SHA256 manifest. Restart Neovim after
setup. Rust formatting/checking additionally relies on rustfmt/Clippy in the
selected Rust toolchain.

Language tools live under Neovim's data directory. Selection markers under
`~/.local/state/dotfiles` let verification check expected tool binaries. Installing
more languages does not uninstall earlier tools. Project tools may take priority
according to the formatter/server configuration; inspect `:checkhealth`,
`:Mason`, and `<leader>cl` when diagnosing a project.

Without `--setup-editor`, server bootstrap keeps the SSH profile small and does
not download language runtimes or parsers. Run the explicit setup command after
installing any prerequisites yourself when you choose that mode.

## VS Code

Linux uses `~/.config/Code/User`; macOS uses
`~/Library/Application Support/Code/User`, pointing to the shared source User
directory. Source settings are JSONC, allowing comments. Windows-hosted VS Code
under WSL must import/copy these settings through Windows's User settings UI;
Linux deployment does not edit Windows `%APPDATA%`.

The extension manifest supplies themes, language tooling, formatting, remote
connections, and optional assistant interfaces. Extensions update through
VS Code. Assistant functionality may require accounts; repository-level telemetry
settings do not govern every extension's service behavior.

Python uses Ruff formatting and Pylance basic checking. Go uses goimports, Rust
uses rust-analyzer/Clippy. JSON/YAML/Markdown use Prettier. Select a JavaScript/
TypeScript formatter explicitly per workspace (Prettier, Biome, or ESLint) rather
than running overlapping fixes. Project configuration overrides personal defaults.

Saving formats files; focus changes autosave. Code actions configured as
`explicit` are for explicit saves. Sync confirmation is enabled, and automatic
smart commits are disabled. Search includes lockfiles.
