#!/usr/bin/env bash
set -euo pipefail

# Extract the wallpaper seed for the palette generator.
#
# Follows Uki's rule: discard low-saturation pixels, bin the rest into
# 30-degree hue families, and let the family with the most area x saturation
# win (so the most visible chromatic hue drives the theme, not the largest
# near-grey cluster). Chroma policy lives downstream in lib/palette.js.
#
# Prints "<hue> <sat> <mean_l> <hue2> <sat2>" on stdout:
#   hue/sat    dominant family hue (deg) and representative saturation (unclamped)
#   mean_l     whole-image mean HSL lightness, 0..1 (drives the palette's tone)
#   hue2/sat2  the wallpaper's second chromatic family, when it is substantial
#              and far enough from the first; hue2 = -1 when there is none
# Achromatic images emit "0 0 <mean_l> -1 0" so a grey wallpaper yields a grey theme.

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
# POSIX-awk hex parse (no gawk-only strtonum / match-array)
function hex2d(s,   i, c, v) {
    v = 0
    for (i = 1; i <= length(s); i++) {
        c = tolower(substr(s, i, 1))
        v = v * 16 + index("0123456789abcdef", c) - 1
    }
    return v
}
{
    if (!match($0, /#[0-9A-Fa-f]{6}/)) next
    hx = substr($0, RSTART + 1, 6)
    r = hex2d(substr(hx, 1, 2)) / 255
    g = hex2d(substr(hx, 3, 2)) / 255
    b = hex2d(substr(hx, 5, 2)) / 255
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
    # representative saturation: the most prominent (count x sat) pixel of the
    # family, so the seed reflects wallpaper vividness, not a muted average
    if (cnt * s > fam_best[fam]) { fam_best[fam] = cnt * s; fam_best_sat[fam] = s }
}
END {
    mean_l = tot > 0 ? lum / tot : 0.12
    best = -1; second = -1; bf = -1; sf = -1
    for (f in fam_score) {
        if (fam_score[f] > best)      { second = best; sf = bf; best = fam_score[f]; bf = f }
        else if (fam_score[f] > second) { second = fam_score[f]; sf = f }
    }
    if (bf < 0 || best <= 0) {            # achromatic: grey theme downstream
        printf "0 0 %.4f -1 0\n", mean_l
        exit 0
    }
    hue1 = (fam_hue[bf] / fam_score[bf]) * 360
    sat1 = fam_best_sat[bf]
    hue2 = -1; sat2 = 0
    if (sf >= 0 && second >= 0.35 * best) {
        h2 = (fam_hue[sf] / fam_score[sf]) * 360
        s2 = fam_best_sat[sf]
        d = h2 - hue1; if (d < 0) d = -d; if (d > 180) d = 360 - d
        if (s2 >= sat_floor && d >= 40) { hue2 = h2; sat2 = s2 }
    }
    printf "%.1f %.4f %.4f %.1f %.4f\n", hue1, sat1, mean_l, hue2, sat2
}'
