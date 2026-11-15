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

The active theme is Dusk, drawn by `mini.base16` from `lua/dusk_palette.lua`
(see [Dusk appearance](VISUALS.md)).

### Language servers

Mason is disabled. `chezmoi apply` installs the servers with the tools each
machine already has, at the versions pinned under `editor` in
[`packages.yaml`](../home/.chezmoidata/packages.yaml), and Neovim starts a
server only where its binary is on PATH:

| Language | Server | Installed by | Machines |
|---|---|---|---|
| Python | Pyrefly (types, navigation), Ruff (lint, format) | `uv tool install` | all |
| Shell | bash-language-server, with ShellCheck and shfmt | `npm` into `~/.local` | all |
| TypeScript, JavaScript | typescript-language-server with TypeScript 6 | `npm` into `~/.local` | workstations |
| Rust | rust-analyzer | `rustup component add` | workstations |
| C, C++ | clangd | system package | personal Fedora workstation |

To change a version, edit the list and run `chezmoi apply`; `just outdated`
shows newer releases. Lua and Go servers (`lua-language-server`, `gopls`)
start too when you install them yourself. `<leader>cl` shows the servers
attached to a buffer, and `tests/editor.sh` checks that each one attaches.

On Fedora the same script builds the Treesitter parsers listed there. Debian
13 ships a `tree-sitter` CLI too old for nvim-treesitter, so those machines
keep Neovim's bundled parsers (C, Lua, Markdown, Vim) and regular syntax
highlighting for the rest.

## VS Code

`settings.json` and `keybindings.json` are deployed to `~/.config/Code/User`. The repository installs
VS Code on Fedora; on the Debian work workstation it deploys the
settings only once `code` is on PATH. A setting changed in VS Code's UI changes
the deployed copy: `chezmoi diff` shows it, and you `chezmoi re-add` it
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
extensions are not uninstalled automatically.

Saving formats files; focus changes autosave. Code actions configured as
`explicit` are for explicit saves. Sync confirmation is enabled, and automatic
smart commits are disabled. Search includes lockfiles.
