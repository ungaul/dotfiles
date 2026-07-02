#!/usr/bin/env bash
secs=$(cut -d. -f1 /proc/uptime)
h=$(( secs / 3600 ))
m=$(( (secs % 3600) / 60 ))
if (( h > 0 )); then
    printf '%dh %dm\n' "$h" "$m"
else
    printf '%dm\n' "$m"
fi
