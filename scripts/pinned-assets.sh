#!/usr/bin/env bash
# Pinned direct-download assets.
# Keep versions, URLs, filenames and SHA256 values in sync with docs/ASSET-MANIFEST.md.

pinned_asset_field() {
  local key="$1" field="$2"
  case "$key:$field" in
    tokei-cargo:version) printf '%s\n' '14.0.0' ;;
    starship-linux-x86_64:version) printf '%s\n' 'v1.26.0' ;;
    starship-linux-x86_64:url) printf '%s\n' 'https://github.com/starship/starship/releases/download/v1.26.0/starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:file) printf '%s\n' 'starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:sha256) printf '%s\n' '321f0dd7af8340a5f2e6a8fec6538a04f617486f9ec70d878f91c09cd8deef22' ;;

    eza-linux-x86_64:version) printf '%s\n' 'v0.23.5' ;;
    eza-linux-x86_64:url) printf '%s\n' 'https://github.com/eza-community/eza/releases/download/v0.23.5/eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:file) printf '%s\n' 'eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:sha256) printf '%s\n' '35c70c5c43c29108075e58b893234c67ef585f0b53a7eaf8e9e7d4eec9f339b4' ;;

    uv-linux-x86_64:version) printf '%s\n' '0.12.13' ;;
    uv-linux-x86_64:url) printf '%s\n' 'https://github.com/astral-sh/uv/releases/download/0.12.13/uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:file) printf '%s\n' 'uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:sha256) printf '%s\n' '745765a3b6e360ad76743599ae5c42e9278c7edf8bbff9fc76d05bf2623a04dd' ;;

    lazygit-linux-x86_64:version) printf '%s\n' 'v0.65.0' ;;
    lazygit-linux-x86_64:url) printf '%s\n' 'https://github.com/jesseduffield/lazygit/releases/download/v0.65.0/lazygit_0.65.0_linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:file) printf '%s\n' 'lazygit_0.65.0_linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:sha256) printf '%s\n' '44d8e7dd1484b4a66e191bd4ab25a71e8b4b3a65ab122f838e65677ef58c5506' ;;

    delta-linux-x86_64:version) printf '%s\n' '0.19.2' ;;
    delta-linux-x86_64:url) printf '%s\n' 'https://github.com/dandavison/delta/releases/download/0.19.2/delta-0.19.2-x86_64-unknown-linux-gnu.tar.gz' ;;
    delta-linux-x86_64:file) printf '%s\n' 'delta-0.19.2-x86_64-unknown-linux-gnu.tar.gz' ;;
    delta-linux-x86_64:sha256) printf '%s\n' '8e695c5f586a8c53d6c3b01be0b4a422ed218bfed2a56191caebe373a1c18ab2' ;;

    firacode:version) printf '%s\n' 'v3.5.1' ;;
    firacode:url) printf '%s\n' 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/FiraCode.zip' ;;
    firacode:file) printf '%s\n' 'FiraCode.zip' ;;
    firacode:sha256) printf '%s\n' '239395baf60c89b2eaf4862b6b09db0ef95605cd3e8eef51c00345822a81a665' ;;

    neovim-linux-x86_64:version) printf '%s\n' 'v0.12.5' ;;
    neovim-linux-x86_64:url) printf '%s\n' 'https://github.com/neovim/neovim/releases/download/v0.12.5/nvim-linux-x86_64.tar.gz' ;;
    neovim-linux-x86_64:file) printf '%s\n' 'nvim-linux-x86_64.tar.gz' ;;
    neovim-linux-x86_64:sha256) printf '%s\n' 'bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875' ;;

    just-linux-x86_64:version) printf '%s\n' '1.58.0' ;;
    just-linux-x86_64:url) printf '%s\n' 'https://github.com/casey/just/releases/download/1.58.0/just-1.58.0-x86_64-unknown-linux-musl.tar.gz' ;;
    just-linux-x86_64:file) printf '%s\n' 'just-1.58.0-x86_64-unknown-linux-musl.tar.gz' ;;
    just-linux-x86_64:sha256) printf '%s\n' '4a5cc2f53e6f0f8c59092a6cc38291eb729d46a7dd95d3ae582008881b84931d' ;;

    mise-linux-x86_64:version) printf '%s\n' 'v2026.9.5' ;;
    mise-linux-x86_64:url) printf '%s\n' 'https://github.com/jdx/mise/releases/download/v2026.9.5/mise-v2026.9.5-linux-x64' ;;
    mise-linux-x86_64:file) printf '%s\n' 'mise-v2026.9.5-linux-x64' ;;
    mise-linux-x86_64:sha256) printf '%s\n' '32f644d8c291bb182f702c6d2b0dda9f8b01441e940d74d328aad5f08446b2fd' ;;

    yazi-linux-x86_64:version) printf '%s\n' 'v26.9.1' ;;
    yazi-linux-x86_64:url) printf '%s\n' 'https://github.com/sxyazi/yazi/releases/download/v26.9.1/yazi-x86_64-unknown-linux-gnu.zip' ;;
    yazi-linux-x86_64:file) printf '%s\n' 'yazi-x86_64-unknown-linux-gnu.zip' ;;
    yazi-linux-x86_64:sha256) printf '%s\n' 'a02fe91d3304294048c681f010f1100856872a4e98ecf6927328e888d40a6ad2' ;;

    yq-linux-amd64:version) printf '%s\n' 'v4.53.6' ;;
    yq-linux-amd64:url) printf '%s\n' 'https://github.com/mikefarah/yq/releases/download/v4.53.6/yq_linux_amd64' ;;
    yq-linux-amd64:file) printf '%s\n' 'yq_linux_amd64' ;;
    yq-linux-amd64:sha256) printf '%s\n' 'c5f056448f973ae7d39b5401949648a78f2dc1947d6a8eb65be60d5c504b9385' ;;

    sd-linux-x86_64:version) printf '%s\n' 'v1.1.0' ;;
    sd-linux-x86_64:url) printf '%s\n' 'https://github.com/chmln/sd/releases/download/v1.1.0/sd-v1.1.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    sd-linux-x86_64:file) printf '%s\n' 'sd-v1.1.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    sd-linux-x86_64:sha256) printf '%s\n' '3613eca74cd686739bb5a6d68319aa56c747e7315274d02323a2ca2b1c5d82d2' ;;

    dust-linux-x86_64:version) printf '%s\n' 'v1.2.5' ;;
    dust-linux-x86_64:url) printf '%s\n' 'https://github.com/bootandy/dust/releases/download/v1.2.5/dust-v1.2.5-x86_64-unknown-linux-gnu.tar.gz' ;;
    dust-linux-x86_64:file) printf '%s\n' 'dust-v1.2.5-x86_64-unknown-linux-gnu.tar.gz' ;;
    dust-linux-x86_64:sha256) printf '%s\n' '64b16f5c10cc4c25d2eaa144e9d2d44b3ed8f72ee63b3bc0a92c85e21e9e0932' ;;

    duf-linux-x86_64:version) printf '%s\n' 'v0.9.1' ;;
    duf-linux-x86_64:url) printf '%s\n' 'https://github.com/muesli/duf/releases/download/v0.9.1/duf_0.9.1_linux_x86_64.tar.gz' ;;
    duf-linux-x86_64:file) printf '%s\n' 'duf_0.9.1_linux_x86_64.tar.gz' ;;
    duf-linux-x86_64:sha256) printf '%s\n' '5add851e7062c5e56939abb664705e4d14fa2d06289490aff31d51f153832de7' ;;

    hyperfine-linux-x86_64:version) printf '%s\n' 'v1.20.0' ;;
    hyperfine-linux-x86_64:url) printf '%s\n' 'https://github.com/sharkdp/hyperfine/releases/download/v1.20.0/hyperfine-v1.20.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    hyperfine-linux-x86_64:file) printf '%s\n' 'hyperfine-v1.20.0-x86_64-unknown-linux-gnu.tar.gz' ;;
    hyperfine-linux-x86_64:sha256) printf '%s\n' '63ad53934062118f5b0be11785e0bb1603d4b91667d1921f2fd8df9a8712040a' ;;

    watchexec-linux-x86_64:version) printf '%s\n' 'v2.7.2' ;;
    watchexec-linux-x86_64:url) printf '%s\n' 'https://github.com/watchexec/watchexec/releases/download/v2.7.2/watchexec-2.7.2-x86_64-unknown-linux-gnu.tar.xz' ;;
    watchexec-linux-x86_64:file) printf '%s\n' 'watchexec-2.7.2-x86_64-unknown-linux-gnu.tar.xz' ;;
    watchexec-linux-x86_64:sha256) printf '%s\n' 'b5b3cf6fd45ce2503bae90ba4017f85d62314b427b91c06818ff39a4c46930c4' ;;

    xh-linux-x86_64:version) printf '%s\n' 'v0.26.2' ;;
    xh-linux-x86_64:url) printf '%s\n' 'https://github.com/ducaale/xh/releases/download/v0.26.2/xh-v0.26.2-x86_64-unknown-linux-musl.tar.gz' ;;
    xh-linux-x86_64:file) printf '%s\n' 'xh-v0.26.2-x86_64-unknown-linux-musl.tar.gz' ;;
    xh-linux-x86_64:sha256) printf '%s\n' '8c53b6a23435754f9e2ea8ab8c0d0296a1921404b88132cf9b364ff6e8c22a6e' ;;

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

    node-linux-x86_64:version) printf '%s\n' 'v24.21.0' ;;
    node-linux-x86_64:url) printf '%s\n' 'https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.xz' ;;
    node-linux-x86_64:file) printf '%s\n' 'node-v24.21.0-linux-x64.tar.xz' ;;
    node-linux-x86_64:sha256) printf '%s\n' 'fd8e59d5a511510f6a298afb548f18c7d2b1be404d8b4a27d94fbe49f56cb2d6' ;;

    node-linux-arm64:version) printf '%s\n' 'v24.21.0' ;;
    node-linux-arm64:url) printf '%s\n' 'https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-arm64.tar.xz' ;;
    node-linux-arm64:file) printf '%s\n' 'node-v24.21.0-linux-arm64.tar.xz' ;;
    node-linux-arm64:sha256) printf '%s\n' '6ad1325edbdb5649c379b75a237147a666c95d4f9ae8d340fef2d1575d289ad2' ;;

    chezmoi-linux-amd64:version) printf '%s\n' 'v2.72.1' ;;
    chezmoi-linux-amd64:url) printf '%s\n' 'https://github.com/twpayne/chezmoi/releases/download/v2.72.1/chezmoi_2.72.1_linux_amd64.tar.gz' ;;
    chezmoi-linux-amd64:file) printf '%s\n' 'chezmoi_2.72.1_linux_amd64.tar.gz' ;;
    chezmoi-linux-amd64:sha256) printf '%s\n' '9f97d32caca166e5c92160ec3a9325519809c38963121cef38173142065c981f' ;;

    chezmoi-linux-arm64:version) printf '%s\n' 'v2.72.1' ;;
    chezmoi-linux-arm64:url) printf '%s\n' 'https://github.com/twpayne/chezmoi/releases/download/v2.72.1/chezmoi_2.72.1_linux_arm64.tar.gz' ;;
    chezmoi-linux-arm64:file) printf '%s\n' 'chezmoi_2.72.1_linux_arm64.tar.gz' ;;
    chezmoi-linux-arm64:sha256) printf '%s\n' '75508ef41216b6d64f3145986b751729d7f92d09c6bad77d51cf2895ab35a508' ;;

    go-linux-amd64:version) printf '%s\n' '1.26.8' ;;
    go-linux-amd64:url) printf '%s\n' 'https://go.dev/dl/go1.26.8.linux-amd64.tar.gz' ;;
    go-linux-amd64:file) printf '%s\n' 'go1.26.8.linux-amd64.tar.gz' ;;
    go-linux-amd64:sha256) printf '%s\n' 'd0f743b33e8d8945e6b1f432edd15785c70507121d6e2a723b21285eddf8b57b' ;;

    go-linux-arm64:version) printf '%s\n' '1.26.8' ;;
    go-linux-arm64:url) printf '%s\n' 'https://go.dev/dl/go1.26.8.linux-arm64.tar.gz' ;;
    go-linux-arm64:file) printf '%s\n' 'go1.26.8.linux-arm64.tar.gz' ;;
    go-linux-arm64:sha256) printf '%s\n' '211ffced9dcb9633a55eac6364816ec0ddd951389a740e88fa8b3337971bdda0' ;;

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
  local partial
  partial="$(mktemp "$dest_dir/$file.part.XXXXXX")" || return 1
  if curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    --retry 3 --connect-timeout 15 "$url" -o "$partial" && verify_sha256 "$partial" "$sha"; then
    mv "$partial" "$dest_dir/$file"
  else
    rm -f "$partial"
    return 1
  fi
}

