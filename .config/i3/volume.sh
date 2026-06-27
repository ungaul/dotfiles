#!/bin/bash
exec >> /tmp/volume-debug.log 2>&1
echo "--- $(date) ---"
echo "DBUS: $DBUS_SESSION_BUS_ADDRESS"
echo "ARG: $1"

case $1 in
  up)   pamixer -i 5 ;;
  down) pamixer -d 5 ;;
  mute) pamixer -t ;;
esac

if [ "$(pamixer --get-mute)" = "true" ]; then
  notify-send -h int:value:0 -h string:x-canonical-private-synchronous:volume "Volume" "Muted"
else
  VOL=$(pamixer --get-volume)
  notify-send -h int:value:$VOL -h string:x-canonical-private-synchronous:volume "Volume" "$VOL%"
fi
