# Offline assets manifest

Restricted mode expects these pre-downloaded files in
`~/dotfiles-offline-assets/`. Filenames and SHA256 values must match exactly.

The installer verifies SHA256 before extracting anything.

| Tool | Version | URL | Filename | SHA256 |
|---|---:|---|---|---|
| starship | `v1.23.0` | `https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz` | `starship-x86_64-unknown-linux-gnu.tar.gz` | `cef41df04378c6f692913c5d9c1032d3b9a4369a1d2f3296c8300ed8838c2197` |
| eza | `v0.21.5` | `https://github.com/eza-community/eza/releases/download/v0.21.5/eza_x86_64-unknown-linux-gnu.tar.gz` | `eza_x86_64-unknown-linux-gnu.tar.gz` | `f49f764340d13379013213dbffc6e0d78cba7b0f9b9388be9306eb0c69914dd1` |
| uv | `0.6.17` | `https://github.com/astral-sh/uv/releases/download/0.6.17/uv-x86_64-unknown-linux-gnu.tar.gz` | `uv-x86_64-unknown-linux-gnu.tar.gz` | `720ec28f7a94aa8cd91d3d57dec1434d64b9ae13d1dd6a25f4c0cdb837ba9cf6` |
| lazygit | `v0.48.0` | `https://github.com/jesseduffield/lazygit/releases/download/v0.48.0/lazygit_0.48.0_Linux_x86_64.tar.gz` | `lazygit_0.48.0_Linux_x86_64.tar.gz` | `291722c643a10805de3bd7b58f51d5275878269aeadb046709708f8683f558d7` |
| git-delta | `0.18.2` | `https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz` | `delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz` | `99607c43238e11a77fe90a914d8c2d64961aff84b60b8186c1b5691b39955b0f` |
| FiraCode Nerd Font | `v3.3.0` | `https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip` | `FiraCode.zip` | `89978e6f870d044286a339161d5ed961569744b1cd2afee62337fa140cd0b397` |
| Neovim fallback | `v0.10.4` | `https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz` | `nvim-linux-x86_64.tar.gz` | `95aaa8e89473f5421114f2787c13ae0ec6e11ebbd1a13a1bd6fcf63420f8073f` |

## PowerShell download helper

```powershell
$assets = @(
  @{ Url = "https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz"; File = "starship-x86_64-unknown-linux-gnu.tar.gz"; Sha256 = "cef41df04378c6f692913c5d9c1032d3b9a4369a1d2f3296c8300ed8838c2197" },
  @{ Url = "https://github.com/eza-community/eza/releases/download/v0.21.5/eza_x86_64-unknown-linux-gnu.tar.gz"; File = "eza_x86_64-unknown-linux-gnu.tar.gz"; Sha256 = "f49f764340d13379013213dbffc6e0d78cba7b0f9b9388be9306eb0c69914dd1" },
  @{ Url = "https://github.com/astral-sh/uv/releases/download/0.6.17/uv-x86_64-unknown-linux-gnu.tar.gz"; File = "uv-x86_64-unknown-linux-gnu.tar.gz"; Sha256 = "720ec28f7a94aa8cd91d3d57dec1434d64b9ae13d1dd6a25f4c0cdb837ba9cf6" },
  @{ Url = "https://github.com/jesseduffield/lazygit/releases/download/v0.48.0/lazygit_0.48.0_Linux_x86_64.tar.gz"; File = "lazygit_0.48.0_Linux_x86_64.tar.gz"; Sha256 = "291722c643a10805de3bd7b58f51d5275878269aeadb046709708f8683f558d7" },
  @{ Url = "https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz"; File = "delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz"; Sha256 = "99607c43238e11a77fe90a914d8c2d64961aff84b60b8186c1b5691b39955b0f" },
  @{ Url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"; File = "FiraCode.zip"; Sha256 = "89978e6f870d044286a339161d5ed961569744b1cd2afee62337fa140cd0b397" },
  @{ Url = "https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz"; File = "nvim-linux-x86_64.tar.gz"; Sha256 = "95aaa8e89473f5421114f2787c13ae0ec6e11ebbd1a13a1bd6fcf63420f8073f" }
)
New-Item -ItemType Directory -Force -Path .\dotfiles-offline-assets | Out-Null
foreach ($a in $assets) {
  $out = ".\dotfiles-offline-assets\$($a.File)"
  Invoke-WebRequest -Uri $a.Url -OutFile $out
  $actual = (Get-FileHash -Algorithm SHA256 $out).Hash.ToLower()
  if ($actual -ne $a.Sha256) { throw "SHA256 mismatch for $($a.File)" }
}
```

Everything else in restricted mode comes from Debian apt repositories or
`git clone` from `github.com`.
