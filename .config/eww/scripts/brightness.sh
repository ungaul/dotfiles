#!/usr/bin/env bash
set -uo pipefail

case "${1:-status}" in
    status)
        pct=$(brightnessctl -m | awk -F, '{gsub("%","",$4); print $4}')
        echo "{\"on\":true,\"label\":\"${pct}%\"}"
        ;;
    toggle)
        pct=$(brightnessctl -m | awk -F, '{gsub("%","",$4); print $4}')
        if (( pct > 10 )); then
            brightnessctl set 10% >/dev/null
        else
            brightnessctl set 100% >/dev/null
        fi
        ;;
    menu)
        choice=$(printf '10%%\n25%%\n50%%\n75%%\n100%%\n' | rofi -dmenu -p "Brightness")
        [[ -n "$choice" ]] && brightnessctl set "$choice" >/dev/null
        ;;
esac
