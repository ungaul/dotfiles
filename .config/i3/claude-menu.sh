#!/usr/bin/env bash
# Toggle a floating Claude Code terminal pinned to the left edge of the
# screen. First call spawns it; later calls hide/show it via scratchpad.
set -euo pipefail

INSTANCE="claude-menu"
WORKDIR="$HOME"

exists() {
    i3-msg -t get_tree | jq -e --arg i "$INSTANCE" \
        '.. | objects | select(.window_properties? and .window_properties.instance == $i)' \
        >/dev/null 2>&1
}

if exists; then
    i3-msg "[instance=\"$INSTANCE\"] scratchpad show"
else
    alacritty --class "$INSTANCE" --working-directory "$WORKDIR" -e claude &
    disown

    (
        set +e
        winid=""
        for i in $(seq 1 50); do
            winid=$(xdotool search --class "$INSTANCE" 2>/dev/null | head -1)
            [ -n "$winid" ] && break
            sleep 0.1
        done
        [ -n "$winid" ] && xprop -id "$winid" -f _NET_WM_STATE 32a -set _NET_WM_STATE "_NET_WM_STATE_STICKY, _NET_WM_STATE_SKIP_TASKBAR"
    ) &
    disown
fi
