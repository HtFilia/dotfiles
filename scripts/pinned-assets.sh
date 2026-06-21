#!/usr/bin/env bash
# Pinned direct-download assets.
# Keep versions, URLs, filenames and SHA256 values in sync with docs/ASSET-MANIFEST.md.

pinned_asset_field() {
  local key="$1" field="$2"
  case "$key:$field" in
    starship-linux-x86_64:version) printf '%s\n' 'v1.23.0' ;;
    starship-linux-x86_64:url) printf '%s\n' 'https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:file) printf '%s\n' 'starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:sha256) printf '%s\n' 'cef41df04378c6f692913c5d9c1032d3b9a4369a1d2f3296c8300ed8838c2197' ;;

    eza-linux-x86_64:version) printf '%s\n' 'v0.21.5' ;;
    eza-linux-x86_64:url) printf '%s\n' 'https://github.com/eza-community/eza/releases/download/v0.21.5/eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:file) printf '%s\n' 'eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:sha256) printf '%s\n' 'f49f764340d13379013213dbffc6e0d78cba7b0f9b9388be9306eb0c69914dd1' ;;

    uv-linux-x86_64:version) printf '%s\n' '0.6.17' ;;
    uv-linux-x86_64:url) printf '%s\n' 'https://github.com/astral-sh/uv/releases/download/0.6.17/uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:file) printf '%s\n' 'uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:sha256) printf '%s\n' '720ec28f7a94aa8cd91d3d57dec1434d64b9ae13d1dd6a25f4c0cdb837ba9cf6' ;;

    lazygit-linux-x86_64:version) printf '%s\n' 'v0.48.0' ;;
    lazygit-linux-x86_64:url) printf '%s\n' 'https://github.com/jesseduffield/lazygit/releases/download/v0.48.0/lazygit_0.48.0_Linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:file) printf '%s\n' 'lazygit_0.48.0_Linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:sha256) printf '%s\n' '291722c643a10805de3bd7b58f51d5275878269aeadb046709708f8683f558d7' ;;

    delta-linux-x86_64:version) printf '%s\n' '0.18.2' ;;
    delta-linux-x86_64:url) printf '%s\n' 'https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz' ;;
    delta-linux-x86_64:file) printf '%s\n' 'delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz' ;;
    delta-linux-x86_64:sha256) printf '%s\n' '99607c43238e11a77fe90a914d8c2d64961aff84b60b8186c1b5691b39955b0f' ;;

    firacode:version) printf '%s\n' 'v3.3.0' ;;
    firacode:url) printf '%s\n' 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip' ;;
    firacode:file) printf '%s\n' 'FiraCode.zip' ;;
    firacode:sha256) printf '%s\n' '89978e6f870d044286a339161d5ed961569744b1cd2afee62337fa140cd0b397' ;;

    neovim-linux-x86_64:version) printf '%s\n' 'v0.10.4' ;;
    neovim-linux-x86_64:url) printf '%s\n' 'https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz' ;;
    neovim-linux-x86_64:file) printf '%s\n' 'nvim-linux-x86_64.tar.gz' ;;
    neovim-linux-x86_64:sha256) printf '%s\n' '95aaa8e89473f5421114f2787c13ae0ec6e11ebbd1a13a1bd6fcf63420f8073f' ;;

    node-linux-x86_64:version) printf '%s\n' 'v24.17.0' ;;
    node-linux-x86_64:url) printf '%s\n' 'https://nodejs.org/dist/v24.17.0/node-v24.17.0-linux-x64.tar.xz' ;;
    node-linux-x86_64:file) printf '%s\n' 'node-v24.17.0-linux-x64.tar.xz' ;;
    node-linux-x86_64:sha256) printf '%s\n' 'ab343a1b747c7cbf3630dfd7dbf818c5423fab2eb4f5ad1afc896f6bd121a917' ;;

    node-linux-arm64:version) printf '%s\n' 'v24.17.0' ;;
    node-linux-arm64:url) printf '%s\n' 'https://nodejs.org/dist/v24.17.0/node-v24.17.0-linux-arm64.tar.xz' ;;
    node-linux-arm64:file) printf '%s\n' 'node-v24.17.0-linux-arm64.tar.xz' ;;
    node-linux-arm64:sha256) printf '%s\n' '67324b9e515e7d13da72571a5dd522bb23145a820f7dde15497897e466759ab3' ;;

    chezmoi-linux-amd64:version) printf '%s\n' 'v2.70.5' ;;
    chezmoi-linux-amd64:url) printf '%s\n' 'https://github.com/twpayne/chezmoi/releases/download/v2.70.5/chezmoi_2.70.5_linux_amd64.tar.gz' ;;
    chezmoi-linux-amd64:file) printf '%s\n' 'chezmoi_2.70.5_linux_amd64.tar.gz' ;;
    chezmoi-linux-amd64:sha256) printf '%s\n' '6a76a0ac3718f0d45b34b4b57067f9556f8f6042e3da710a3c496838362aca14' ;;

    chezmoi-linux-arm64:version) printf '%s\n' 'v2.70.5' ;;
    chezmoi-linux-arm64:url) printf '%s\n' 'https://github.com/twpayne/chezmoi/releases/download/v2.70.5/chezmoi_2.70.5_linux_arm64.tar.gz' ;;
    chezmoi-linux-arm64:file) printf '%s\n' 'chezmoi_2.70.5_linux_arm64.tar.gz' ;;
    chezmoi-linux-arm64:sha256) printf '%s\n' '4f4f31d0a10ed3b955e814a5ae20075426e27c9d3a09f536bfa4a6c8718353f2' ;;

    go-linux-amd64:version) printf '%s\n' '1.26.4' ;;
    go-linux-amd64:url) printf '%s\n' 'https://go.dev/dl/go1.26.4.linux-amd64.tar.gz' ;;
    go-linux-amd64:file) printf '%s\n' 'go1.26.4.linux-amd64.tar.gz' ;;
    go-linux-amd64:sha256) printf '%s\n' '1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f' ;;

    go-linux-arm64:version) printf '%s\n' '1.26.4' ;;
    go-linux-arm64:url) printf '%s\n' 'https://go.dev/dl/go1.26.4.linux-arm64.tar.gz' ;;
    go-linux-arm64:file) printf '%s\n' 'go1.26.4.linux-arm64.tar.gz' ;;
    go-linux-arm64:sha256) printf '%s\n' 'ef758ae7c6cf9267c9c0ef080b8965f453d89ab2d25d9eb22de4405925238768' ;;

    *) return 1 ;;
  esac
}

pinned_asset_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf '%s\n' 'x86_64' ;;
    aarch64|arm64) printf '%s\n' 'arm64' ;;
    *) return 1 ;;
  esac
}

pinned_asset_go_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf '%s\n' 'amd64' ;;
    aarch64|arm64) printf '%s\n' 'arm64' ;;
    *) return 1 ;;
  esac
}

verify_sha256() {
  local file="$1" expected="$2" actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  fi
  [[ "$actual" == "$expected" ]]
}

download_pinned_asset() {
  local key="$1" dest_dir="$2" file url sha
  file="$(pinned_asset_field "$key" file)" || return 1
  url="$(pinned_asset_field "$key" url)" || return 1
  sha="$(pinned_asset_field "$key" sha256)" || return 1
  mkdir -p "$dest_dir"
  curl -fsSL "$url" -o "$dest_dir/$file"
  verify_sha256 "$dest_dir/$file" "$sha"
}

require_pinned_file() {
  local key="$1" dir="$2" file sha
  file="$(pinned_asset_field "$key" file)" || return 1
  sha="$(pinned_asset_field "$key" sha256)" || return 1
  [[ -f "$dir/$file" ]] || return 2
  verify_sha256 "$dir/$file" "$sha"
}
