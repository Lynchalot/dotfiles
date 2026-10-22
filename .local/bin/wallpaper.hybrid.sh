#!/usr/bin/env bash
# HyDE wallpaper backend "hybrid": still images go to awww (formerly swww: light on
# GPU/RAM, animated transitions), videos go to mpvpaper. Enabled with
#   [wallpaper] backend = "hybrid"   in ~/.config/hyde/config.toml
# HyDE finds this via PATH as wallpaper.<backend>.sh and passes the wallpaper path.

lib="$HOME/.local/lib/hyde"
wall="$(readlink -f "${1:-${XDG_CACHE_HOME:-$HOME/.cache}/hyde/wall.set}")"
[ -e "$wall" ] || { echo "wallpaper.hybrid: no such wallpaper: $wall" >&2; exit 1; }

if file --mime-type -b "$wall" | grep -q '^video/'; then
    # Start the video first, then drop awww so there is no blank frame in between.
    "$lib/wallpaper.mpvpaper.sh" "$wall"
    sleep 0.5
    pkill -x awww-daemon 2>/dev/null || true
else
    "$lib/wallpaper.awww.sh" "$wall"
    # mpvpaper's surface sits on top of awww's; remove it once awww has drawn.
    if pgrep -x mpvpaper >/dev/null; then
        sleep 0.5
        pkill -x mpvpaper 2>/dev/null || true
    fi
fi
