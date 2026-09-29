#!/usr/bin/env bash
set -euo pipefail

# Pick a source colour for Matugen from a wallpaper.
#
# Matugen's own `image` extraction weights a huge near-grey cluster over
# smaller vivid ones, so a desaturated wallpaper area can win the seed and
# then get blown up by the scheme type into a hue that is barely present
# (a grey-purple car body becoming loud pink). This script instead follows
# Uki's rule: discard low-saturation pixels, bin the rest into 30-degree hue
# families, and let the family with the most area x saturation win. Theme.qml
# feeds the result to `matugen color hex` so the palette follows the
# wallpaper's most visible hue.
#
# Prints "#rrggbb" on stdout, or exits non-zero when the image is achromatic.

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
sat_min=0.30      # seed saturation floor (Uki's chromatic minimum)
sat_max=0.85      # seed saturation ceiling
seed_l=0.50       # seed lightness fed to matugen
l_min=0.05        # ignore near-black
l_max=0.92        # ignore near-white

magick "$wp" -alpha off -resize 200x200 -colors 48 -depth 8 -format "%c" histogram:info:- 2>/dev/null |
awk -v sat_floor="$sat_floor" -v sat_min="$sat_min" -v sat_max="$sat_max" \
    -v seed_l="$seed_l" -v l_min="$l_min" -v l_max="$l_max" '
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
    if (s < sat_floor) next
    if (l < l_min || l > l_max) next
    cnt = $1 + 0
    fam = int(h * 12)
    fam_cnt[fam] += cnt
    fam_score[fam] += cnt * s
    fam_hue[fam] += cnt * s * h
}
END {
    best = -1
    for (f in fam_score) if (fam_score[f] > best) { best = fam_score[f]; bf = f }
    if (best <= 0) exit 1
    hue = fam_hue[bf] / fam_score[bf]
    sat = fam_score[bf] / fam_cnt[bf]
    if (sat < sat_min) sat = sat_min
    if (sat > sat_max) sat = sat_max
    q = seed_l < 0.5 ? seed_l * (1 + sat) : seed_l + sat - seed_l * sat
    p = 2 * seed_l - q
    for (i = 1; i <= 3; i++) {
        t = hue + (i == 1 ? 1.0 / 3 : (i == 2 ? 0 : -1.0 / 3))
        if (t < 0) t += 1
        if (t > 1) t -= 1
        if (t < 1.0 / 6)      v = p + (q - p) * 6 * t
        else if (t < 1.0 / 2) v = q
        else if (t < 2.0 / 3) v = p + (q - p) * (2.0 / 3 - t) * 6
        else                  v = p
        rgb[i] = v
    }
    printf "#%02x%02x%02x\n", int(rgb[1] * 255 + 0.5), int(rgb[2] * 255 + 0.5), int(rgb[3] * 255 + 0.5)
}'
