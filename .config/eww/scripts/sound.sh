#!/usr/bin/env bash
set -uo pipefail

case "${1:-status}" in
    status)
        mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)
        if [[ "$mute" == "yes" ]]; then
            echo "{\"on\":false,\"label\":\"Muted\"}"
        else
            echo "{\"on\":true,\"label\":\"$vol\"}"
        fi
        ;;
    toggle)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    menu)
        sink=$(pactl list short sinks | awk '{print $2}' | rofi -dmenu -p "Output device")
        [[ -n "$sink" ]] && pactl set-default-sink "$sink"
        ;;
esac
