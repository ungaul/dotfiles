#!/usr/bin/env bash
set -uo pipefail

case "${1:-status}" in
    status)
        if [[ "$(dunstctl is-paused)" == "true" ]]; then
            echo '{"on":false,"label":"Notifs off"}'
        else
            echo '{"on":true,"label":"Notifs on"}'
        fi
        ;;
    toggle)
        dunstctl set-paused toggle
        ;;
    menu)
        choice=$(printf 'Pause 30m\nPause 1h\nResume\nClear history\n' | rofi -dmenu -p "Notifications")
        case "$choice" in
            "Pause 30m") dunstctl set-paused true; (sleep 1800 && dunstctl set-paused false &) ;;
            "Pause 1h")  dunstctl set-paused true; (sleep 3600 && dunstctl set-paused false &) ;;
            "Resume")    dunstctl set-paused false ;;
            "Clear history")
                dunstctl history-clear
                : > "$HOME/.local/share/eww/notif-history.jsonl"
                ;;
        esac
        ;;
esac
