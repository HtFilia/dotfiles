# Workstation tool audit

The recommendation is based on this repository and a development/quant/SSH workflow, not a measured personal usage history. Only deployment prerequisites are universally required. Practical defaults deliberately omit project runtimes, overlapping interfaces and visual extras. Existing tools are not uninstalled.

The **recommended** preset contains 13 catalog entries on Linux: four locked prerequisites and nine practical tools. Project/compiler/editor, shell comfort, specialist and visual categories are all opt-in. macOS filters this list through the available catalog/platform selection.

| Tool | Decision | Purpose | Reason |
|---|---|---|---|
| atuin | comfort | Contextual shell history | Optional history database and integration; local history already exists. |
| delta | comfort | Readable Git diffs | Comfort; ordinary Git diffs already work. |
| direnv | comfort | Project environment loading | Choose for projects with reviewed environment scripts. |
| eza | comfort | Enhanced directory listings | Comfort; avoid making formatted listings mandatory. |
| lazygit | comfort | Interactive Git UI | Choose if a terminal Git UI is part of daily work. |
| mise | comfort | Project runtime selection | Choose for multi-runtime projects; avoid duplicating runtime ownership. |
| starship | comfort | Prompt decoration | Comfort, not a bootstrap requirement. |
| tldr | comfort | Short command examples | Optional help cache; offline population adds onboarding work. |
| yazi | comfort | Interactive file manager | Choose one file manager, rather than installing every file TUI. |
| zoxide | comfort | Learned directory navigation | Comfort for interactive navigation. |
| actionlint | project | Workflow validation | Useful for GitHub Actions maintainers. |
| bats | project | Shell test runner | Only needed when a project uses this test framework. |
| biome | project | JavaScript formatting/linting | Select for projects configured to use it. |
| cargo | project | Rust package/build tool | Pair with a Rust compiler when needed; avoid duplicate toolchains. |
| cargo-clippy | project | Rust linting | Rust-project component; requires a configured toolchain. |
| code | project | GUI editor | Select only if this is the editor used on the host. |
| colima | project | macOS container runtime | Needed only for the chosen macOS container setup. |
| docker | project | Container engine/CLI | Select only for actual container workflows; installing it changes service ownership. |
| docker-buildx | project | Container image builder | Only useful for image-building workflows. |
| docker-compose | project | Container stack CLI | Only useful with a container stack workflow. |
| font-fira-code-nerd-font | project | Decorative terminal font | Font aesthetics and icon support; not essential for command execution. |
| gh | project | GitHub workflows | Useful when GitHub workflows are needed; Git alone handles version control. |
| ghostty | project | Terminal emulator | Choose one terminal; not an SSH host prerequisite. |
| gitleaks | project | Secret scanning | Useful security check; redacted output only. |
| go | project | Go compiler and runtime | Install for Go development or chosen source builds; not for prebuilt Go tools. |
| hyperfine | project | Command benchmarking | High value for performance work, not for routine onboarding. |
| just | project | Project task runner | Useful for repositories with a task file; no need globally for every machine. |
| lazydocker | project | Interactive container UI | Convenience on top of a working container setup. |
| node | project | JavaScript runtime | Install for Node projects or selected package tools. |
| nvim | project | Terminal editor | Choose an editor; provisioning plugins/language tools is a separate opt-in. |
| pnpm | project | JavaScript package manager | Select only when a project uses this package manager. |
| rustc | project | Rust compiler | Install for Rust projects/builds; prebuilt Rust tools do not require a compiler. |
| rustfmt | project | Rust formatting | Rust-project component, not a generic Unix requirement. |
| rustup | project | Rust toolchain bootstrap | macOS toolchain provisioner; choose this or a distro-owned compiler. |
| shfmt | project | Shell formatting | Useful shell-maintenance extra. |
| tokei | project | Code statistics | Occasional inventory; compiling it is not worth default bootstrap cost. |
| watchexec | project | File-change command runner | Select for a concrete watcher workflow; no background watcher by default. |
| bat | recommended | Readable file output | Useful bounded previews; standard text commands still work. |
| fd | recommended | File-name search | Complements content search; convenient interactive file discovery. |
| fzf | recommended | Interactive selection | Useful for shell file/history selection; agents should avoid interactive prompts. |
| jq | recommended | JSON processing | Useful for structured output and API responses. |
| rg | recommended | Content search | High value for repository inspection and agent work. |
| shellcheck | recommended | Shell static analysis | Useful maintenance check for the bootstrap itself. |
| tmux | recommended | Persistent terminal sessions | High value for development and SSH; one terminal multiplexer is enough. |
| uv | recommended | Python project environments | Strong fit for a Python/quant workstation; only selected runtime manager in the lean preset. |
| zsh | recommended | Configured interactive shell | Useful because these dotfiles configure this shell. |
| chezmoi | required | Configuration deployment | Required to deploy and track the dotfiles. |
| curl | required | HTTPS downloads | Required download transport; avoid adding another downloader by default. |
| git | required | Version control | Required for configuration deployment and source retrieval. |
| python3 | required | Installer and report runtime | Required by the installer, inventory and deployment helpers. |
| 7z | specialist | 7-Zip archive utility | Select for formats requiring it; avoid a full archive stack by default. |
| broot | specialist | Interactive tree navigator | Overlap with file managers and file selection; choose one preferred workflow. |
| btop | specialist | Interactive resource monitor | Alternative to another monitor; choose one, not both. |
| czkawka_cli | specialist | Duplicate/media cleanup | Real specialist cleanup utility; review candidates before deleting anything. |
| dua | specialist | Directory usage explorer | Overlap with directory-size utilities; choose when its interactive workflow is needed. |
| duf | specialist | Filesystem capacity overview | Readable capacity display; standard diagnostics already exist. |
| dust | specialist | Directory size overview | Useful disk investigation; choose one directory-size tool. |
| ffmpeg | specialist | Media conversion | Large specialist media dependency; select for a media workflow. |
| hexyl | specialist | Hexadecimal file inspection | Specialist binary-data debugging. |
| htop | specialist | Interactive process monitor | Choose one interactive process monitor. |
| jc | specialist | Unix output parsing | Useful when automating unstructured command output, not for every shell session. |
| jless | specialist | Interactive JSON viewer | Overlap with structured queries and the editor; optional TUI. |
| ouch | specialist | Archive interface | Convenience wrapper over archive operations; optional. |
| ov | specialist | Interactive pager | Alternative pager; do not add several pagers by default. |
| parallel | specialist | Parallel command batches | Useful for intentional batch jobs, not as a default interactive dependency. |
| sd | specialist | Text replacement | Optional convenience over existing text processing; edits files. |
| sponge | specialist | Buffered Unix output helpers | Specialist package with file-writing helpers; do not probe it by executing an arbitrary option. |
| tree | specialist | Recursive directory listing | Optional listing convenience; avoid overlapping listing packages. |
| wget | specialist | Alternative downloader | Duplicates the download transport in the lean set. |
| xclip | specialist | X11 clipboard integration | X11-specific; not universal to WSL, Wayland or remote hosts. |
| xcp | specialist | Alternative copy utility | Optional copying interface; ordinary copies cover the lean workflow. |
| xh | specialist | Interactive HTTP client | Convenience HTTP interface; existing download transport can make requests. |
| yq | specialist | Structured YAML editing | Useful for YAML-heavy projects; this recipe targets the Go implementation. |
| zstd | specialist | Zstandard compression | Install when datasets/artifacts actually use this format. |
| cava | visual | Audio visualizer | Decorative gadget; excluded from every practical default. |
| chafa | visual | Terminal image rendering | Presentation/preview helper; not core development tooling. |
| cmatrix | visual | Terminal animation | Decorative gadget; excluded from every practical default. |
| fastfetch | visual | Decorative system summary | Visual convenience; existing system diagnostics cover operational inspection. |
| pastel | visual | Color inspection | Useful for color/design work; unnecessary for generic workstation setup. |
| viu | visual | Terminal image viewing | Overlaps terminal image rendering; choose only if actually used. |
| vivid | visual | Listing color theme | Visual customization, not an operational requirement. |

## Overlap and onboarding decisions

Choose one interactive process monitor; one file manager/navigation TUI; one preferred directory-size interface; and one editor. Prefer prebuilt tools before bringing in full Go/Rust compiler stacks just to install a CLI. Select package managers and formatters according to actual project configuration.

The visual category stays available for personal use but is never part of the recommended preset. Specialist tools can be very useful for a concrete job; calling them optional does not make them gadgets.

Primary references checked for specialist classifications: [jc](https://github.com/kellyjonbrazil/jc), [Czkawka CLI](https://github.com/qarmin/czkawka/blob/master/instructions/Instruction_CLI.md), [Fastfetch](https://github.com/fastfetch-cli/fastfetch). The catalog links the official repositories for the other tools.

Compiler/build prerequisites are provisioned only when source compilation or explicit editor provisioning is selected. Custom binaries receive no automatic “useful/gadget” judgment: describe the actual workflow in the custom-tool registry.