require_pinned_file() {
  local key="$1" dir="$2" file sha
  file="$(pinned_asset_field "$key" file)" || return 1
  sha="$(pinned_asset_field "$key" sha256)" || return 1
  [[ -f "$dir/$file" ]] || return 2
  verify_sha256 "$dir/$file" "$sha"
}

# Versioned cache paths avoid collisions for upstream filenames without versions.
cached_asset_path() {
  local key="$1" cache="$2" file version directory
  file="$(pinned_asset_field "$key" file)" || return 1
  version="$(pinned_asset_field "$key" version)" || return 1
  directory="$cache/$key/$version"
  if ! require_pinned_file "$key" "$directory"; then
    download_pinned_asset "$key" "$directory" || return 1
  fi
  printf '%s\n' "$directory/$file"
}

extract_pinned_archive() {
  local archive="$1" destination="$2"
  case "$archive" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$destination" ;;
    *.tar.xz) tar -xJf "$archive" -C "$destination" ;;
    *.zip) unzip -oq "$archive" -d "$destination" ;;
    *) return 1 ;;
  esac
}

asset_version_matches() {
  local tool="$1" key="$2" argument="${3:---version}" expected output
  command -v "$tool" >/dev/null 2>&1 || return 1
  expected="$(pinned_asset_field "$key" version)" || return 1
  output="$("$tool" "$argument" 2>&1)" || return 1
  expected="${expected#v}"
  expected="${expected//./\\.}"
  printf '%s\n' "$output" | grep -Eq "(^|[^0-9.])$expected([^0-9.]|$)"
}
