#!/usr/bin/env bash
# Persistently logs every desktop notification to disk (survives dunst/eww
# restarts and reboots), so the panel can show history beyond dunst's
# in-memory session history.
set -uo pipefail

HIST="$HOME/.local/share/eww/notif-history.jsonl"
mkdir -p "$(dirname "$HIST")"
MAX=100

# Avoid spawning duplicate loggers across i3 reloads/restarts.
LOCK="/tmp/notif-logger-$UID.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

esc() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify',type='method_call'" |
while IFS= read -r line; do
    if [[ "$line" == method\ call* ]]; then
        if [[ "$n" -ge 4 ]]; then
            ts=$(date +%s)
            printf '{"time":%s,"app":"%s","summary":"%s","body":"%s"}\n' \
                "$ts" "$(esc "$app")" "$(esc "$summary")" "$(esc "$body")" >> "$HIST"
            tail -n "$MAX" "$HIST" > "$HIST.tmp" && mv "$HIST.tmp" "$HIST"
        fi
        n=0; app=""; summary=""; body=""
        continue
    fi

    trimmed="${line#"${line%%[![:space:]]*}"}"
    if [[ "$trimmed" == string\ \"* ]]; then
        n=$((n + 1))
        val="${trimmed#string \"}"
        val="${val%\"}"
        case "$n" in
            1) app="$val" ;;
            4) summary="$val" ;;
            5) body="$val" ;;
        esac
    fi
done
