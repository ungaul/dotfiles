#!/usr/bin/env bash
set -uo pipefail

STATE="$HOME/.cache/eww-nightshift-state"

outputs() {
    xrandr --query | awk '/ connected/{print $1}'
}

apply() {
    local mode="$1"
    for o in $(outputs); do
        if [[ "$mode" == "warm" ]]; then
            xrandr --output "$o" --gamma 1.0:0.75:0.55
        else
            xrandr --output "$o" --gamma 1.0:1.0:1.0
        fi
    done
}

case "${1:-status}" in
    status)
        if [[ -f "$STATE" && "$(cat "$STATE")" == "warm" ]]; then
            echo '{"on":true,"label":"Night Shift"}'
        else
            echo '{"on":false,"label":"Night Shift"}'
        fi
        ;;
    toggle)
        if [[ -f "$STATE" && "$(cat "$STATE")" == "warm" ]]; then
            apply normal
            echo "normal" > "$STATE"
        else
            apply warm
            echo "warm" > "$STATE"
        fi
        ;;
    menu)
        choice=$(printf 'Off\nLight\nWarm\nExtra warm\n' | rofi -dmenu -p "Night Shift")
        case "$choice" in
            Off)         for o in $(outputs); do xrandr --output "$o" --gamma 1.0:1.0:1.0; done; echo "normal" > "$STATE" ;;
            Light)       for o in $(outputs); do xrandr --output "$o" --gamma 1.0:0.9:0.8;  done; echo "warm" > "$STATE" ;;
            "Warm")      for o in $(outputs); do xrandr --output "$o" --gamma 1.0:0.75:0.55; done; echo "warm" > "$STATE" ;;
            "Extra warm") for o in $(outputs); do xrandr --output "$o" --gamma 1.0:0.6:0.4;  done; echo "warm" > "$STATE" ;;
        esac
        ;;
esac
