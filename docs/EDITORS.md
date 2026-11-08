# Neovim and VS Code

## Neovim

The single profile uses a pinned LazyVim distribution and lazy.nvim manager.
`lazy-lock.json` records the plugin graph. On first start, `init.lua` clones
lazy.nvim and LazyVim at their pinned commits, then lazy.nvim installs every
other plugin at its locked commit. A drifted lazy.nvim checkout is refused;
review local changes and restore its pinned commit deliberately.

`:Lazy restore` returns to the lock. `:Lazy update` changes the plugins and the
deployed `lazy-lock.json`; `chezmoi diff` then shows the new lock, and
`chezmoi re-add ~/.config/nvim/lazy-lock.json` brings it into the repository
after review.

The active theme is Gruvbox Material. Mason tool installation and Treesitter
parser installation are not automatically requested during ordinary startup.
Configured servers enable only when their executable is available: Lua,
BasedPyright/Ruff, Go, Rust, TypeScript/JavaScript, Bash and clangd. On the
personal workstations the packages add a C++ compiler, CMake, Ninja, clangd
and a debugger (gdb);
`setup-editor.sh cpp` adds the C, C++ and CMake parsers.

### Explicit provisioning

Language servers come from Mason and are installed only on request. Node and
npm are installed on every machine, Go on the personal workstations, and
`python3-venv` plus a C compiler on the VPS. Selecting `python` requires
`python3` with virtual environment support, because Mason installs BasedPyright
and Ruff in isolated Python environments; Treesitter parsers need a C compiler.

```sh
setup="$(chezmoi source-path)/../scripts/setup-editor.sh"
"$setup" lua python go rust node shell
"$setup" python shell    # only the languages you use
```

The command restores locked plugins, refreshes Mason's registry, installs the
selected language servers/formatters, installs corresponding Treesitter parsers,
waits for completion, and reports failures. Packages already installed are
preserved. Mason package releases are resolved by its registry at setup time;
these are not covered by the Linux binary SHA256 manifest. Restart Neovim after
setup. Rust formatting/checking additionally relies on rustfmt/Clippy in the
selected Rust toolchain.

Language tools live under Neovim's data directory. Installing more languages
does not uninstall earlier tools. Project tools may take priority
according to the formatter/server configuration; inspect `:checkhealth`,
`:Mason`, and `<leader>cl` when diagnosing a project.

## VS Code

`settings.json` and `keybindings.json` are rendered from
`home/.chezmoitemplates/` into `~/.config/Code/User`. The repository installs
VS Code on Fedora; on the Debian work workstation it deploys the
settings only once `code` is on PATH. A setting changed in VS Code's UI changes
the deployed copy: `chezmoi diff` shows it, and you port it into the template
or keep it in a VS Code profile.

The extensions listed under `vscode` in `packages.yaml` are installed when the
list changes. The AI extension (Claude Code) is listed for the `perso`
context only; GitHub Copilot ships with VS Code and is not installed
separately. Extensions update through VS Code; repository-level telemetry
settings do not govern every extension's service behavior.

Python uses Ruff formatting and Pylance basic checking. Go uses goimports, Rust
uses rust-analyzer/Clippy. No global JavaScript/JSON/YAML/Markdown formatter is
selected. Choose formatting tools explicitly in projects that need them.
Prettier, Biome, and ESLint are not provisioned by this repository. Existing
extension/Mason installations are not uninstalled automatically.

Saving formats files; focus changes autosave. Code actions configured as
`explicit` are for explicit saves. Sync confirmation is enabled, and automatic
smart commits are disabled. Search includes lockfiles.
