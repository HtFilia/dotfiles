# Tools and their roles

The workstation supplies tools for common interactive tasks. Use the smaller
server profile when those tasks do not apply. Package installation is declared
in `Brewfile` and the Linux installer; this guide explains roles rather than
repeating every version pin.

| Tools | Purpose |
|---|---|
| Chezmoi, Bash scripts | Deploy configuration; install and maintain platform packages |
| Zsh, Starship | Interactive shell, completions, informative prompt |
| fzf, fd, ripgrep, zoxide | Select files/history, find names, search content, learn directories |
| eza, bat, delta | Listings, readable file content and Git diffs |
| tmux, Ghostty | Persistent terminal sessions; local terminal rendering |
| LazyGit, gh | Interactive Git operations; GitHub workflows |
| Yazi | Interactive file navigation with `yy` returning the selected directory |
| jq, yq, sd | Structured JSON/YAML processing; simple text substitutions |
| xh, curl, wget | Interactive HTTP requests and conventional downloads |
| dust, duf, hyperfine, tokei | Disk usage, filesystem overview, benchmarks, optional code counts |
| watchexec | Rerun commands when files change |
| uv, mise | Python project/tool environments; explicit project runtime selection |
| direnv, atuin | Approved per-project environment; contextual history when installed |
| Docker, Compose, Buildx, Colima, LazyDocker | Container CLI/plugins, macOS runtime, interactive inspection |
| ShellCheck, shfmt, Bats, actionlint, gitleaks | Shell quality, formatting/testing, workflow lint, secret detection |
| VS Code, Neovim | GUI and terminal editing; language tools provisioned explicitly |

Several tools intentionally overlap for different modes of use: bat versus a
pager, gh versus Git, and a GUI editor versus a remote terminal editor. Remove
packages from your personal manifest when you do not use that mode; no extra
abstraction is needed to justify keeping everything installed.

The base uses Gruvbox Material Dark for Ghostty/tmux/Starship/editor UI, and
built-in `gruvbox-dark` syntax themes for bat/delta. fzf shares matching colors.
Palette values remain local to their native configuration files so each is easy
to read and adjust.

New file utilities, graphical options and data helpers are detailed in
[the interactive workbooks](WORKBOOKS.md). See [visual profiles](VISUALS.md)
and [version/update policy](UPGRADES.md) for deployment and maintenance.
