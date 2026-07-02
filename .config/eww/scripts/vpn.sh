#!/usr/bin/env bash
set -uo pipefail

active_vpn() {
    nmcli -t -f name,type connection show --active | awk -F: '$2=="vpn"{print $1; exit}'
}

case "${1:-status}" in
    status)
        vpn=$(active_vpn)
        if [[ -n "$vpn" ]]; then
            echo "{\"on\":true,\"label\":\"$vpn\"}"
        else
            echo '{"on":false,"label":"VPN"}'
        fi
        ;;
    toggle)
        vpn=$(active_vpn)
        if [[ -n "$vpn" ]]; then
            nmcli connection down "$vpn"
        else
            first=$(nmcli -t -f name,type connection show | awk -F: '$2=="vpn"{print $1; exit}')
            [[ -n "$first" ]] && nmcli connection up "$first"
        fi
        ;;
    menu)
        choice=$(nmcli -t -f name,type connection show | awk -F: '$2=="vpn"{print $1}' | rofi -dmenu -p "VPN")
        [[ -n "$choice" ]] && nmcli connection up "$choice"
        ;;
esac
