# Interactive terminal workbooks

Run `lab` (or `dotfiles-lab`) after deployment. From the checkout, use `just lab`.
No notebook server, account, or Python dependency installation is required.

```sh
lab --list
lab navigation
lab archives --keep
lab --smoke
```

Each session creates its own temporary sample directory. The menu shows the
exact command and its purpose before execution. Enter runs a demonstration,
`p` opens a practice shell, `s` skips a step, and `q` returns to the lesson menu.
Use `exit` to leave a practice shell. The practice shell is a normal shell,
not an operating-system security sandbox. Keep experiments inside the displayed
sample directory. Samples are removed on exit unless `--keep` is specified.

| Workbook | Practice |
|---|---|
| navigation | eza, fd, ripgrep, fzf, broot, Yazi |
| viewers | bat, hexyl, jless, ov |
| structured | jc, jq, yq, sd |
| archives | ouch, zstd, xcp, sponge, ts, GNU Parallel, vidir |
| storage | dust, duf, dua, Czkawka duplicate scanning |
| graphics | chafa, viu, pastel, vivid |
| help | tealdeer, jc parser discovery, archive help |
| dev | just, tokei, hyperfine, watchexec |
| operator | fastfetch, btop, cmatrix, cava |

The samples include text, Python, CSV, JSON, duplicate files and a generated PNG.
Duplicate scans never request deletion. Interactive directory editing uses only
the sample directory. Tool configuration/cache directories used by the runner
are isolated beneath the samples where the applications support XDG paths.

`--smoke` runs the noninteractive demonstrations, checks exit codes and selected
expected output, and returns a failure if a required command is missing. It skips
full-screen interactions and audio capture. It is a workflow test, not just a
`--version` check. The lessons end with small exercises for independent practice.

Tealdeer uses the `tldr` command. Run `tldr --update` once to download general
help pages, then try `tldr tar`, `tldr jq`, or `tldr fd`. A local `dotfiles-lab`
page is included. Cache updates do not run automatically at shell startup.
