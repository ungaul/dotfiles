#!/usr/bin/env bash
# Advances each keyboard device to its own next configured layout.
# Used as the click action for the graphical language-switcher button in the bar.
#
# `switchxkblayout <device> next` advances that device's own layout index on
# its own; it doesn't need comparing against other devices first. An earlier
# version tried to detect "are all devices already in sync" before deciding
# next-vs-reset, but stray virtual keyboard devices (e.g. wayvnc's, ydotool's)
# never report the same active_keymap as the real ones, so that check always
# failed and every click just reset back to layout 0 instead of cycling.

echo "$(date +%T) invoked" >> /tmp/xkb-switch-debug.log

for device in $(hyprctl devices -j | jq -r '.keyboards[].name'); do
    hyprctl switchxkblayout "$device" next
done
