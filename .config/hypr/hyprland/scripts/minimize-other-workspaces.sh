#!/usr/bin/env bash

# Minimizes every window not on the workspace Waffle pins to (the workspace
# that was active at the moment of switching into Waffle, passed as $1 — NOT
# hardcoded to 1, since the user may have been on any workspace) onto the
# special:minimized workspace. Waffle has no workspace switcher, so windows
# left behind on other workspaces are hidden the same way hyprbars' minimize
# button hides a window (see minimize-active.sh), restorable later via the
# taskbar.

KEEP_WORKSPACE="${1:-1}"

mapfile -t ADDRS < <(hyprctl clients -j | jq -r --arg ws "$KEEP_WORKSPACE" '.[] | select((.workspace.id | tostring) != $ws) | .address')

for addr in "${ADDRS[@]}"; do
    hyprctl dispatch "hl.dsp.window.move({ workspace = 'special:minimized', silent = true, window = 'address:${addr}' })"
done

if [ "${#ADDRS[@]}" -gt 0 ]; then
    sleep 0.05
    SPECIAL_NAME="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')"
    if [ "$SPECIAL_NAME" = "special:minimized" ]; then
        hyprctl dispatch 'hl.dsp.workspace.toggle_special("minimized")'
    fi
fi
