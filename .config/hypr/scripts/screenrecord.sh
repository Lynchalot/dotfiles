#!/bin/bash

SAVE_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
FILENAME="$SAVE_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

mkdir -p "$SAVE_DIR"

if pgrep -x "wf-recorder" > /dev/null 2>&1; then
    pkill -SIGINT -x wf-recorder
    sleep 0.5
    LAST=$(ls -t "$SAVE_DIR"/*.mp4 2>/dev/null | head -1)
    notify-send -i "media-record" -t 5000 "⏹ Recording Stopped" "Saved: $(basename "$LAST")"
else
    if [[ "$1" == "region" ]]; then
        REGION=$(slurp)
        [[ -z "$REGION" ]] && exit 0  # user pressed escape
        notify-send -i "media-record" -t 2000 "⏺ Recording Started" "Region · $(basename "$FILENAME")"
        wf-recorder -g "$REGION" -a -f "$FILENAME" &
    else
        MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name')
        notify-send -i "media-record" -t 2000 "⏺ Recording Started" "$MONITOR · $(basename "$FILENAME")"
        wf-recorder -o "$MONITOR" -a -f "$FILENAME" &
    fi
fi
