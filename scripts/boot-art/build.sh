#!/usr/bin/env bash
# Render the boot-theme artwork from scene.svg into the GRUB theme folder.
# The PNGs are committed, so `chezmoi apply` needs no image tools; run this
# only after changing scene.svg. Needs rsvg-convert and ImageMagick.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="$here/../../home/dot_local/share/boot-theme/grub"
mkdir -p "$out"

rsvg-convert -w 1920 -h 1080 "$here/scene.svg" -o "$out/background.png"

# Selected-entry bar: a rounded peach rectangle cut into the nine pieces GRUB
# stretches (select_nw.png … select_se.png), corner radius 12.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
magick -size 48x48 xc:none -fill '#E6B7A6' -draw 'roundrectangle 0,0 47,47 12,12' "$tmp/select.png"
crop() { magick "$tmp/select.png" -crop "$2" +repage -define png:color-type=6 "$out/select_$1.png"; }
crop nw 12x12+0+0;  crop n 24x12+12+0;  crop ne 12x12+36+0
crop w  12x24+0+12; crop c 24x24+12+12; crop e  12x24+36+12
crop sw 12x12+0+36; crop s 24x12+12+36; crop se 12x12+36+36
echo "Boot artwork written to $out"
