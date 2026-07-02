#!/usr/bin/env bash
# Terminate already running bar instances and wait for them to actually exit
# before relaunching, otherwise the new instance can fail to claim the
# systray selection ("Systray selection already managed").
killall -q polybar

while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

primary=$(xrandr --query | awk '/ primary/{print $1}')

for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    if [[ "$m" == "$primary" ]]; then
        TRAY_POS=right MONITOR=$m polybar main &
    else
        TRAY_POS=none MONITOR=$m polybar main &
    fi
    disown
done
