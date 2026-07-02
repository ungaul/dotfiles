#!/usr/bin/env bash
# Toggle the eww right-side control panel.
set -euo pipefail

eww ping >/dev/null 2>&1 || eww daemon

if eww active-windows | grep -q "^rightpanel"; then
    eww close rightpanel
else
    eww open rightpanel
fi
