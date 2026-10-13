# Host-specific tool guidance

The deployed guide is generated at `~/AGENTS.additional.md` from tools actually
available on that host. It includes custom executables in the conventional
Go, Rust and user-local binary directories without invoking unknown programs.
Register their purpose and usage in `~/.config/dotfiles/custom-tools.json`.

See `docs/TOOL-AUDIT.md` for the catalog audit and `docs/INSTALL-METHODS.md` for
selection, installation policy and guide generation. This repository reference
is not a claim that every catalog tool is installed on the current host.
