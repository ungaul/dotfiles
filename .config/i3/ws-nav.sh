#!/usr/bin/env bash
# Navigate/move within a fixed 1..N workspace range, wrapping around and
# creating the target workspace if needed.
set -euo pipefail

NUM_WORKSPACES=5
mode="$1"      # switch | move
direction="$2" # next | prev

current=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

if ! [[ "$current" =~ ^[0-9]+$ ]]; then
    current=1
fi

if [[ "$direction" == "next" ]]; then
    target=$(( (current % NUM_WORKSPACES) + 1 ))
else
    target=$(( ((current - 2 + NUM_WORKSPACES) % NUM_WORKSPACES) + 1 ))
fi

if [[ "$mode" == "move" ]]; then
    i3-msg "move container to workspace number $target; workspace number $target"
else
    i3-msg "workspace number $target"
fi
