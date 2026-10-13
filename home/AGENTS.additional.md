# Modern Unix tools on this workstation

These dotfiles install optional tools. Check `command -v TOOL` first; never assume
an installation succeeded. Read the newest `~/.local/state/dotfiles/install-reports/*/report.md`
for the actual result, method, observed version, attempted fallbacks and logs.
Prefer non-interactive commands with plain, bounded output. Invoke executables
explicitly rather than relying on interactive Zsh aliases. Keep POSIX utilities
as fallbacks and do not install anything just to inspect a repository.

| Task | Preferred commands | Fallback / guidance |
|---|---|---|
| Search file contents | `rg -n -- 'pattern' path`; `rg -l -- 'pattern' path` | `grep -R`; use `rg --hidden -g '!.git'` only when hidden files matter |
| Enumerate repository files | `rg --files -g '*.py'`; `fd -t f -e py . path` | `find`; `fd -0` and `xargs -0` preserve unusual filenames |
| Read files | `bat --paging=never --color=never --style=plain file` | `sed -n '1,160p' file` or `cat`; keep output bounded |
| Directory overview | `eza -la --color=never`; `eza --tree --level=2 --color=never` | `ls -la`, `find`; avoid icons and large recursive listings in logs |
| Git changes | `git diff --stat`; `git --no-pager diff -- file` | `delta --paging=never` for human review; `lazygit` is interactive |
| GitHub | `gh pr view`, `gh run view`, `gh issue view` | Git/API tools; creating or changing remote content needs task authorization |
| JSON | `jq -r '.items[] | .name' file.json` | Python `json`; `jless` is an interactive viewer |
| YAML / TOML / XML | Mike Farah `yq eval '.key' file.yaml` | Python/library tools; this is not the Python package also named `yq` |
| Unix output to JSON | `jc --df` or `jc --ps` | Verify the parser matches the command before using its fields |
| Simple substitution | `sd 'pattern' 'replacement' file` | Python or `sed`; `sd` edits in place: review the diff after changing files |
| Filesystem capacity | `duf --json`; `df -h` | `duf` is for mounted filesystems, not directory totals |
| Directory sizes | `dust -d 2 path`; `dua --no-progress aggregate path` | `du -sh`; `dua interactive`, `broot` and Yazi are terminal UIs |
| Archives | `ouch list archive.zip`; `ouch decompress archive.zip -d dest` | `tar`, `unzip`, `zstd`; inspect paths before extracting untrusted archives |
| Binary files | `hexyl --length 256 file` | `od` or `xxd`; bound the byte count |
| Copy files | `xcp source dest` | `cp`; review overwrite behavior before copying |
| Benchmarks | `hyperfine --warmup 2 --runs 5 'command'` | `time`; benchmarks execute commands repeatedly, so avoid destructive commands |
| Code inventory | `tokei path` | `wc` or language tools; optional compiler-dependent tool |
| Watch changes | `watchexec -e py -- command` | Run once unless a persistent watcher was requested |
| HTTP | `xh --print=hb GET https://example.com`; `curl -fsSL URL` | Prefer read-only requests; inspect bodies and destinations before mutations |
| Python environments | `uv sync`, `uv run pytest`, `uv venv` | Project's existing workflow or `python3 -m venv`; preserve lockfiles |
| Project runtimes | `mise current`; `mise exec -- command` | Installed runtime; inspect project configuration before `mise trust` |
| Project environments | `direnv status` | Inspect `.envrc` before `direnv allow`; it executes code |
| Shell quality | `shellcheck scripts/*.sh`; `shfmt -d file.sh`; `bats tests` | Bash syntax checks; match the repository's conventions |
| CI and secrets | `actionlint`; `gitleaks git --redact --no-banner` | Do not print secret values; report only locations and remediation |
| Tasks / JS quality | `just --list`; `pnpm run SCRIPT`; `biome check path` | Read the task/config first; use the project's pinned runtime and package manager |
| Sessions / resources | `tmux list-sessions`; `ps`, `free`, `df` | `btop`, `htop` are interactive resource inspectors |
| Short command help | `tldr COMMAND`; `COMMAND --help` | `man`; tldr needs a separately populated cache (`tldr --update`) |

Interactive conveniences include fzf, zoxide (`z`), Atuin, Yazi (`yy`),
LazyGit, LazyDocker, broot, ov and jless. Agents should use their ordinary CLI
counterparts for deterministic operations. Atuin history can contain private
information; use only task-relevant history. Fastfetch, chafa, viu, vivid,
pastel, cmatrix and cava are presentation helpers, not mandatory dependencies.
Czkawka can find duplicates; inspect candidates before any deletion. GNU
Parallel and moreutils (`sponge`, `ts`, `vidir`) help batch work; `sponge` writes
a file and `vidir` can rename/delete entries. Docker, Compose, Buildx and Colima
may manage services; inspect state before starting or stopping anything.

For configuration deployment use `scripts/apply-dotfiles.sh --dry-run`, then
apply only within the requested scope. For tool installation use
`scripts/install-tools.py --dry-run` and the documented `--methods` order.
Do not use `--methods source` assuming GitHub is the only network dependency:
Cargo, Go, npm, Python builds and Neovim can fetch dependencies from other hosts.
