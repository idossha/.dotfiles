#!/bin/bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

BATT="$(pmset -g batt)"
PCT="$(echo "$BATT" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$PCT" ] && { sketchybar --set "$NAME" drawing=off; exit 0; }

COLOR=$TEXT
if echo "$BATT" | grep -qE 'AC Power|charging'; then
  ICON="$ICON_BATTERY_CHARGING"; COLOR=$GREEN
else
  case "$PCT" in
    9[0-9]|100) ICON="$ICON_BATTERY_100" ;;
    [6-8][0-9]) ICON="$ICON_BATTERY_75" ;;
    [3-5][0-9]) ICON="$ICON_BATTERY_50" ;;
    [1-2][0-9]) ICON="$ICON_BATTERY_25"; COLOR=$YELLOW ;;
    *)          ICON="$ICON_BATTERY_0";  COLOR=$RED ;;
  esac
fi
sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color=$COLOR label="${PCT}%"
