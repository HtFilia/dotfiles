# 🏡 chezmoi workflow

[chezmoi](https://www.chezmoi.io/) manages your dotfiles in a **source state** (the git repo) and applies them to your home directory (the **destination state**).

## Mental model

```
┌─────────────────────────────┐        ┌──────────────────┐
│ ~/.local/share/chezmoi/     │  -->   │ ~/.zshrc         │
│   dot_zshrc.tmpl            │        │ ~/.gitconfig     │
│   dot_gitconfig.tmpl        │        │ ~/.config/nvim/  │
│   dot_config/nvim/init.lua  │        │ ...              │
└─────────────────────────────┘        └──────────────────┘
        source state                      destination state
```

## Filename prefixes

| Prefix | Meaning | Example |
|---|---|---|
| `dot_` | Becomes a dotfile (`.`) | `dot_zshrc` → `~/.zshrc` |
| `private_` | Mode 600 (sensitive) | `private_dot_ssh/` → `~/.ssh/` (0600) |
| `executable_` | Mode +x | `executable_dot_local/bin/foo` |
| suffix `.tmpl` | Go template | `dot_zshrc.tmpl` → `~/.zshrc` |
| `run_once_` | Run once per machine | `run_once_install.sh` |
| `run_onchange_` | Run when content changes | `run_onchange_install-packages.sh` |

## First-time setup

```bash
# Install chezmoi + clone + apply + answer prompts
chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git
```

On first run, you'll be prompted for:

- Your name
- Your email
- Machine type: `personal` or `work`
- Machine hostname identifier

The answers are stored in `~/.config/chezmoi/chezmoi.toml` and accessed in templates via `{{ .name }}`, `{{ .email }}`, etc.

## Daily commands

```bash
# See what's different between source and destination
chezmoi diff

# Apply source → destination
chezmoi apply

# Apply with verbose output
chezmoi apply -v

# Edit a file in the source state (opens in $EDITOR)
chezmoi edit ~/.zshrc

# Edit + auto-apply on save
chezmoi edit --apply ~/.zshrc

# Go to the source directory (for git ops)
chezmoi cd
# → you're now in ~/.local/share/chezmoi
# do: git add . && git commit -m "…" && git push
# exit with `exit`

# Pull upstream changes + re-apply
chezmoi update
```

## Templates

Template syntax is Go's `text/template`. Variables available:

```go
{{ .chezmoi.os }}           // "darwin", "linux"
{{ .chezmoi.arch }}         // "amd64", "arm64"
{{ .chezmoi.hostname }}     // system hostname
{{ .chezmoi.username }}     // current user
{{ .chezmoi.kernel.osrelease }}  // useful for WSL detection

// From your .chezmoi.toml
{{ .name }}
{{ .email }}
{{ .machineType }}  // "personal" or "work"
```

### Example — OS-specific aliases

```go
{{- if eq .chezmoi.os "darwin" }}
alias brewup='brew update && brew upgrade'
{{- else }}
alias aptup='sudo apt update && sudo apt upgrade -y'
{{- end }}
```

### Example — WSL detection

```go
{{- if and (eq .chezmoi.os "linux") (contains "microsoft" (lower .chezmoi.kernel.osrelease)) }}
alias pbcopy='clip.exe'
{{- end }}
```

### Example — work vs personal git email

```go
[user]
{{- if eq .machineType "work" }}
    email = {{ .email }}
    signingkey = "WORK_KEY_ID"
{{- else }}
    email = {{ .email }}
{{- end }}
```

## Adding a new file

```bash
# Add an existing file from your home dir to the source state
chezmoi add ~/.config/something/config.yaml

# Add as a template (so it can use {{ .name }} etc.)
chezmoi add --template ~/.gitconfig
```

## Machine-local overrides (not committed)

Any file ending in `.local` is sourced by our config but **ignored by git**:

- `~/.zshrc.local` — sourced at the end of `.zshrc`
- `~/.gitconfig.local` — included from `.gitconfig`

Put secrets and per-machine tweaks there.

## Troubleshooting

```bash
# Check what chezmoi thinks your data is
chezmoi data

# See source → dest mapping for a file
chezmoi source-path ~/.zshrc
chezmoi target-path <source-file>

# Dry run
chezmoi apply --dry-run -v

# Force re-run of run_once scripts
chezmoi state delete-bucket --bucket=scriptState
```
