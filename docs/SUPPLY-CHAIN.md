# Supply chain

Every download either goes through a package manager that checks signatures,
or is pinned to a version and a SHA256 that chezmoi checks before use.
Nothing is piped from `curl` into a shell.

## Package sources

| Machine | Sources |
|---|---|
| Fedora | Fedora repositories (including navi, difftastic and procs); COPR `atim/starship`, `atim/lazygit`, `errornointernet/klassy` and `peterwu/rendezvous` (Bibata cursors); Microsoft's VS Code repository |
| Debian 13 | Official Debian repositories only: no added source, key or backports suite |

The Fedora package script downloads Microsoft's signing key, checks it
against the SHA256 pinned in the script, and only then imports it and enables
the repository with `gpgcheck=1`. [`packages.yaml`](../home/.chezmoidata/packages.yaml)
lists package names; versions follow the repositories.

## Pinned binaries

| Binary | Version | Machines | Reason |
|---|---|---|---|
| chezmoi | 2.73.3 | Debian | Not packaged in Debian 13 |
| Neovim | 0.12.6 | Debian | Debian ships 0.10.4; the pinned LazyVim needs 0.11.2 |
| uv, uvx | 0.13.6 | Debian workstation | Not packaged in Debian 13 |
| yq | 4.54.1 | Debian workstation | Debian's `yq` is a different tool |
| actionlint | 1.7.12 | Fedora, Debian | Packaged in neither |
| yazi, ya (and their zsh completions) | 26.9.1 | Fedora | Not packaged in Fedora 44 |
| gping | 1.21.0 | Fedora | Not packaged in Fedora 44 |
| fzf-tab (zsh plugin) | 1.3.0 | Fedora | Packaged nowhere; the tag's source archive |

Each entry in [`.chezmoiexternal.toml.tmpl`](../home/.chezmoiexternal.toml.tmpl)
has the release URL and the archive's SHA256; chezmoi refuses an archive whose
checksum differs. The README's Debian install pins the same chezmoi archive.

To upgrade one:

1. Download the new archive into an empty directory and run `sha256sum` on it.
2. Compare the result with the project's published checksums: chezmoi's
   `checksums.txt`, uv's `.sha256` file, yq's `checksums` file, actionlint's
   `checksums.txt`. Neovim, yazi and gping publish the digest in their GitHub
   release metadata (`gh release view TAG --json assets`). fzf-tab's source
   archive has no published digest: check the tag's commit on GitHub.
3. Change the version in the URL and the checksum together. For chezmoi, also
   update the version and hash in the README's Debian install.
4. Run `tests/container.sh debian-travail` and `tests/container.sh debian-server`,
   or `tests/container.sh fedora-perso` for a Fedora-only binary.

## Downloads managed elsewhere

- The stable Rust toolchain: rustup downloads it once and checks it against
  its release manifest.
- Neovim plugins: `init.lua` pins lazy.nvim and refuses a different checkout;
  `lazy-lock.json` pins every plugin commit. Mason language tools, installed
  only by `scripts/setup-editor.sh`, follow Mason's registry and are not pinned.
- VS Code extensions come from the marketplace and update through VS Code.

## Secrets

`tests/repo.sh` runs gitleaks over the whole history. `.gitleaks.toml` has two
narrow exceptions: a VS Code keyboard shortcut that looks like a key, and
SHA256 digests of old `keybindings.json` contents in a deleted file.
