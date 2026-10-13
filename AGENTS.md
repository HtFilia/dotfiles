# Repository instructions

Read [AGENTS.additional.md](AGENTS.additional.md) for effective use of the
optional modern Unix tools supplied by this repository.

Installation changes must preserve exact checksums for pinned assets. Keep
native packages, official GitHub releases and reviewed source builds distinct
in the report. Optional tool failures must not prevent configuration deployment;
Git, Python (installer/report runtime) and Chezmoi are bootstrap prerequisites.
Do not run the workstation bootstrap on an active host just to test a change.
Use temporary homes and offline regressions, then selected isolated live tests.

Run Bash/Zsh syntax checks, ShellCheck, `bash tests/script-contracts.sh` and
`python3 tests/install-tools.py`. Update docs when changing installation policy.
The server profile remains independently maintained; do not add desktop tools
to it. Build tools as the normal user and preserve existing installations until
the replacement has passed its executable probe.
