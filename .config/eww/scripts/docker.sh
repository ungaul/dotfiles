#!/usr/bin/env bash
set -uo pipefail

case "${1:-status}" in
    status)
        if systemctl is-active --quiet docker; then
            n=$(docker ps -q 2>/dev/null | wc -l)
            echo "{\"on\":true,\"label\":\"Docker ($n)\"}"
        else
            echo '{"on":false,"label":"Docker"}'
        fi
        ;;
    toggle)
        if systemctl is-active --quiet docker; then
            pkexec systemctl stop docker
        else
            pkexec systemctl start docker
        fi
        ;;
    menu)
        docker ps -a --format '{{.Names}} ({{.Status}})' | rofi -dmenu -p "Docker containers"
        ;;
esac
