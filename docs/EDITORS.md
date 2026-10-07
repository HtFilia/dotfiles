# Neovim and VS Code

Neovim keeps pinned LazyVim/lazy.nvim, `lazy-lock.json`, Gruvbox Material and existing
keybindings. Mason is disabled on this branch. Blink completion uses its Lua matcher
and does not download a native library. Ordinary startup does not install missing
plugins or parsers; a missing manager reports the explicit setup command.

Prepare the exact selected tool closures described in
[CORPORATE.md](CORPORATE.md), then run:

```sh
./scripts/setup-editor.sh python shell
./scripts/verify.sh --profile workstation
```

The command validates every selected manifest, installs native tools into immutable
prefixes under `~/.local/opt/dotfiles-editor`, restores locked GitHub plugins and
installs/updates only selected parsers to pinned revisions. It records tools, parser
revisions and language selection only after parser success. Repeat setup reuses
matching prefixes. Runtime/compiler prerequisites come from APT and pinned GitHub
tree-sitter. Missing selected tools fail explicitly. Restart Neovim after setup;
check `:checkhealth` and `<leader>cl` for project-specific issues.

VS Code and its runtime tooling must be supplied through authorized channels.
Settings retain format-on-save and existing formatter choices. Automatic extension
updates, Git autofetch, schema downloads and TypeScript type acquisition are
disabled. Host-reviewed VSIXs install only through the explicit local manifest
path; dependency order, hashes and identities are checked. The original extension
ID list does not trigger Marketplace installation. Review runtime downloads and
assistant service access separately under AGENTS.md C09.

Linux settings live in `~/.config/Code/User`. WSL users must copy/import the settings
into Windows VS Code themselves; Linux deployment does not edit Windows files.
