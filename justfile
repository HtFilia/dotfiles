# Tasks for this repository. `just` lists them.

# List recipes
default:
    @just --list

# Lint and scan the repository: actionlint, gitleaks, ShellCheck, shfmt, rendered templates
check:
    tests/repo.sh

# Install one machine from scratch in a Podman container, from the working tree
test scenario="fedora-perso":
    tests/container.sh --worktree {{ scenario }}

# Run the container install for every machine CI covers
test-all: (test "fedora-perso") (test "debian-travail") (test "debian-server-baseline")

# Format the repository's shell scripts
fmt:
    shfmt -w scripts tests .githooks

# Show what `chezmoi apply` would change on this machine
diff:
    chezmoi diff

# Deploy to this machine, then check it
apply:
    chezmoi apply
    scripts/verify.sh

# Pull and apply everything, package and baseline scripts included (sudo); the daily timer on the server skips those
vps-update:
    chezmoi update
    scripts/verify.sh

# Check this machine's tools and files
verify:
    scripts/verify.sh

# Compare each pinned release with the project's latest one
outdated:
    scripts/outdated.sh
