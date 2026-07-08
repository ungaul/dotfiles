#!/bin/bash
case $1 in
  up)   brightnessctl set +5% ;;
  down) brightnessctl set 5%- ;;
esac

BRIGHT=$(brightnessctl -m | cut -d, -f4 | tr -d %)
notify-send -h int:value:$BRIGHT -h string:x-canonical-private-synchronous:brightness "Brightness" "$BRIGHT%"
