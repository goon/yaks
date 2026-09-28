#!/usr/bin/env bash
set -euo pipefail

wpdir="${1:?usage: thumbnailer.sh <wpdir> <thumbdir>}"
thumbdir="${2:?usage: thumbnailer.sh <wpdir> <thumbdir>}"

# Thumbnail geometry. The carousel's focused tile is 196x110 at s=1.3
# (254.8x143), so 384x216 gives ~1.5x headroom with no stretching. The 16:9
# centre-crop matches the tile aspect exactly. JPEG is used because it decodes
# far faster than PNG on Qt's single async reader thread, and Quickshell's Qt
# ships the jpeg image-format plugin (webp/png plugins are not available).
thumb_w=384
thumb_h=216
thumb_quality=82

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

mkdir -p "$thumbdir"

# Purge legacy PNG/WebP thumbs from the old pipelines and any thumb whose
# source file no longer exists.
for f in "$thumbdir"/*.jpg "$thumbdir"/*.png "$thumbdir"/*.webp; do
    [ -e "$f" ] || continue
    case "$f" in
        *.png|*.webp)
            rm -f "$f"
            continue
            ;;
    esac
    base="$(basename "$f" .jpg)"
    if ! find "$wpdir" -type f -name "$base" -print -quit | grep -q .; then
        rm -f "$f"
    fi
done

find "$wpdir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) |
while IFS= read -r src; do
    thumb="$thumbdir/$(basename "$src").jpg"
    if [ ! -s "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        if magick "${src}[0]" -strip \
                -resize "${thumb_w}x${thumb_h}^" -gravity center -extent "${thumb_w}x${thumb_h}" \
                -quality "$thumb_quality" "jpg:$thumb.tmp" 2>/dev/null; then
            mv "$thumb.tmp" "$thumb"
        else
            rm -f "$thumb.tmp"
        fi
    fi
done
