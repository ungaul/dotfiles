#!/usr/bin/env bash
set -uo pipefail

HIST="$HOME/.local/share/eww/notif-history.jsonl"
mkdir -p "$(dirname "$HIST")"
touch "$HIST"

case "${1:-show}" in
    show)
        if [[ ! -s "$HIST" ]]; then
            echo "No notifications yet"
            exit 0
        fi
        tail -n 8 "$HIST" | tac | jq -r '
            (.time | localtime | strftime("%H:%M")) as $t |
            "[\($t)] \(.app): \(.summary)" +
            (if .body != "" then " — " + .body else "" end)
        '
        ;;
    clear)
        : > "$HIST"
        ;;
esac
