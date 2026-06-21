# Asset Manifest

Linux installs use apt first, then exact direct-download assets for tools where
the distro packages are missing, too old, or not available in the expected
channel. Each downloaded file is verified against the SHA256 value in
[`scripts/pinned-assets.sh`](../scripts/pinned-assets.sh) before installation or
extraction.

Keep this document and `scripts/pinned-assets.sh` in sync.

| Tool | Version | Filename | SHA256 |
|---|---:|---|---|
| starship | `v1.25.1` | `starship-x86_64-unknown-linux-gnu.tar.gz` | `4488c11ca632327d1f1f16fb2f102c0646094c35479cd5435991385da43c61ac` |
| eza | `v0.23.4` | `eza_x86_64-unknown-linux-gnu.tar.gz` | `0c38665440226cd8bef5d1d4f3bc6ff77c927fb0d68b752739105db7ab5b358d` |
| uv | `0.11.23` | `uv-x86_64-unknown-linux-gnu.tar.gz` | `e12c4cda2fe8c305510a78380a88f2c32a27e90cdcd123cefd2873388f0ebb5f` |
| lazygit | `v0.62.2` | `lazygit_0.62.2_linux_x86_64.tar.gz` | `8b9a4c2d0969cbea92b45c956dd2a44e1ba76900c9df49f1c60984045ce77984` |
| git-delta | `0.19.2` | `delta-0.19.2-x86_64-unknown-linux-gnu.tar.gz` | `8e695c5f586a8c53d6c3b01be0b4a422ed218bfed2a56191caebe373a1c18ab2` |
| FiraCode Nerd Font | `v3.4.0` | `FiraCode.zip` | `7cc4ffd8f7a1fc914cdab7b149808298165ff7a7f40e40d82dea9ebe41e8ca0b` |
| Neovim | `v0.12.3` | `nvim-linux-x86_64.tar.gz` | `c441b547142860bf01bcce39e36cbed185c41112813e15443b16e5237750724d` |
| Node.js LTS | `v24.17.0` | `node-v24.17.0-linux-x64.tar.xz` | `ab343a1b747c7cbf3630dfd7dbf818c5423fab2eb4f5ad1afc896f6bd121a917` |
| Node.js LTS | `v24.17.0` | `node-v24.17.0-linux-arm64.tar.xz` | `67324b9e515e7d13da72571a5dd522bb23145a820f7dde15497897e466759ab3` |
| Chezmoi | `v2.70.5` | `chezmoi_2.70.5_linux_amd64.tar.gz` | `6a76a0ac3718f0d45b34b4b57067f9556f8f6042e3da710a3c496838362aca14` |
| Chezmoi | `v2.70.5` | `chezmoi_2.70.5_linux_arm64.tar.gz` | `4f4f31d0a10ed3b955e814a5ae20075426e27c9d3a09f536bfa4a6c8718353f2` |
| Go | `1.26.4` | `go1.26.4.linux-amd64.tar.gz` | `1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f` |
| Go | `1.26.4` | `go1.26.4.linux-arm64.tar.gz` | `ef758ae7c6cf9267c9c0ef080b8965f453d89ab2d25d9eb22de4405925238768` |
| just | `1.53.0` | `just-1.53.0-x86_64-unknown-linux-musl.tar.gz` | `7fedeb22c7e14d9ef1551e8b793700866d80f409f9884b0e80ebb65c11d4874d` |
| mise | `v2026.6.11` | `mise-v2026.6.11-linux-x64` | `4c1036af15efea3a4d83f13481132ec7d7dda15e7ec5869dd70a64072bf1a6c9` |
| yazi | `v26.5.6` | `yazi-x86_64-unknown-linux-gnu.zip` | `1c9096f0a83b8102c194385f644cdeff93cc8269426163c9d033041ebd537bd2` |
| yq | `v4.53.3` | `yq_linux_amd64` | `fa52a4e758c63d38299163fbdd1edfb4c4963247918bf9c1c5d31d84789eded4` |
| sd | `v1.1.0` | `sd-v1.1.0-x86_64-unknown-linux-gnu.tar.gz` | `3613eca74cd686739bb5a6d68319aa56c747e7315274d02323a2ca2b1c5d82d2` |
| dust | `v1.2.4` | `dust-v1.2.4-x86_64-unknown-linux-gnu.tar.gz` | `707cfdbfb9d2dc536f8c3853815bbe98a01012f2772463835edae06816551160` |
| duf | `v0.9.1` | `duf_0.9.1_linux_x86_64.tar.gz` | `5add851e7062c5e56939abb664705e4d14fa2d06289490aff31d51f153832de7` |
| hyperfine | `v1.20.0` | `hyperfine-v1.20.0-x86_64-unknown-linux-gnu.tar.gz` | `63ad53934062118f5b0be11785e0bb1603d4b91667d1921f2fd8df9a8712040a` |
| watchexec | `v2.5.1` | `watchexec-2.5.1-x86_64-unknown-linux-gnu.tar.xz` | `cafc381f74e95f8e93e796ef590c7cbbf3409dda6d56cf3dee6109c10e5188ee` |
| xh | `v0.26.1` | `xh-v0.26.1-x86_64-unknown-linux-musl.tar.gz` | `c411f07a0b204ca07858a67473d0f5c77e332226430d4d84d1d2afd351a425f2` |
| lazydocker | `v0.25.2` | `lazydocker_0.25.2_Linux_x86_64.tar.gz` | `0d9dbfc26068b218e7ed84b104748cadc6e3cf733c0afd35465306fb39b9523c` |
| gitleaks | `v8.30.1` | `gitleaks_8.30.1_linux_x64.tar.gz` | `551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb` |
| actionlint | `v1.7.12` | `actionlint_1.7.12_linux_amd64.tar.gz` | `8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8` |

## Update process

1. Update the version, URL, filename, and SHA256 in `scripts/pinned-assets.sh`.
2. Mirror the table row here.
3. Run `bash -n scripts/*.sh`.
4. Run `shellcheck scripts/*.sh`.
5. Run `bash tests/script-contracts.sh`.
