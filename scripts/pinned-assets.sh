#!/usr/bin/env bash
# Pinned direct-download assets.
# Keep versions, URLs, filenames and SHA256 values in sync with docs/ASSET-MANIFEST.md.

pinned_asset_field() {
  local key="$1" field="$2"
  case "$key:$field" in
    starship-linux-x86_64:version) printf '%s\n' 'v1.25.1' ;;
    starship-linux-x86_64:url) printf '%s\n' 'https://github.com/starship/starship/releases/download/v1.25.1/starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:file) printf '%s\n' 'starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:sha256) printf '%s\n' '4488c11ca632327d1f1f16fb2f102c0646094c35479cd5435991385da43c61ac' ;;

    eza-linux-x86_64:version) printf '%s\n' 'v0.23.4' ;;
    eza-linux-x86_64:url) printf '%s\n' 'https://github.com/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:file) printf '%s\n' 'eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:sha256) printf '%s\n' '0c38665440226cd8bef5d1d4f3bc6ff77c927fb0d68b752739105db7ab5b358d' ;;

    uv-linux-x86_64:version) printf '%s\n' '0.11.23' ;;
    uv-linux-x86_64:url) printf '%s\n' 'https://github.com/astral-sh/uv/releases/download/0.11.23/uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:file) printf '%s\n' 'uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:sha256) printf '%s\n' 'e12c4cda2fe8c305510a78380a88f2c32a27e90cdcd123cefd2873388f0ebb5f' ;;

    lazygit-linux-x86_64:version) printf '%s\n' 'v0.62.2' ;;
    lazygit-linux-x86_64:url) printf '%s\n' 'https://github.com/jesseduffield/lazygit/releases/download/v0.62.2/lazygit_0.62.2_linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:file) printf '%s\n' 'lazygit_0.62.2_linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:sha256) printf '%s\n' '8b9a4c2d0969cbea92b45c956dd2a44e1ba76900c9df49f1c60984045ce77984' ;;

    delta-linux-x86_64:version) printf '%s\n' '0.19.2' ;;
    delta-linux-x86_64:url) printf '%s\n' 'https://github.com/dandavison/delta/releases/download/0.19.2/delta-0.19.2-x86_64-unknown-linux-gnu.tar.gz' ;;
    delta-linux-x86_64:file) printf '%s\n' 'delta-0.19.2-x86_64-unknown-linux-gnu.tar.gz' ;;
    delta-linux-x86_64:sha256) printf '%s\n' '8e695c5f586a8c53d6c3b01be0b4a422ed218bfed2a56191caebe373a1c18ab2' ;;

    firacode:version) printf '%s\n' 'v3.4.0' ;;
    firacode:url) printf '%s\n' 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip' ;;
    firacode:file) printf '%s\n' 'FiraCode.zip' ;;
    firacode:sha256) printf '%s\n' '7cc4ffd8f7a1fc914cdab7b149808298165ff7a7f40e40d82dea9ebe41e8ca0b' ;;

    neovim-linux-x86_64:version) printf '%s\n' 'v0.12.3' ;;
    neovim-linux-x86_64:url) printf '%s\n' 'https://github.com/neovim/neovim/releases/download/v0.12.3/nvim-linux-x86_64.tar.gz' ;;
    neovim-linux-x86_64:file) printf '%s\n' 'nvim-linux-x86_64.tar.gz' ;;
    neovim-linux-x86_64:sha256) printf '%s\n' 'c441b547142860bf01bcce39e36cbed185c41112813e15443b16e5237750724d' ;;

    just-linux-x86_64:version) printf '%s\n' '1.53.0' ;;
    just-linux-x86_64:url) printf '%s\n' 'https://github.com/casey/just/releases/download/1.53.0/just-1.53.0-x86_64-unknown-linux-musl.tar.gz' ;;
    just-linux-x86_64:file) printf '%s\n' 'just-1.53.0-x86_64-unknown-linux-musl.tar.gz' ;;
    just-linux-x86_64:sha256) printf '%s\n' '7fedeb22c7e14d9ef1551e8b793700866d80f409f9884b0e80ebb65c11d4874d' ;;

    mise-linux-x86_64:version) printf '%s\n' 'v2026.6.11' ;;
    mise-linux-x86_64:url) printf '%s\n' 'https://github.com/jdx/mise/releases/download/v2026.6.11/mise-v2026.6.11-linux-x64' ;;
    mise-linux-x86_64:file) printf '%s\n' 'mise-v2026.6.11-linux-x64' ;;
    mise-linux-x86_64:sha256) printf '%s\n' '4c1036af15efea3a4d83f13481132ec7d7dda15e7ec5869dd70a64072bf1a6c9' ;;

    yazi-linux-x86_64:version) printf '%s\n' 'v26.5.6' ;;
    yazi-linux-x86_64:url) printf '%s\n' 'https://github.com/sxyazi/yazi/releases/download/v26.5.6/yazi-x86_64-unknown-linux-gnu.zip' ;;
    yazi-linux-x86_64:file) printf '%s\n' 'yazi-x86_64-unknown-linux-gnu.zip' ;;
    yazi-linux-x86_64:sha256) printf '%s\n' '1c9096f0a83b8102c194385f644cdeff93cc8269426163c9d033041ebd537bd2' ;;

    yq-linux-amd64:version) printf '%s\n' 'v4.53.3' ;;
    yq-linux-amd64:url) printf '%s\n' 'https://github.com/mikefarah/yq/releases/download/v4.53.3/yq_linux_amd64' ;;
    yq-linux-amd64:file) printf '%s\n' 'yq_linux_amd64' ;;
    yq-linux-amd64:sha256) printf '%s\n' 'fa52a4e758c63d38299163fbdd1edfb4c4963247918bf9c1c5d31d84789eded4' ;;

    sd-linux-x86_64:version) printf '%s\n' 'v1.1.0' ;;
    sd-linux-x86_64:url) printf '%s\n' 'https://github.com/chmln/sd/releases/download/v1.1.0/sd-v1.1.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    sd-linux-x86_64:file) printf '%s\n' 'sd-v1.1.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    sd-linux-x86_64:sha256) printf '%s\n' '3613eca74cd686739bb5a6d68319aa56c747e7315274d02323a2ca2b1c5d82d2' ;;

    dust-linux-x86_64:version) printf '%s\n' 'v1.2.4' ;;
    dust-linux-x86_64:url) printf '%s\n' 'https://github.com/bootandy/dust/releases/download/v1.2.4/dust-v1.2.4-x86_64-unknown-linux-gnu.tar.gz' ;;
    dust-linux-x86_64:file) printf '%s\n' 'dust-v1.2.4-x86_64-unknown-linux-gnu.tar.gz' ;;
    dust-linux-x86_64:sha256) printf '%s\n' '707cfdbfb9d2dc536f8c3853815bbe98a01012f2772463835edae06816551160' ;;

    duf-linux-x86_64:version) printf '%s\n' 'v0.9.1' ;;
    duf-linux-x86_64:url) printf '%s\n' 'https://github.com/muesli/duf/releases/download/v0.9.1/duf_0.9.1_linux_x86_64.tar.gz' ;;
    duf-linux-x86_64:file) printf '%s\n' 'duf_0.9.1_linux_x86_64.tar.gz' ;;
    duf-linux-x86_64:sha256) printf '%s\n' '5add851e7062c5e56939abb664705e4d14fa2d06289490aff31d51f153832de7' ;;

    hyperfine-linux-x86_64:version) printf '%s\n' 'v1.20.0' ;;
    hyperfine-linux-x86_64:url) printf '%s\n' 'https://github.com/sharkdp/hyperfine/releases/download/v1.20.0/hyperfine-v1.20.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    hyperfine-linux-x86_64:file) printf '%s\n' 'hyperfine-v1.20.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    hyperfine-linux-x86_64:sha256) printf '%s\n' '63ad53934062118f5b0be11785e0bb1603d4b91667d1921f2fd8df9a8712040a' ;;

    watchexec-linux-x86_64:version) printf '%s\n' 'v2.5.1' ;;
    watchexec-linux-x86_64:url) printf '%s\n' 'https://github.com/watchexec/watchexec/releases/download/v2.5.1/watchexec-2.5.1-x86_64-unknown-linux-gnu.tar.xz' ;;
    watchexec-linux-x86_64:file) printf '%s\n' 'watchexec-2.5.1-x86_64-unknown-linux-gnu.tar.xz' ;;
    watchexec-linux-x86_64:sha256) printf '%s\n' 'cafc381f74e95f8e93e796ef590c7cbbf3409dda6d56cf3dee6109c10e5188ee' ;;

    xh-linux-x86_64:version) printf '%s\n' 'v0.26.1' ;;
    xh-linux-x86_64:url) printf '%s\n' 'https://github.com/ducaale/xh/releases/download/v0.26.1/xh-v0.26.1-x86_64-unknown-linux-musl.tar.gz' ;;
    xh-linux-x86_64:file) printf '%s\n' 'xh-v0.26.1-x86_64-unknown-linux-musl.tar.gz' ;;
    xh-linux-x86_64:sha256) printf '%s\n' 'c411f07a0b204ca07858a67473d0f5c77e332226430d4d84d1d2afd351a425f2' ;;

    lazydocker-linux-x86_64:version) printf '%s\n' 'v0.25.2' ;;
    lazydocker-linux-x86_64:url) printf '%s\n' 'https://github.com/jesseduffield/lazydocker/releases/download/v0.25.2/lazydocker_0.25.2_Linux_x86_64.tar.gz' ;;
    lazydocker-linux-x86_64:file) printf '%s\n' 'lazydocker_0.25.2_Linux_x86_64.tar.gz' ;;
    lazydocker-linux-x86_64:sha256) printf '%s\n' '0d9dbfc26068b218e7ed84b104748cadc6e3cf733c0afd35465306fb39b9523c' ;;

    gitleaks-linux-x64:version) printf '%s\n' 'v8.30.1' ;;
    gitleaks-linux-x64:url) printf '%s\n' 'https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz' ;;
    gitleaks-linux-x64:file) printf '%s\n' 'gitleaks_8.30.1_linux_x64.tar.gz' ;;
    gitleaks-linux-x64:sha256) printf '%s\n' '551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb' ;;

    actionlint-linux-amd64:version) printf '%s\n' 'v1.7.12' ;;
    actionlint-linux-amd64:url) printf '%s\n' 'https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz' ;;
    actionlint-linux-amd64:file) printf '%s\n' 'actionlint_1.7.12_linux_amd64.tar.gz' ;;
    actionlint-linux-amd64:sha256) printf '%s\n' '8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8' ;;

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
