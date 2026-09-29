#!/usr/bin/env bash
set -euo pipefail

# Extract the wallpaper seed for the palette generator.
#
# Follows Uki's rule: discard low-saturation pixels, bin the rest into
# 30-degree hue families, and let the family with the most area x saturation
# win (so the most visible chromatic hue drives the theme, not the largest
# near-grey cluster). Chroma policy lives downstream in lib/palette.js.
#
# Prints "<hue_deg> <sat> <mean_l>" on stdout:
#   hue_deg  winning family hue, 0..360 (0 when achromatic)
#   sat      representative saturation, 0..1, unclamped (0 when achromatic)
#   mean_l   whole-image mean HSL lightness, 0..1 (drives the palette's tone)
# Achromatic images emit "0 0 <mean_l>" so a grey wallpaper yields a grey theme.

wp="${1:?usage: seed.sh <wallpaper>}"
[ -f "$wp" ] || exit 1

# magick may live outside the systemd service PATH; mirror thumbnailer.sh.
if ! command -v magick &>/dev/null; then
    for p in /run/current-system/sw/bin /etc/profiles/per-user/*/bin /nix/var/nix/profiles/default/bin; do
        [ -x "$p/magick" ] && export PATH="$p:$PATH" && break
    done
fi
if ! command -v magick &>/dev/null; then
    _magick=$(find /nix/store -maxdepth 4 -name magick -path '*/bin/magick' -type f 2>/dev/null | tail -1)
    if [ -n "$_magick" ]; then
        export PATH="$(dirname "$_magick"):$PATH"
    fi
    unset _magick
fi
command -v magick &>/dev/null || exit 1

# Tunables.
sat_floor=0.15    # below this a pixel counts as grey and is ignored
l_min=0.05        # ignore near-black
l_max=0.92        # ignore near-white

magick "$wp" -alpha off -resize 200x200 -colors 48 -depth 8 -format "%c" histogram:info:- 2>/dev/null |
awk -v sat_floor="$sat_floor" -v l_min="$l_min" -v l_max="$l_max" '
function amax(a, b) { return a > b ? a : b }
function amin(a, b) { return a < b ? a : b }
{
    if (match($0, /#([0-9A-Fa-f]{6})/, m)) hx = m[1]; else next
    r = strtonum("0x" substr(hx, 1, 2)) / 255
    g = strtonum("0x" substr(hx, 3, 2)) / 255
    b = strtonum("0x" substr(hx, 5, 2)) / 255
    mx = amax(r, amax(g, b)); mn = amin(r, amin(g, b)); d = mx - mn
    l = (mx + mn) / 2
    if (d == 0) { s = 0; h = 0 } else {
        s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
        if (mx == r)      h = ((g - b) / d + (g < b ? 6 : 0)) / 6
        else if (mx == g) h = ((b - r) / d + 2) / 6
        else              h = ((r - g) / d + 4) / 6
    }
    cnt = $1 + 0
    tot += cnt
    lum += cnt * l
    if (s < sat_floor) next
    if (l < l_min || l > l_max) next
    fam = int(h * 12)
    fam_cnt[fam] += cnt
    fam_score[fam] += cnt * s
    fam_hue[fam] += cnt * s * h
}
END {
    mean_l = tot > 0 ? lum / tot : 0.12
    best = -1
    for (f in fam_score) if (fam_score[f] > best) { best = fam_score[f]; bf = f }
    if (best <= 0) {                      # achromatic: grey theme downstream
        printf "0 0 %.4f\n", mean_l
        exit 0
    }
    hue = (fam_hue[bf] / fam_score[bf]) * 360
    sat = fam_score[bf] / fam_cnt[bf]     # raw representative saturation
    printf "%.1f %.4f %.4f\n", hue, sat, mean_l
}'
