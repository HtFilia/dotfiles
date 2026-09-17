#!/usr/bin/env bash
# Pinned direct-download assets.
# Keep versions, URLs, filenames and SHA256 values in sync with docs/ASSET-MANIFEST.md.

pinned_asset_field() {
  local key="$1" field="$2"
  case "$key:$field" in
    tokei-cargo:version) printf '%s\n' '15.0.0' ;;

    starship-linux-x86_64:version) printf '%s\n' 'v1.26.0' ;;
    starship-linux-x86_64:url) printf '%s\n' 'https://github.com/starship/starship/releases/download/v1.26.0/starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:file) printf '%s\n' 'starship-x86_64-unknown-linux-gnu.tar.gz' ;;
    starship-linux-x86_64:sha256) printf '%s\n' '321f0dd7af8340a5f2e6a8fec6538a04f617486f9ec70d878f91c09cd8deef22' ;;

    eza-linux-x86_64:version) printf '%s\n' 'v0.23.5' ;;
    eza-linux-x86_64:url) printf '%s\n' 'https://github.com/eza-community/eza/releases/download/v0.23.5/eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:file) printf '%s\n' 'eza_x86_64-unknown-linux-gnu.tar.gz' ;;
    eza-linux-x86_64:sha256) printf '%s\n' '35c70c5c43c29108075e58b893234c67ef585f0b53a7eaf8e9e7d4eec9f339b4' ;;

    uv-linux-x86_64:version) printf '%s\n' '0.12.15' ;;
    uv-linux-x86_64:url) printf '%s\n' 'https://github.com/astral-sh/uv/releases/download/0.12.15/uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:file) printf '%s\n' 'uv-x86_64-unknown-linux-gnu.tar.gz' ;;
    uv-linux-x86_64:sha256) printf '%s\n' 'f97935763c04be3e692460a7aaeaaab8fc3b78fcf8b389da820b38ae7423a638' ;;

    lazygit-linux-x86_64:version) printf '%s\n' 'v0.65.1' ;;
    lazygit-linux-x86_64:url) printf '%s\n' 'https://github.com/jesseduffield/lazygit/releases/download/v0.65.1/lazygit_0.65.1_linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:file) printf '%s\n' 'lazygit_0.65.1_linux_x86_64.tar.gz' ;;
    lazygit-linux-x86_64:sha256) printf '%s\n' '02beacbcda0fa342e50ae3480ba8147307353af3fb28e1d5f790e02329c201a6' ;;

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

    mise-linux-x86_64:version) printf '%s\n' 'v2026.9.10' ;;
    mise-linux-x86_64:url) printf '%s\n' 'https://github.com/jdx/mise/releases/download/v2026.9.10/mise-v2026.9.10-linux-x64' ;;
    mise-linux-x86_64:file) printf '%s\n' 'mise-v2026.9.10-linux-x64' ;;
    mise-linux-x86_64:sha256) printf '%s\n' 'f917e52216924ef0a8b4eca3f7004dfcff3b94665716ac5685fd53006a491eee' ;;

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
    # The v1.1.0 workspace still reports sd 1.0.0; pin both the archive and binary.
    sd-linux-x86_64:reported-version) printf '%s\n' '1.0.0' ;;
    sd-linux-x86_64:binary-sha256) printf '%s\n' 'f59292eba50873b61afc520e5b25f23d4fbcb0068d5408a13537c4c98c4dc69f' ;;

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

    watchexec-linux-x86_64:version) printf '%s\n' 'v2.7.3' ;;
    watchexec-linux-x86_64:url) printf '%s\n' 'https://github.com/watchexec/watchexec/releases/download/v2.7.3/watchexec-2.7.3-x86_64-unknown-linux-gnu.tar.xz' ;;
    watchexec-linux-x86_64:file) printf '%s\n' 'watchexec-2.7.3-x86_64-unknown-linux-gnu.tar.xz' ;;
    watchexec-linux-x86_64:sha256) printf '%s\n' '8ace3a1d2e752d189f28b6766311d58f155ab977fae66aba60b111ec8aec2f64' ;;

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

    node-linux-x86_64:version) printf '%s\n' 'v26.9.0' ;;
    node-linux-x86_64:url) printf '%s\n' 'https://nodejs.org/dist/v26.9.0/node-v26.9.0-linux-x64.tar.xz' ;;
    node-linux-x86_64:file) printf '%s\n' 'node-v26.9.0-linux-x64.tar.xz' ;;
    node-linux-x86_64:sha256) printf '%s\n' 'c6ecd8efc1c1d395265891675319da7a7b3785c6be174bd78933cf4f057624d1' ;;

    node-linux-arm64:version) printf '%s\n' 'v26.9.0' ;;
    node-linux-arm64:url) printf '%s\n' 'https://nodejs.org/dist/v26.9.0/node-v26.9.0-linux-arm64.tar.xz' ;;
    node-linux-arm64:file) printf '%s\n' 'node-v26.9.0-linux-arm64.tar.xz' ;;
    node-linux-arm64:sha256) printf '%s\n' '686d07ed3bc5d68d9f7bd4939b7e8849a87d0664ac19c8c5474474f44cc956db' ;;

    chezmoi-linux-amd64:version) printf '%s\n' 'v2.72.2' ;;
    chezmoi-linux-amd64:url) printf '%s\n' 'https://github.com/twpayne/chezmoi/releases/download/v2.72.2/chezmoi_2.72.2_linux_amd64.tar.gz' ;;
    chezmoi-linux-amd64:file) printf '%s\n' 'chezmoi_2.72.2_linux_amd64.tar.gz' ;;
    chezmoi-linux-amd64:sha256) printf '%s\n' 'a2be1b8bcdf06c6f173e070bb3ddbcc52c50478fe9b57f6e6c63d15c7cff4f03' ;;

    chezmoi-linux-arm64:version) printf '%s\n' 'v2.72.2' ;;
    chezmoi-linux-arm64:url) printf '%s\n' 'https://github.com/twpayne/chezmoi/releases/download/v2.72.2/chezmoi_2.72.2_linux_arm64.tar.gz' ;;
    chezmoi-linux-arm64:file) printf '%s\n' 'chezmoi_2.72.2_linux_arm64.tar.gz' ;;
    chezmoi-linux-arm64:sha256) printf '%s\n' '499925fd10804b7c1a5dc4b4a275c8935261d02a4be0c18bbd41b7747810de67' ;;

    go-linux-amd64:version) printf '%s\n' '1.27.1' ;;
    go-linux-amd64:url) printf '%s\n' 'https://go.dev/dl/go1.27.1.linux-amd64.tar.gz' ;;
    go-linux-amd64:file) printf '%s\n' 'go1.27.1.linux-amd64.tar.gz' ;;
    go-linux-amd64:sha256) printf '%s\n' '63d339f0da5ab53635a56f2490a7984dfe12dfcff22ad749f63edaf590168445' ;;

    go-linux-arm64:version) printf '%s\n' '1.27.1' ;;
    go-linux-arm64:url) printf '%s\n' 'https://go.dev/dl/go1.27.1.linux-arm64.tar.gz' ;;
    go-linux-arm64:file) printf '%s\n' 'go1.27.1.linux-arm64.tar.gz' ;;
    go-linux-arm64:sha256) printf '%s\n' '3450b45a3f9ee8568792736a5c5e70a1f2e9b36c35a8f74958c03e51d7d92bec' ;;

    fzf-linux-x86_64:version) printf '%s\n' '0.74.4' ;;
    fzf-linux-x86_64:url) printf '%s\n' 'https://github.com/junegunn/fzf/releases/download/v0.74.4/fzf-0.74.4-linux_amd64.tar.gz' ;;
    fzf-linux-x86_64:file) printf '%s\n' 'fzf-0.74.4-linux_amd64.tar.gz' ;;
    fzf-linux-x86_64:sha256) printf '%s\n' '05e6813a337cc722c3ed07e54a764b75cc5d671e2e60459db0ba696ee5fa7504' ;;

    rg-linux-x86_64:version) printf '%s\n' '15.2.0' ;;
    rg-linux-x86_64:url) printf '%s\n' 'https://github.com/BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-x86_64-unknown-linux-musl.tar.gz' ;;
    rg-linux-x86_64:file) printf '%s\n' 'ripgrep-15.2.0-x86_64-unknown-linux-musl.tar.gz' ;;
    rg-linux-x86_64:sha256) printf '%s\n' '33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c' ;;

    bat-linux-x86_64:version) printf '%s\n' '0.26.1' ;;
    bat-linux-x86_64:url) printf '%s\n' 'https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz' ;;
    bat-linux-x86_64:file) printf '%s\n' 'bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz' ;;
    bat-linux-x86_64:sha256) printf '%s\n' '0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191' ;;

    fd-linux-x86_64:version) printf '%s\n' '10.5.0' ;;
    fd-linux-x86_64:url) printf '%s\n' 'https://github.com/sharkdp/fd/releases/download/v10.5.0/fd-v10.5.0-x86_64-unknown-linux-musl.tar.gz' ;;
    fd-linux-x86_64:file) printf '%s\n' 'fd-v10.5.0-x86_64-unknown-linux-musl.tar.gz' ;;
    fd-linux-x86_64:sha256) printf '%s\n' '761c72dc8e120d85b22292063be8a796e2eeb20eb3e4f38b8fa2343ccf3514a7' ;;

    zoxide-linux-x86_64:version) printf '%s\n' '0.10.0' ;;
    zoxide-linux-x86_64:url) printf '%s\n' 'https://github.com/ajeetdsouza/zoxide/releases/download/v0.10.0/zoxide-0.10.0-x86_64-unknown-linux-musl.tar.gz' ;;
    zoxide-linux-x86_64:file) printf '%s\n' 'zoxide-0.10.0-x86_64-unknown-linux-musl.tar.gz' ;;
    zoxide-linux-x86_64:sha256) printf '%s\n' '2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae' ;;

    atuin-linux-x86_64:version) printf '%s\n' '18.22.0' ;;
    atuin-linux-x86_64:url) printf '%s\n' 'https://github.com/atuinsh/atuin/releases/download/v18.22.0/atuin-x86_64-unknown-linux-musl.tar.gz' ;;
    atuin-linux-x86_64:file) printf '%s\n' 'atuin-x86_64-unknown-linux-musl.tar.gz' ;;
    atuin-linux-x86_64:sha256) printf '%s\n' 'b3c123df1887cf27c6480a87d148c86831cd83da478e0a8ab773ca188f3f3222' ;;

    direnv-linux-x86_64:version) printf '%s\n' '2.37.1' ;;
    direnv-linux-x86_64:url) printf '%s\n' 'https://github.com/direnv/direnv/releases/download/v2.37.1/direnv.linux-amd64' ;;
    direnv-linux-x86_64:file) printf '%s\n' 'direnv.linux-amd64' ;;
    direnv-linux-x86_64:sha256) printf '%s\n' '1f1b93dd6f38523fde26dfac96151ef9d31a374e3005cd3345fb93555ae0c9b5' ;;

    jq-linux-x86_64:version) printf '%s\n' '1.8.2' ;;
    jq-linux-x86_64:url) printf '%s\n' 'https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-linux-amd64' ;;
    jq-linux-x86_64:file) printf '%s\n' 'jq-linux-amd64' ;;
    jq-linux-x86_64:sha256) printf '%s\n' 'b1c22172dd303f3be49e935aa56aa48a8b7a46e0bc838b4997d3bb451495870f' ;;

    btop-linux-x86_64:version) printf '%s\n' '1.4.7' ;;
    btop-linux-x86_64:url) printf '%s\n' 'https://github.com/aristocratos/btop/releases/download/v1.4.7/btop-x86_64-unknown-linux-musl.tar.gz' ;;
    btop-linux-x86_64:file) printf '%s\n' 'btop-x86_64-unknown-linux-musl.tar.gz' ;;
    btop-linux-x86_64:sha256) printf '%s\n' '5099054dd6a101bd12eb6ff3702a9a6a3f57aaa27923a0da478ae5b517faf335' ;;

    tmux-linux-x86_64:version) printf '%s\n' '3.7c' ;;
    tmux-linux-x86_64:url) printf '%s\n' 'https://github.com/tmux/tmux/releases/download/3.7c/tmux-3.7c.tar.gz' ;;
    tmux-linux-x86_64:file) printf '%s\n' 'tmux-3.7c.tar.gz' ;;
    tmux-linux-x86_64:sha256) printf '%s\n' '7c60cae9a0e25288e2e24750aafc9e8800fc7fd4555e447e1b29ee4201cfb3bf' ;;

    ouch-linux-x86_64:version) printf '%s\n' '0.8.3' ;;
    ouch-linux-x86_64:url) printf '%s\n' 'https://github.com/ouch-org/ouch/releases/download/0.8.3/ouch-x86_64-unknown-linux-musl.tar.gz' ;;
    ouch-linux-x86_64:file) printf '%s\n' 'ouch-x86_64-unknown-linux-musl.tar.gz' ;;
    ouch-linux-x86_64:sha256) printf '%s\n' 'eaab9b997a823f584557ac5f85205105ae577a4c4fbd23926b686469cfa19881' ;;

    ov-linux-x86_64:version) printf '%s\n' '0.54.0' ;;
    ov-linux-x86_64:url) printf '%s\n' 'https://github.com/noborus/ov/releases/download/v0.54.0/ov_0.54.0_linux_amd64.zip' ;;
    ov-linux-x86_64:file) printf '%s\n' 'ov_0.54.0_linux_amd64.zip' ;;
    ov-linux-x86_64:sha256) printf '%s\n' 'f26ef7b180dbc6bb07677f31d0a73629528b30624cb6203919f23dc6d54f9797' ;;

    hexyl-linux-x86_64:version) printf '%s\n' '0.17.0' ;;
    hexyl-linux-x86_64:url) printf '%s\n' 'https://github.com/sharkdp/hexyl/releases/download/v0.17.0/hexyl-v0.17.0-x86_64-unknown-linux-musl.tar.gz' ;;
    hexyl-linux-x86_64:file) printf '%s\n' 'hexyl-v0.17.0-x86_64-unknown-linux-musl.tar.gz' ;;
    hexyl-linux-x86_64:sha256) printf '%s\n' '82b374b800cc965f4116b9d5d6a50394945170d4f65b9ef6ced3b82b014de8a6' ;;

    dua-linux-x86_64:version) printf '%s\n' '2.45.0' ;;
    dua-linux-x86_64:url) printf '%s\n' 'https://github.com/Byron/dua-cli/releases/download/v2.45.0/dua-v2.45.0-x86_64-unknown-linux-musl.tar.gz' ;;
    dua-linux-x86_64:file) printf '%s\n' 'dua-v2.45.0-x86_64-unknown-linux-musl.tar.gz' ;;
    dua-linux-x86_64:sha256) printf '%s\n' 'd0b972f5bbcab2260db791bae3796f61f22d6df7f1b3707aeb2eed9aa281e4cd' ;;

    broot-linux-x86_64:version) printf '%s\n' '1.60.1' ;;
    broot-linux-x86_64:url) printf '%s\n' 'https://github.com/Canop/broot/releases/download/v1.60.1/broot_1.60.1.zip' ;;
    broot-linux-x86_64:file) printf '%s\n' 'broot_1.60.1.zip' ;;
    broot-linux-x86_64:sha256) printf '%s\n' 'de4a054424ac01ef73fb30c3b3fac0cda437e7426388085d7467b5e0aaa1cb55' ;;

    czkawka_cli-linux-x86_64:version) printf '%s\n' '12.0.2' ;;
    czkawka_cli-linux-x86_64:url) printf '%s\n' 'https://github.com/qarmin/czkawka/releases/download/12.0.2/linux_czkawka_cli_musl' ;;
    czkawka_cli-linux-x86_64:file) printf '%s\n' 'linux_czkawka_cli_musl' ;;
    czkawka_cli-linux-x86_64:sha256) printf '%s\n' 'e90381d8c38479a97f9e98335523208ac285b6e4bcac10f41db791d04a51b14a' ;;

    xcp-linux-x86_64:version) printf '%s\n' '0.24.8' ;;
    xcp-linux-x86_64:url) printf '%s\n' 'https://github.com/tarka/xcp/releases/download/xcp-v0.24.8/xcp-v0.24.8-x86_64-unknown-linux-gnu.tar.gz' ;;
    xcp-linux-x86_64:file) printf '%s\n' 'xcp-v0.24.8-x86_64-unknown-linux-gnu.tar.gz' ;;
    xcp-linux-x86_64:sha256) printf '%s\n' 'b7163f44c837fe8f7e3cc147bfe5db96841c9f65252f0f17cda885db3bc97331' ;;

    viu-linux-x86_64:version) printf '%s\n' '1.6.1' ;;
    viu-linux-x86_64:url) printf '%s\n' 'https://github.com/atanunq/viu/releases/download/v1.6.1/viu-x86_64-unknown-linux-musl' ;;
    viu-linux-x86_64:file) printf '%s\n' 'viu-x86_64-unknown-linux-musl' ;;
    viu-linux-x86_64:sha256) printf '%s\n' 'f108265ff0441406290d5f53f64a2b88d4db530a7389a5dcd771bf782aa3ec6e' ;;

    vivid-linux-x86_64:version) printf '%s\n' '0.11.1' ;;
    vivid-linux-x86_64:url) printf '%s\n' 'https://github.com/sharkdp/vivid/releases/download/v0.11.1/vivid-v0.11.1-x86_64-unknown-linux-musl.tar.gz' ;;
    vivid-linux-x86_64:file) printf '%s\n' 'vivid-v0.11.1-x86_64-unknown-linux-musl.tar.gz' ;;
    vivid-linux-x86_64:sha256) printf '%s\n' 'f1a80a39c75ceae43c4187f302e66c0a45d941ed1479456a0d5ddef665663181' ;;

    pastel-linux-x86_64:version) printf '%s\n' '0.12.0' ;;
    pastel-linux-x86_64:url) printf '%s\n' 'https://github.com/sharkdp/pastel/releases/download/v0.12.0/pastel-v0.12.0-x86_64-unknown-linux-musl.tar.gz' ;;
    pastel-linux-x86_64:file) printf '%s\n' 'pastel-v0.12.0-x86_64-unknown-linux-musl.tar.gz' ;;
    pastel-linux-x86_64:sha256) printf '%s\n' '96ddd6593d08fd3868f2423f18ed5c6117a5f1aab335c1fc9e8347db7f219f2a' ;;

    tldr-linux-x86_64:version) printf '%s\n' '1.9.0' ;;
    tldr-linux-x86_64:url) printf '%s\n' 'https://github.com/tealdeer-rs/tealdeer/releases/download/v1.9.0/tealdeer-linux-x86_64-musl' ;;
    tldr-linux-x86_64:file) printf '%s\n' 'tealdeer-linux-x86_64-musl' ;;
    tldr-linux-x86_64:sha256) printf '%s\n' 'dc7263b550e90c0689ea2cb434e3144469805d5dddecbb1f7fc534e1185b7408' ;;

    jc-linux-x86_64:version) printf '%s\n' '1.25.7' ;;
    jc-linux-x86_64:url) printf '%s\n' 'https://github.com/kellyjonbrazil/jc/releases/download/v1.25.7/jc-1.25.7-linux-x86_64.tar.gz' ;;
    jc-linux-x86_64:file) printf '%s\n' 'jc-1.25.7-linux-x86_64.tar.gz' ;;
    jc-linux-x86_64:sha256) printf '%s\n' '5b7ab595bfbaa70f07a15136bbc3c09d6dbf65891248bf1f060ec3da29608a2c' ;;

    jless-linux-x86_64:version) printf '%s\n' '0.9.0' ;;
    jless-linux-x86_64:url) printf '%s\n' 'https://github.com/PaulJuliusMartinez/jless/releases/download/v0.9.0/jless-v0.9.0-x86_64-unknown-linux-gnu.zip' ;;
    jless-linux-x86_64:file) printf '%s\n' 'jless-v0.9.0-x86_64-unknown-linux-gnu.zip' ;;
    jless-linux-x86_64:sha256) printf '%s\n' 'a1e0eb63ef347adc649989ac5c7d2dc896df6d494622b953c86e3a248e733a93' ;;

    fastfetch-linux-x86_64:version) printf '%s\n' '2.68.1' ;;
    fastfetch-linux-x86_64:url) printf '%s\n' 'https://github.com/fastfetch-cli/fastfetch/releases/download/2.68.1/fastfetch-linux-amd64.tar.gz' ;;
    fastfetch-linux-x86_64:file) printf '%s\n' 'fastfetch-linux-amd64.tar.gz' ;;
    fastfetch-linux-x86_64:sha256) printf '%s\n' '0c51ef6fa3e976eb5038fe0afda38629d3ca07947740bb0e3354c7c4f1238c0c' ;;

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
  if binary_sha="$(pinned_asset_field "$key" binary-sha256 2>/dev/null)"; then
    verify_sha256 "$(command -v "$tool")" "$binary_sha" || return 1
    expected="$(pinned_asset_field "$key" reported-version)" || return 1
  fi
  expected="${expected#v}"
  expected="${expected//./\\.}"
  printf '%s\n' "$output" | grep -Eq "(^|[^0-9.])$expected([^0-9.]|$)"
}

# Replace the destination itself, never follow an existing fd/bat symlink into /usr.
atomic_install_binary() {
  local source="$1" destination="$2" stage
  stage="$(mktemp "${destination}.XXXXXX")" || return 1
  if install -m 755 "$source" "$stage"; then
    mv -f "$stage" "$destination"
  else
    rm -f "$stage"
    return 1
  fi
}
