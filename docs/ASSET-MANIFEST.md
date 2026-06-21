# Asset Manifest

Linux installs use apt first, then exact direct-download assets for tools where
the distro packages are missing, too old, or not available in the expected
channel. Each downloaded file is verified against the SHA256 value in
[`scripts/pinned-assets.sh`](../scripts/pinned-assets.sh) before extraction.

Keep this document and `scripts/pinned-assets.sh` in sync.

| Tool | Version | Filename | SHA256 |
|---|---:|---|---|
| starship | `v1.23.0` | `starship-x86_64-unknown-linux-gnu.tar.gz` | `cef41df04378c6f692913c5d9c1032d3b9a4369a1d2f3296c8300ed8838c2197` |
| eza | `v0.21.5` | `eza_x86_64-unknown-linux-gnu.tar.gz` | `f49f764340d13379013213dbffc6e0d78cba7b0f9b9388be9306eb0c69914dd1` |
| uv | `0.6.17` | `uv-x86_64-unknown-linux-gnu.tar.gz` | `720ec28f7a94aa8cd91d3d57dec1434d64b9ae13d1dd6a25f4c0cdb837ba9cf6` |
| lazygit | `v0.48.0` | `lazygit_0.48.0_Linux_x86_64.tar.gz` | `291722c643a10805de3bd7b58f51d5275878269aeadb046709708f8683f558d7` |
| git-delta | `0.18.2` | `delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz` | `99607c43238e11a77fe90a914d8c2d64961aff84b60b8186c1b5691b39955b0f` |
| FiraCode Nerd Font | `v3.3.0` | `FiraCode.zip` | `89978e6f870d044286a339161d5ed961569744b1cd2afee62337fa140cd0b397` |
| Neovim | `v0.10.4` | `nvim-linux-x86_64.tar.gz` | `95aaa8e89473f5421114f2787c13ae0ec6e11ebbd1a13a1bd6fcf63420f8073f` |
| Node.js LTS | `v24.17.0` | `node-v24.17.0-linux-x64.tar.xz` | `ab343a1b747c7cbf3630dfd7dbf818c5423fab2eb4f5ad1afc896f6bd121a917` |
| Node.js LTS | `v24.17.0` | `node-v24.17.0-linux-arm64.tar.xz` | `67324b9e515e7d13da72571a5dd522bb23145a820f7dde15497897e466759ab3` |
| Chezmoi | `v2.70.5` | `chezmoi_2.70.5_linux_amd64.tar.gz` | `6a76a0ac3718f0d45b34b4b57067f9556f8f6042e3da710a3c496838362aca14` |
| Chezmoi | `v2.70.5` | `chezmoi_2.70.5_linux_arm64.tar.gz` | `4f4f31d0a10ed3b955e814a5ae20075426e27c9d3a09f536bfa4a6c8718353f2` |
| Go | `1.26.4` | `go1.26.4.linux-amd64.tar.gz` | `1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f` |
| Go | `1.26.4` | `go1.26.4.linux-arm64.tar.gz` | `ef758ae7c6cf9267c9c0ef080b8965f453d89ab2d25d9eb22de4405925238768` |

## Update process

1. Update the version, URL, filename, and SHA256 in `scripts/pinned-assets.sh`.
2. Mirror the table row here.
3. Run `bash -n scripts/*.sh`.
4. Run `shellcheck scripts/*.sh`.
5. Run `bash tests/script-contracts.sh`.
