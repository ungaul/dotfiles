#!/bin/bash
options="Shutdown\nReboot\nLogout\nSuspend\nLock"
selected=$(echo -e "$options" | rofi -dmenu -p "⏻" \
  -theme-str 'listview { columns: 5; lines: 1; scrollbar: false; }' \
  -theme-str 'inputbar { enabled: false; }' \
  -theme-str 'window { width: 400px; }')
case $selected in
    Shutdown) systemctl poweroff ;;
    Reboot)   systemctl reboot ;;
    Logout)   i3-msg exit ;;
    Suspend)  systemctl suspend ;;
    Lock)     betterlockscreen -l ;;
esac
