#!/usr/bin/env bash
# Render the Plymouth splash artwork from the SVGs next to this script.
# The PNGs are committed, so `chezmoi apply` needs no image tools; run this
# only after changing an SVG. Needs rsvg-convert and ImageMagick.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
plymouth="$here/../../home/dot_local/share/boot-theme/plymouth"
mkdir -p "$plymouth"

# Rendered at twice the 1920x1080 design size so the splash stays sharp on a
# 4K screen. A star and the progress line (a track and its fill) are drawn here.
rsvg-convert -z 2 "$here/sky.svg" -o "$plymouth/sky.png"
rsvg-convert -z 2 "$here/ridges.svg" -o "$plymouth/ridges.png"
rsvg-convert -z 2 "$here/glow.svg" -o "$plymouth/glow.png"
magick -size 32x32 radial-gradient:'#FFF4EC-rgba(247,217,204,0)' -define png:color-type=6 "$plymouth/star.png"
magick -size 1200x12 xc:none -fill '#F7D9CC' -draw 'roundrectangle 0,0 1199,11 6,6' -define png:color-type=6 -channel A -evaluate multiply 0.2 +channel "$plymouth/bar-track.png"
magick -size 1200x12 xc:none -fill '#E6B7A6' -draw 'roundrectangle 0,0 1199,11 6,6' -define png:color-type=6 "$plymouth/bar-fill.png"
echo "Splash artwork written to $plymouth"
