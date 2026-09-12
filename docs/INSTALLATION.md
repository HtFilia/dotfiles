# Installation

`bootstrap.sh` selects a profile, checks the platform, installs packages and
verified assets, installs optional plugins, applies configuration, installs
VS Code extensions when its CLI is available, and optionally changes the shell.
It does not run a system upgrade.

## Prerequisites

Clone `git@github.com:HtFilia/dotfiles.git` using your existing SSH credentials.
Use a regular account. Linux supports x86_64 Debian 12/13 and Ubuntu 24.04/26.04;
package installation needs sudo. macOS needs Homebrew and Command Line Tools.
Finish the graphical CLT installer before rerunning bootstrap.

The default target layout is `~/.config`, `~/.local`, `~/.ssh`, and macOS's native
VS Code settings directory. A custom `XDG_CONFIG_HOME` does not automatically
relocate Chezmoi's managed `.config` targets; use the conventional layout.

## Profiles and flags

| Flag | Effect |
|---|---|
| `--profile workstation` | Default: development packages and application configuration |
| `--profile server` | Linux SSH environment; desktop configurations excluded |
| `--yes` | Skip bootstrap confirmation prompts |
| `--configure-shell` | Permit `/etc/shells` registration and `chsh` |
| `--skip-docker` | Omit container packages on macOS/Linux |
| `--skip-fonts` | Omit font installation, including the macOS font cask |
| `--skip-vscode-extensions` | Omit extension installation |
| `--no-shell-plugins` | Omit Zsh plugin installation |
| `--with-tpm` | Install pinned TPM for explicitly selected tmux plugins |
| `--start-colima` | Start Colima and enable its Homebrew service |
| `--enable-docker-group` | Join Linux Docker group; root-equivalent access |
| `--setup-editor` | Explicitly download language servers, formatters and parsers |

Fonts live on the terminal client. WSL uses Windows-hosted terminal/fonts,
VS Code with Remote WSL, and optional Docker Desktop integration. macOS's
container runtime is Colima. Native Linux uses Docker's signed apt repository.
Docker daemon availability is separate from installed CLI/plugin checks.

## Repeatability and overrides

Rerun after interrupted installation. Download caches are keyed by asset and
version and validated before use. Neovim/Go/Node are staged in versioned
`~/.local/opt` directories, and launchers in `~/.local/bin` switch after staging.
Previous versions remain for rollback. Incomplete version directories cause an
explicit error rather than being silently reused.

`LOCAL_BIN` changes the direct-tool directory and is exported in bootstrap's
PATH. If you keep a custom location, add it to your persistent shell PATH too.
`DOTFILES_DOWNLOAD_DIR` changes the cache root. `DOTFILES_REPO` supplies the SSH
clone URL for the bootstrap fallback; an existing checkout is used directly.

`install-server.sh --skip-packages` assumes an administrator has already
installed its declared apt dependencies. It still compiles terminfo and installs
user-owned binaries. Apply afterward with `--profile server`.

Linux fonts/VS Code/Ghostty, assistant CLIs, and local atuin installation are
separate choices where they are not supplied by the profile's package manager.
