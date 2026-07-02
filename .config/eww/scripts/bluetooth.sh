#!/usr/bin/env bash
set -uo pipefail

case "${1:-status}" in
    status)
        if bluetoothctl show | grep -q "Powered: yes"; then
            dev=$(bluetoothctl info | awk -F': ' '/Name:/{print $2; exit}')
            if [[ -n "$dev" ]]; then
                echo "{\"on\":true,\"label\":\"$dev\"}"
            else
                echo '{"on":true,"label":"Bluetooth"}'
            fi
        else
            echo '{"on":false,"label":"Bluetooth"}'
        fi
        ;;
    toggle)
        if bluetoothctl show | grep -q "Powered: yes"; then
            bluetoothctl power off
        else
            bluetoothctl power on
        fi
        ;;
    menu)
        bluetoothctl power on
        mapfile -t devices < <(bluetoothctl devices Paired | sed 's/^Device //')
        names=()
        for d in "${devices[@]}"; do names+=("${d#* }"); done
        choice=$(printf '%s\n' "${names[@]}" | rofi -dmenu -p "Bluetooth")
        [[ -z "$choice" ]] && exit 0
        for d in "${devices[@]}"; do
            mac="${d%% *}"
            label="${d#* }"
            if [[ "$label" == "$choice" ]]; then
                bluetoothctl connect "$mac"
                break
            fi
        done
        ;;
esac
