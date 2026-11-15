#!/usr/bin/env bash
# Render the boot-theme artwork from scene.svg into the GRUB theme folder.
# The PNGs are committed, so `chezmoi apply` needs no image tools; run this
# only after changing scene.svg. Needs rsvg-convert and ImageMagick.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="$here/../../home/dot_local/share/boot-theme/grub"
mkdir -p "$out"

rsvg-convert -w 3840 -h 2160 "$here/scene.svg" -o "$out/background.png"

# Selected-entry bar: a rounded peach rectangle cut into the nine pieces GRUB
# stretches (select_nw.png … select_se.png), corner radius 24, drawn for a 4K screen.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
magick -size 96x96 xc:none -fill '#E6B7A6' -draw 'roundrectangle 0,0 95,95 24,24' "$tmp/select.png"
crop() { magick "$tmp/select.png" -crop "$2" +repage -define png:color-type=6 "$out/select_$1.png"; }
crop nw 24x24+0+0
crop n 48x24+24+0
crop ne 24x24+72+0
crop w 24x48+0+24
crop c 48x48+24+24
crop e 24x48+72+24
crop sw 24x24+0+72
crop s 48x24+24+72
crop se 24x24+72+72

# Plymouth layers: sky, ridges and glow from their SVGs, plus a star and the
# progress line (a track and its fill) drawn here.
plymouth="$here/../../home/dot_local/share/boot-theme/plymouth"
mkdir -p "$plymouth"
rsvg-convert -z 2 "$here/sky.svg" -o "$plymouth/sky.png"
rsvg-convert -z 2 "$here/ridges.svg" -o "$plymouth/ridges.png"
rsvg-convert -z 2 "$here/glow.svg" -o "$plymouth/glow.png"
magick -size 32x32 radial-gradient:'#FFF4EC-rgba(247,217,204,0)' -define png:color-type=6 "$plymouth/star.png"
magick -size 1200x12 xc:none -fill '#F7D9CC' -draw 'roundrectangle 0,0 1199,11 6,6' -define png:color-type=6 -channel A -evaluate multiply 0.2 +channel "$plymouth/bar-track.png"
magick -size 1200x12 xc:none -fill '#E6B7A6' -draw 'roundrectangle 0,0 1199,11 6,6' -define png:color-type=6 "$plymouth/bar-fill.png"
echo "Boot artwork written to $out and $plymouth"
