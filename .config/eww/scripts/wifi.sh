#!/usr/bin/env bash
set -uo pipefail

case "${1:-status}" in
    status)
        if [[ "$(nmcli radio wifi)" == "enabled" ]]; then
            ssid=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2}')
            if [[ -n "$ssid" ]]; then
                echo "{\"on\":true,\"label\":\"$ssid\"}"
            else
                echo '{"on":true,"label":"WiFi"}'
            fi
        else
            echo '{"on":false,"label":"WiFi"}'
        fi
        ;;
    toggle)
        if [[ "$(nmcli radio wifi)" == "enabled" ]]; then
            nmcli radio wifi off
        else
            nmcli radio wifi on
        fi
        ;;
    menu)
        nmcli radio wifi on
        sleep 1
        choice=$(nmcli -t -f ssid dev wifi list | sort -u | grep -v '^$' | rofi -dmenu -p "WiFi")
        [[ -n "$choice" ]] && nmcli device wifi connect "$choice"
        ;;
esac
