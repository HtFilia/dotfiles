#!/usr/bin/env bash
# shellcheck disable=SC2034
# Use only repositories already configured by the workstation administrator.
corporate_packages=(
  build-essential curl wget git openssh-client zsh tmux unzip xz-utils ca-certificates
  pkg-config libssl-dev python3 python3-pip python3-venv jq tree htop fontconfig
  xclip xdg-utils ripgrep fd-find bat fzf zoxide direnv rustc cargo rustfmt rust-clippy
  shellcheck shfmt bats btop zstd moreutils chafa parallel cmatrix cava ffmpeg 7zip
  libevent-dev libncurses-dev byacc ncurses-term ncurses-bin less bsdextrautils
  util-linux procps man-db nodejs npm golang-go gh
)
