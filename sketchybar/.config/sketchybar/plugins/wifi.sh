#!/bin/bash
# Bar item: Wi-Fi name (via `sudo -n wdutil info`, see install/sudoers/), else IP.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/plugins/wifi_lib.sh"

DEV="$(wifi_dev)"
IP="$(ipconfig getifaddr "$DEV" 2>/dev/null)"
if [ -n "$IP" ]; then
  SSID="$(wifi_ssid "$DEV")"
  sketchybar --set "$NAME" icon="$ICON_WIFI" icon.color=$GREEN label="${SSID:-$IP}" label.drawing=on
  exit 0
fi

# Any other active interface (ethernet / usb)?
for dev in $(ifconfig -lu | tr ' ' '\n' | grep -E '^en[0-9]+$' | grep -v "^$DEV$"); do
  IP="$(ipconfig getifaddr "$dev" 2>/dev/null)"
  if [ -n "$IP" ]; then
    sketchybar --set "$NAME" icon="$ICON_ETHERNET" icon.color=$GREEN label="$IP" label.drawing=on
    exit 0
  fi
done

if [ "$(networksetup -getairportpower "$DEV" 2>/dev/null | awk '{print $NF}')" = "On" ]; then
  sketchybar --set "$NAME" icon="$ICON_WIFI" icon.color=$TEXT_DIM label="no network" label.drawing=on
else
  sketchybar --set "$NAME" icon="$ICON_WIFI_OFF" icon.color=$RED label="off" label.drawing=on
fi
