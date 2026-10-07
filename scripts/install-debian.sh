#!/usr/bin/env bash
# Install corporate Debian tools through existing APT sources and pinned GitHub assets.

set -euo pipefail

ENV_TYPE="linux"
if [[ $# -gt 0 && "$1" != --* ]]; then
  ENV_TYPE="$1"
  shift
fi
ENABLE_DOCKER_GROUP=0
SKIP_DOCKER=0
SKIP_PACKAGES=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/pinned-assets.sh
. "$SCRIPT_DIR/pinned-assets.sh"

log() { printf "\033[0;34m==>\033[0m %s\n" "$*"; }
success() { printf "\033[0;32m  +\033[0m %s\n" "$*"; }
info() { printf "\033[0;36m  i\033[0m %s\n" "$*"; }
warn() { printf "\033[0;33m  !\033[0m %s\n" "$*" >&2; }
fatal() { printf "\033[0;31m  x\033[0m %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [linux|wsl] [--enable-docker-group] [--skip-docker] [--skip-packages]

Options:
  --enable-docker-group   add the current user to the root-equivalent docker group
  --skip-docker           do not install Docker
  --skip-packages         administrator has provisioned required APT packages
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable-docker-group) ENABLE_DOCKER_GROUP=1 ;;
    --skip-docker) SKIP_DOCKER=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fatal "Unknown argument: $1" ;;
  esac
  shift
done

[[ "$ENV_TYPE" == linux || "$ENV_TYPE" == wsl ]] || fatal "Expected linux or wsl"
# shellcheck source=scripts/corporate-preflight.sh
. "$SCRIPT_DIR/corporate-preflight.sh"
corporate_platform workstation
corporate_settings
corporate_repository "$(cd "$SCRIPT_DIR/.." && pwd)"
(( EUID != 0 )) || fatal "Run as a regular user."

LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
DOWNLOAD_DIR="${DOTFILES_DOWNLOAD_DIR:-$HOME/.cache/dotfiles/downloads}"
mkdir -p "$LOCAL_BIN" "$DOWNLOAD_DIR"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

ARCH="$(pinned_asset_arch)" || fatal "Unsupported architecture: $(uname -m)"
GO_ARCH="$(pinned_asset_go_arch)" || fatal "Unsupported Go architecture: $(uname -m)"
[[ "$ARCH" == "x86_64" ]] || fatal "Pinned Linux assets currently support x86_64 only."

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

install_from_archive() {
  local key="$1" member="$2" dest="$3" archive tmp file
  file="$(pinned_asset_field "$key" file)"
  archive="$(cached_asset_path "$key" "$DOWNLOAD_DIR")" || fatal "Download/checksum failed: $key"
  tmp="$(mktemp -d "$work_dir/extract.XXXXXX")"
  extract_pinned_archive "$archive" "$tmp" || { rm -rf "$tmp"; fatal "Unsupported archive type: $file"; }
  local found
  local -a matches=()
  while IFS= read -r -d '' found; do matches+=("$found"); done < <(find "$tmp" -type f -name "$member" -print0)
  [[ "${#matches[@]}" == 1 ]] || { rm -rf "$tmp"; fatal "Could not find $member in $file"; }
  atomic_install_binary "${matches[0]}" "$dest"
  rm -rf "$tmp"
  success "installed $(basename "$dest")"
}

install_binary_asset() {
  local key="$1" dest="$2" archive file
  file="$(pinned_asset_field "$key" file)"
  archive="$(cached_asset_path "$key" "$DOWNLOAD_DIR")" || fatal "Download/checksum failed: $key"
  atomic_install_binary "$archive" "$dest"
  success "installed $(basename "$dest")"
}

install_archive_if_needed() {
  local tool="$1" key="$2" member="$3" dest="$4" version_cmd="${5:---version}"
  asset_version_matches "$tool" "$key" "$version_cmd" || install_from_archive "$key" "$member" "$dest"
  asset_version_matches "$tool" "$key" "$version_cmd" || fatal "Installed $tool does not execute at the reviewed version"
}

install_binary_if_needed() {
  local tool="$1" key="$2" dest="$3" version_cmd="${4:---version}"
  asset_version_matches "$tool" "$key" "$version_cmd" || install_binary_asset "$key" "$dest"
  asset_version_matches "$tool" "$key" "$version_cmd" || fatal "Installed $tool does not execute at the reviewed version"
}

install_yazi() {
  install_from_archive "yazi-linux-$ARCH" yazi "$LOCAL_BIN/yazi"
  install_from_archive "yazi-linux-$ARCH" ya "$LOCAL_BIN/ya"
}

install_runtime() {
  local tool="$1" key="$2" member="$3" version archive stage destination
  version="$(pinned_asset_field "$key" version)"
  archive="$(cached_asset_path "$key" "$DOWNLOAD_DIR")" || fatal "Download/checksum failed: $key"
  mkdir -p "$HOME/.local/opt"
  destination="$HOME/.local/opt/$tool-$version"
  if [[ ! -x "$destination/$member" ]]; then
    stage="$(mktemp -d "$HOME/.local/opt/$tool-stage.XXXXXX")"
    if ! extract_pinned_archive "$archive" "$stage"; then
      rm -rf "$stage"
      fatal "Invalid runtime archive: $key"
    fi
    local roots=("$stage"/*)
    [[ ${#roots[@]} == 1 && -d "${roots[0]}" && -x "${roots[0]}/$member" ]] || { rm -rf "$stage"; fatal "Invalid runtime layout: $key"; }
    "${roots[0]}/$member" --version >/dev/null || { rm -rf "$stage"; fatal "Runtime does not execute: $key"; }
    [[ ! -e "$destination" ]] || { rm -rf "$stage"; fatal "Incomplete runtime directory: $destination"; }
    mv "${roots[0]}" "$destination"
    rmdir "$stage"
  fi
  ln -sfnT "$destination/$member" "$LOCAL_BIN/$tool"
}
install_neovim() { install_runtime nvim "neovim-linux-$ARCH" bin/nvim; }
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  info "Detected: ${PRETTY_NAME:-$ID}"
fi
# shellcheck source=scripts/corporate-packages.sh
. "$SCRIPT_DIR/corporate-packages.sh"
if [[ "$SKIP_PACKAGES" == 0 ]]; then
  command -v sudo >/dev/null || fatal 'sudo is required; use --skip-packages after administrator provisioning.'
  log 'Checking authorized APT packages...'
  sudo apt-get update
  apt-get --simulate install --no-install-recommends "${corporate_packages[@]}" >/dev/null || fatal 'Required APT packages unavailable; resolve AGENTS.md C02 before continuing.'
  sudo apt-get install -y --no-install-recommends "${corporate_packages[@]}"
fi
for tool in cc curl git python3 tar unzip xz pkg-config; do
  command -v "$tool" >/dev/null || fatal "Required tool $tool missing; administrator provisioning is incomplete."
done
# Stable distro runtimes; project-specific upgrades need a reviewed source closure.
for pair in python3:python3 node:nodejs npm:npm npx:npm go:golang-go gofmt:golang-go rustc:rustc cargo:cargo rustfmt:rustfmt; do
  corporate_apt_runtime "${pair%%:*}" "${pair#*:}" "$LOCAL_BIN" || fatal 'APT runtime provisioning failed.'
done
if [[ "$SKIP_PACKAGES" == 0 ]] && apt-cache policy tokei | grep -Eq 'Candidate: [^ (]'; then
  sudo apt-get install -y --no-install-recommends tokei
fi
if ! dpkg-query -W -f='${Status}' tokei 2>/dev/null | grep -qx 'install ok installed'; then
  warn 'Optional Tokei unavailable through APT; no Cargo registry fallback (AGENTS.md C11).'
fi
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
fi
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
fi

install_archive_if_needed starship "starship-linux-$ARCH" starship "$LOCAL_BIN/starship"
install_archive_if_needed eza "eza-linux-$ARCH" eza "$LOCAL_BIN/eza"
install_archive_if_needed uv "uv-linux-$ARCH" uv "$LOCAL_BIN/uv"
install_archive_if_needed uvx "uv-linux-$ARCH" uvx "$LOCAL_BIN/uvx"
install_archive_if_needed delta "delta-linux-$ARCH" delta "$LOCAL_BIN/delta"
install_archive_if_needed lazygit "lazygit-linux-$ARCH" lazygit "$LOCAL_BIN/lazygit"
install_archive_if_needed chezmoi "chezmoi-linux-$GO_ARCH" chezmoi "$LOCAL_BIN/chezmoi"
install_archive_if_needed just "just-linux-$ARCH" just "$LOCAL_BIN/just"
install_binary_if_needed mise "mise-linux-$ARCH" "$LOCAL_BIN/mise"
if ! asset_version_matches yazi "yazi-linux-$ARCH" --version || ! command -v ya >/dev/null 2>&1; then
  install_yazi
fi
install_binary_if_needed yq "yq-linux-$GO_ARCH" "$LOCAL_BIN/yq"
install_archive_if_needed sd "sd-linux-$ARCH" sd "$LOCAL_BIN/sd"
install_archive_if_needed dust "dust-linux-$ARCH" dust "$LOCAL_BIN/dust"
install_archive_if_needed duf "duf-linux-$ARCH" duf "$LOCAL_BIN/duf"
install_archive_if_needed hyperfine "hyperfine-linux-$ARCH" hyperfine "$LOCAL_BIN/hyperfine"
install_archive_if_needed watchexec "watchexec-linux-$ARCH" watchexec "$LOCAL_BIN/watchexec"
install_archive_if_needed xh "xh-linux-$ARCH" xh "$LOCAL_BIN/xh"
install_archive_if_needed lazydocker "lazydocker-linux-$ARCH" lazydocker "$LOCAL_BIN/lazydocker"
install_archive_if_needed gitleaks "gitleaks-linux-x64" gitleaks "$LOCAL_BIN/gitleaks" version
install_archive_if_needed actionlint "actionlint-linux-$GO_ARCH" actionlint "$LOCAL_BIN/actionlint"

if ! asset_version_matches nvim "neovim-linux-$ARCH" --version; then
  install_neovim
fi
"$SCRIPT_DIR/install-extra-tools.sh"
install_archive_if_needed pnpm "pnpm-linux-$ARCH" pnpm "$LOCAL_BIN/pnpm"
install_binary_if_needed biome "biome-linux-$ARCH" "$LOCAL_BIN/biome"
# The standalone pnpm asset does not provide npm's pnpx launcher.
printf '#!/usr/bin/env sh\nexec pnpm dlx "$@"\n' > "$work_dir/pnpx"
if ! cmp -s "$work_dir/pnpx" "$LOCAL_BIN/pnpx"; then
  atomic_install_binary "$work_dir/pnpx" "$LOCAL_BIN/pnpx"
fi
if ! asset_version_matches tree-sitter "tree-sitter-linux-$ARCH"; then
  archive="$(cached_asset_path "tree-sitter-linux-$ARCH" "$DOWNLOAD_DIR")" || fatal 'tree-sitter acquisition failed.'
  gzip -dc "$archive" > "$work_dir/tree-sitter"
  atomic_install_binary "$work_dir/tree-sitter" "$LOCAL_BIN/tree-sitter"
fi
for pair in pnpm:pnpm-linux-x86_64 biome:biome-linux-x86_64 tree-sitter:tree-sitter-linux-x86_64; do
  asset_version_matches "${pair%%:*}" "${pair#*:}" || fatal "Installed binary failed version verification: ${pair%%:*}"
done

if [[ "$SKIP_DOCKER" == 1 ]]; then
  warn 'Docker omitted by selection.'
elif [[ "$ENV_TYPE" == wsl ]]; then
  warn 'WSL container engine must be supplied by the authorized Windows host.'
elif [[ "$SKIP_PACKAGES" == 0 ]]; then
  docker_packages=(docker.io docker-compose docker-buildx)
  apt-get --simulate install --no-install-recommends "${docker_packages[@]}" >/dev/null || fatal 'Docker packages unavailable through authorized APT; use --skip-docker or resolve AGENTS.md C10.'
  sudo apt-get install -y --no-install-recommends "${docker_packages[@]}"
fi
if [[ "$SKIP_DOCKER" == 0 && "$ENV_TYPE" != wsl ]]; then
  if ! docker compose version >/dev/null || ! docker buildx version >/dev/null; then
    fatal 'Docker Compose/Buildx missing; resolve C10 or use --skip-docker.'
  fi
fi
if [[ "$ENABLE_DOCKER_GROUP" == 1 && "$SKIP_PACKAGES" == 1 ]]; then
  fatal "--enable-docker-group requires package changes; omit --skip-packages"
fi
if [[ "$ENABLE_DOCKER_GROUP" == 1 && "$SKIP_DOCKER" == 0 && "$ENV_TYPE" != wsl ]]; then
  getent group docker >/dev/null || fatal "Docker group is absent; install the engine first."
  sudo usermod -aG docker "$(id -un)"
  warn "Docker group grants root-equivalent access; log out/in."
fi

command -v gh >/dev/null || fatal 'GitHub CLI missing; install gh through authorized APT.'
mkdir -p "$HOME/.local/state/dotfiles"
printf '%s\n' "$SKIP_DOCKER" > "$HOME/.local/state/dotfiles/skip-docker"
# Record actual distribution versions, allowing Debian security updates.
dpkg-query -W -f='${Package}\t${Version}\n' python3 nodejs npm golang-go rustc cargo > "$HOME/.local/state/dotfiles/apt-runtimes.tsv"
warn "Claude Code is not installed automatically."
warn "Ghostty and VS Code require separate corporate-approved provisioning (AGENTS.md C09)."
success "Debian/WSL setup complete."
