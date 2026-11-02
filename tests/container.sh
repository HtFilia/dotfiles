#!/usr/bin/env bash
# Install the dotfiles from scratch in a disposable Podman container with the
# README commands, as a regular user with sudo, then check the machine.
# Usage: tests/container.sh [--worktree] [--keep] SCENARIO
#   SCENARIO: fedora-perso, debian-travail, debian-server, debian-server-baseline
#   --worktree  use the working tree as chezmoi's source instead of cloning
#               the committed HEAD
#   --keep      leave the container running for inspection
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() { sed -n '4,8s/^# \{0,1\}//p' "$0" >&2; exit 2; }
worktree=0
keep=0
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --worktree) worktree=1 ;;
    --keep) keep=1 ;;
    *) usage ;;
  esac
  shift
done
scenario="${1:-}"
case "$scenario" in
  fedora-perso)
    base=registry.fedoraproject.org/fedora:44 os=fedora
    answers=(--promptChoice 'profile=workstation,context=perso' --promptBool gaming=true) ;;
  debian-travail)
    base=docker.io/library/debian:trixie os=debian
    answers=(--promptChoice 'profile=workstation,context=travail') ;;
  debian-server)
    base=docker.io/library/debian:trixie os=debian
    answers=(--promptChoice 'profile=server,context=perso' --promptBool systemBaseline=false) ;;
  debian-server-baseline)
    base=docker.io/library/debian:trixie os=debian
    answers=(--promptChoice 'profile=server,context=perso' --promptBool systemBaseline=true) ;;
  *) usage ;;
esac

# A fresh machine: systemd as PID 1, sudo and a regular user allowed to use it.
# The mounted checkout belongs to another user inside the container, so the
# system Git configuration trusts it for the clone.
build="$(mktemp -d)"
cat >"$build/Containerfile" <<CONTAINERFILE
FROM $base
RUN if command -v dnf >/dev/null; then dnf -y -q install systemd sudo && dnf clean all; \\
    else apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq systemd systemd-sysv dbus sudo \\
      && rm -rf /var/lib/apt/lists/*; fi \\
 && useradd -m -s /bin/bash tester \\
 && echo 'tester ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/tester && chmod 0440 /etc/sudoers.d/tester \
 && printf '[safe]\n\tdirectory = /src\n\tdirectory = /src/.git\n' >/etc/gitconfig
CMD ["/sbin/init"]
CONTAINERFILE
image="localhost/dotfiles-test:$os"
podman build -q -t "$image" "$build" >/dev/null
rm -rf "$build"

name="dotfiles-$scenario-$$"
cleanup() { (( keep )) || podman rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT
podman run -d --name "$name" --systemd=always --security-opt label=disable \
  -v "$root:/src:ro" "$image" >/dev/null
podman exec "$name" systemctl is-system-running --wait >/dev/null 2>&1 || true

as_tester() {
  podman exec -u tester -w /home/tester -e HOME=/home/tester -e USER=tester \
    -e PATH=/home/tester/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    "$name" "$@"
}
if (( worktree )); then
  install="mkdir -p ~/.local/share && ln -s /src ~/.local/share/chezmoi"$'\n'
  install+="$("$root/tests/readme-install.sh" "$os" "" "${answers[@]}")"
else
  install="$("$root/tests/readme-install.sh" "$os" file:///src "${answers[@]}")"
fi
# Debian machines may only use the official repositories: record the APT
# sources and keys before the install and compare afterwards.
apt_sources() {
  podman exec "$name" sh -c 'find /etc/apt/sources.list /etc/apt/sources.list.d /etc/apt/trusted.gpg \
    /etc/apt/trusted.gpg.d /etc/apt/keyrings -type f 2>/dev/null | sort | xargs -r sha256sum'
}
[[ "$os" == debian ]] && apt_before="$(apt_sources)"

printf '== Install: %s\n%s\n' "$scenario" "$install"
as_tester bash -euo pipefail -c "$install"

if [[ "$os" == debian ]]; then
  apt_after="$(apt_sources)"
  if [[ "$apt_after" != "$apt_before" ]]; then
    printf 'APT sources or keys changed:\n%s\n' "$(diff <(echo "$apt_before") <(echo "$apt_after"))"
    exit 1
  fi
  echo 'ok - the install added no APT source, key or backports suite'
fi
# The checks come from chezmoi's own clone, as on a real machine.
# shellcheck disable=SC2016
as_tester bash -c 'exec bash "$(chezmoi source-path)/../tests/machine.sh"'
if [[ "$scenario" == fedora-perso ]]; then
  # shellcheck disable=SC2016
  as_tester bash -c 'exec bash "$(chezmoi source-path)/../tests/repo.sh"'
fi
(( keep )) && printf 'Container kept: podman exec -it -u tester %s bash\n' "$name"
printf '== %s passed\n' "$scenario"
