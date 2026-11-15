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

[`.chezmoiexternal.toml.tmpl`](../home/.chezmoiexternal.toml.tmpl) is the
list: each entry has a comment giving the machines and the reason, the
release URL and the archive's SHA256; chezmoi refuses an archive whose
checksum differs. The README's Debian install pins the same chezmoi archive.

`just outdated` lists the pins that are behind their project's latest
release. Dependabot proposes updates for the GitHub Actions only, since it
cannot compute these checksums. To upgrade one:

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
  `lazy-lock.json` pins every plugin commit, and with it the revision of
  each Treesitter parser.
- Neovim's language servers: PyPI (uv), npm and rustup install the versions
  pinned under `editor` in `packages.yaml`. Each registry checks its own
  package hashes; the repository pins versions, not hashes.
- VS Code extensions come from the marketplace and update through VS Code.

## Secrets

`chezmoi apply` enables `.githooks` in its own checkout (and nowhere else), so
gitleaks scans the staged changes before every commit to this repository.
`tests/repo.sh` runs gitleaks over the whole history. `.gitleaks.toml` has two
narrow exceptions: a VS Code keyboard shortcut that looks like a key, and
SHA256 digests of old `keybindings.json` contents in a deleted file.
