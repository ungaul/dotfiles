#!/usr/bin/env bash

# Minimizes the active window by shoving it onto a dedicated special workspace.
# Restored via the taskbar (TaskAppButton.qml's focusOrRestore, which detects the
# special: workspace and runs togglespecialworkspace).
#
# hyprbars treats a button click as a tiny drag gesture too (logged as
# "Dragging initiated/ended" right alongside this script firing), and that drag
# handling reveals the special workspace to keep the window visible while it
# thinks a drag is in progress. That immediately undoes the hide. So: move the
# window, then explicitly force the special workspace closed again if it's open.

ACTIVE_ADDR="$(hyprctl activewindow -j | jq -r '.address')"

hyprctl dispatch "hl.dsp.window.move({ workspace = 'special:minimized', silent = true, window = 'address:${ACTIVE_ADDR}' })"

sleep 0.05

SPECIAL_NAME="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')"
if [ "$SPECIAL_NAME" = "special:minimized" ]; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("minimized")'
fi
