#!/usr/bin/env bash
# A small portable Debian 13 system baseline; sudo user or root with --user.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  printf 'Usage: %s [--dry-run|--apply] [--user ACCOUNT]\n' "$0"
  exit 0
fi
# shellcheck source=scripts/preflight.sh
. "$SCRIPT_DIR/preflight.sh"
preflight_linux server
# shellcheck disable=SC1091
. /etc/os-release
[[ "$ID:$VERSION_ID" == debian:13 ]] || { printf 'System baseline supports Debian 13 only.\n' >&2; exit 2; }
mode=dry-run
user="$(id -un)"
explicit_user=0
while (( $# )); do
  case "$1" in
    --apply) mode=apply ;;
    --dry-run) mode=dry-run ;;
    --user) [[ $# -ge 2 ]] || exit 2; user="$2"; explicit_user=1; shift ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
account="$(getent passwd "$user")" || { printf 'Unknown account.\n' >&2; exit 2; }
[[ "${account%%:*}" == "$user" ]] || exit 2
(( $(id -u "$user") >= 1000 )) || { printf 'Expected a regular administrator account.\n' >&2; exit 2; }
admin=()
if (( EUID == 0 )); then
  (( explicit_user )) || { printf 'Root must select --user ACCOUNT.\n' >&2; exit 2; }
else
  [[ "$(id -un)" == "$user" ]] || { printf 'Select the current account.\n' >&2; exit 2; }
  command -v sudo >/dev/null || { printf 'sudo is required.\n' >&2; exit 2; }
  admin=(sudo)
fi
user_home="$(printf '%s' "$account" | cut -d: -f6)"
[[ -d "$user_home" && "$user_home" != / ]] || { printf 'Administrator home is missing.\n' >&2; exit 2; }
source_dir="$SCRIPT_DIR/../system/debian"
target=/etc/systemd/journald.conf.d/20-dotfiles-retention.conf
legacy=/etc/systemd/journald.conf.d/20-homelab-retention.conf
apt_target=/etc/apt/apt.conf.d/20auto-upgrades
policy_target=/etc/apt/apt.conf.d/52dotfiles-unattended
expected_journal="$(cat "$source_dir/20-dotfiles-retention.conf")"
expected_apt="$(cat "$source_dir/20auto-upgrades")"
expected_policy="$(cat "$source_dir/52dotfiles-unattended")"
expected_legacy=$'[Journal]\nSystemMaxUse=500M\nSystemKeepFree=1G\nMaxRetentionSec=30day\nMaxFileSec=7day\n'
check_file() {
  local file="$1" expected="$2" label="$3"
  [[ ! -e "$file" || "$(cat "$file")" == "${expected%$'\n'}" ]] || {
    printf 'Conflicting %s configuration: %s\n' "$label" "$file" >&2; exit 1;
  }
}
apt-config -c "$source_dir/52dotfiles-unattended" dump >/dev/null
check_file "$target" "$expected_journal" journal
check_file "$legacy" "$expected_legacy" 'legacy journal'
check_file "$apt_target" "$expected_apt" APT
check_file "$policy_target" "$expected_policy" 'unattended upgrades'
packages=()
for package in unattended-upgrades logrotate; do
  [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" == 'install ok installed' ]] || packages+=("$package")
done
journal_changed=0
[[ -f "$target" && ! -e "$legacy" ]] || journal_changed=1
needs_group=0
id -nG "$user" | tr ' ' '\n' | grep -qx systemd-journal || needs_group=1
timers=()
for timer in apt-daily.timer apt-daily-upgrade.timer logrotate.timer; do
  if ! systemctl is-enabled --quiet "$timer" || ! systemctl is-active --quiet "$timer"; then timers+=("$timer"); fi
done
printf 'Debian 13 baseline for %s:\n' "$user"
printf '  journal retention: 500M, keep 1G free, maximum 30 days\n'
printf '  daily APT index refresh and Debian-origin unattended upgrades\n'
printf '  add %s to systemd-journal for read-only system logs\n' "$user"
printf '  keep automatic reboot disabled; enable APT and logrotate timers\n'
if (( ${#packages[@]} )); then printf '  install packages:'; printf ' %s' "${packages[@]}"; printf '\n'; fi
[[ ! -e "$legacy" ]] || printf '  retire the identical homelab journal drop-in\n'
[[ "$mode" == apply ]] || exit 0
if (( journal_changed == 0 && needs_group == 0 && ${#packages[@]} == 0 && ${#timers[@]} == 0 )) && [[ -f "$apt_target" && -f "$policy_target" && -f "$user_home/.local/state/dotfiles/system-baseline" ]]; then
  printf 'Baseline already matches; no changes.\n'
  exit 0
fi
if (( EUID != 0 )); then sudo -v; fi
"${admin[@]}" install -d -m 700 /var/backups/dotfiles-system
backup="$("${admin[@]}" mktemp -d /var/backups/dotfiles-system/baseline.XXXXXXXX)"
for file in "$target" "$legacy" "$apt_target" "$policy_target"; do
  if [[ -e "$file" ]]; then "${admin[@]}" cp -p "$file" "$backup/$(basename "$file")"; fi
done
for timer in apt-daily.timer apt-daily-upgrade.timer logrotate.timer; do
  printf '%s %s %s\n' "$timer" "$(systemctl is-enabled "$timer" 2>/dev/null || true)" "$(systemctl is-active "$timer" 2>/dev/null || true)"
done | "${admin[@]}" tee "$backup/timers-before" >/dev/null
printf '%s\n' "$(id -nG "$user")" | "${admin[@]}" tee "$backup/groups-before" >/dev/null
printf 'Baseline backup: %s\n' "$backup"
if (( ${#packages[@]} )); then
  "${admin[@]}" apt-get update
  "${admin[@]}" apt-get install -y --no-install-recommends "${packages[@]}"
fi
"${admin[@]}" install -d -m 755 /etc/systemd/journald.conf.d
"${admin[@]}" install -m 644 "$source_dir/20-dotfiles-retention.conf" "$target"
"${admin[@]}" install -m 644 "$source_dir/20auto-upgrades" "$apt_target"
"${admin[@]}" install -m 644 "$source_dir/52dotfiles-unattended" "$policy_target"
[[ ! -e "$legacy" ]] || "${admin[@]}" rm -- "$legacy"
if (( needs_group )); then
  "${admin[@]}" usermod -aG systemd-journal "$user"
fi
"${admin[@]}" systemd-analyze cat-config systemd/journald.conf >/dev/null
if (( journal_changed )); then
  "${admin[@]}" systemctl restart systemd-journald.service
  "${admin[@]}" journalctl --flush
fi
if (( ${#timers[@]} )); then "${admin[@]}" systemctl enable --now "${timers[@]}"; fi
"${admin[@]}" install -d -o "$user" -g "$(id -gn "$user")" -m 700 "$user_home/.local/state/dotfiles"
printf 'Debian 13\n' | "${admin[@]}" install -o "$user" -g "$(id -gn "$user")" -m 600 /dev/stdin "$user_home/.local/state/dotfiles/system-baseline"
printf 'Baseline applied. Sign in again for journal group membership.\n'
