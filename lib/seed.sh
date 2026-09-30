#!/usr/bin/env bash
set -euo pipefail

# Print the wallpaper's colour histogram for the palette generator.
#
# This script is a dumb pixel feeder: it emits one line per quantised colour
# ("<count>: (...) #rrggbb ...") and does no colour science of its own. All
# interpretation — OKLab conversion, hue-family clustering, mean lightness and
# the colorfulness score — lives in lib/color.js (seedFromHistogram), so the
# seed reflects the wallpaper's real chroma and lightness instead of a value
# reconstructed from HSL at a synthetic lightness.
#
# Usage: seed.sh <wallpaper>

wp="${1:?usage: seed.sh <wallpaper>}"
[ -f "$wp" ] || exit 1

# The caller (Theme/Wallpaper) exports a PATH that includes ImageMagick.
command -v magick &>/dev/null || exit 1

magick "$wp" -alpha off -resize 256x256 -colors 256 -depth 8 -format "%c" histogram:info:- 2>/dev/null
