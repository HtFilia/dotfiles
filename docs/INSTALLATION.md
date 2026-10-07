# Installation

This branch installs Debian 12/13 x86_64 workstations through existing authorized
APT and pinned GitHub assets. Start with [CORPORATE.md](CORPORATE.md) for host
preparation, administrator provisioning, flags, reviewed editor/VSIX inputs and
recovery. [AGENTS.md](../AGENTS.md) tracks infrastructure acceptance.

```sh
./scripts/corporate-preflight.sh
./scripts/bootstrap.sh --dry-run --skip-docker
./scripts/bootstrap.sh --yes --skip-packages --skip-docker
```

The last command assumes IT has installed `scripts/corporate-packages.sh`.
Otherwise omit `--skip-packages` to install from already configured APT sources.
Provide corporate Git identity before applying. Use a regular account.

Fonts, pinned Zsh plugins and configuration are supplied by default. VS Code,
Ghostty, language-tool provisioning, TPM and login-shell changes have separate
preparation or flags. WSL GUI/font/container integration belongs to the Windows
host. macOS/server/Ubuntu installation instructions are on personal `master`.
