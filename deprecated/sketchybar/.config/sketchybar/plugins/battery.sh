
#!/bin/bash

source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/colors.sh"

BATTERY_INFO="$(pmset -g batt 2>/dev/null)"

# Check if no battery is present (common on desktops like iMacs)
if echo "$BATTERY_INFO" | grep -qi "no battery"; then
  # Hide the battery item since it's not applicable
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

PERCENTAGE=$(echo "$BATTERY_INFO" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(echo "$BATTERY_INFO" | grep 'AC Power')

# If PERCENTAGE is empty for some reason, hide the item
if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

DRAWING=on
COLOR=$WHITE

case $PERCENTAGE in
  9[0-9]|100)
    ICON=$BATTERY_100
    DRAWING=off
    ;;
  [6-8][0-9])
    ICON=$BATTERY_75
    DRAWING=off
    ;;
  [3-5][0-9])
    ICON=$BATTERY_50
    ;;
  [1-2][0-9])
    ICON=$BATTERY_25
    COLOR=$ORANGE
    ;;
  *)
    ICON=$BATTERY_0
    COLOR=$RED
    ;;
esac

if [ -n "$CHARGING" ]; then
  ICON=$BATTERY_CHARGING
  DRAWING=off
fi

sketchybar --set "$NAME" drawing=$DRAWING icon="$ICON" icon.color=$COLOR

