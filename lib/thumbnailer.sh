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

# Parallel workers for the generation loop. Capped at 8: the win is already
# large by then, and unbounded -P on a big wallpaper folder would starve the
# compositor (and the shell itself) of CPU.
jobs="${YAKS_THUMB_JOBS:-8}"

# The caller (Wallpaper) exports a PATH that includes ImageMagick.
command -v magick &>/dev/null || exit 1

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

thumb_one() {
    src="$1"
    thumb="$thumbdir/$(basename "$src").jpg"
    # Skip when the thumb exists and is at least as new as its source.
    if [ -s "$thumb" ] && [ ! "$src" -nt "$thumb" ]; then
        return 0
    fi
    if magick "${src}[0]" -strip \
            -resize "${thumb_w}x${thumb_h}^" -gravity center -extent "${thumb_w}x${thumb_h}" \
            -quality "$thumb_quality" "jpg:$thumb.tmp" 2>/dev/null; then
        mv "$thumb.tmp" "$thumb"
    else
        rm -f "$thumb.tmp"
    fi
}
export -f thumb_one
export thumb_w thumb_h thumb_quality thumbdir

# One magick process per image, N at a time. ImageMagick is itself
# multi-threaded, so each worker is pinned to one thread to stop the two
# layers from oversubscribing the machine.
find "$wpdir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 |
MAGICK_THREAD_LIMIT=1 xargs -0 -r -P "$jobs" -n 1 bash -c 'thumb_one "$1"' _
