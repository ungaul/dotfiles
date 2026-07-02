#!/usr/bin/env bash
# Fixed set of workspace buttons for polybar, independent of whether the
# workspace currently exists in i3. Colors mirror the i3/polybar module.
set -euo pipefail

NUM_WORKSPACES=5

FOCUSED_FG="#d0c6aa"
FOCUSED_BG="#2f3327"
INACTIVE_FG="#7f7867"

render() {
    local ws_json="$1"
    local out=""
    for i in $(seq 1 "$NUM_WORKSPACES"); do
        local focused
        focused=$(jq --arg n "$i" 'any(.[]; .name == $n and .focused)' <<<"$ws_json")

        local label="%{A1:i3-msg workspace $i:} $i %{A}"
        if [[ "$focused" == "true" ]]; then
            out+="%{F${FOCUSED_FG}}%{B${FOCUSED_BG}}${label}%{B-}%{F-}"
        else
            out+="%{F${INACTIVE_FG}}${label}%{F-}"
        fi
    done
    printf '%s\n' "$out"
}

i3-msg -t get_workspaces | { read -r ws; render "$ws"; }

i3-msg -t subscribe -m '["workspace"]' | jq --unbuffered -c . | while read -r _event; do
    ws=$(i3-msg -t get_workspaces)
    render "$ws"
done
