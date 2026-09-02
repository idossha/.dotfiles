#!/bin/bash
# GlobalProtect state. Primary source: the last <state> in PanGPA.log.
# Fallback: a utun interface that is UP with an inet address (non-Tailscale).
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

LOG="$HOME/Library/Logs/PaloAltoNetworks/GlobalProtect/PanGPA.log"
STATE=""

if [ -r "$LOG" ]; then
  STATE="$(tail -c 300000 "$LOG" | grep -ao '<state>[^<]*' | tail -1 | sed 's/<state>//')"
fi

if [ -z "$STATE" ]; then
  if ifconfig | awk '/^utun[0-9]+: .*UP/{u=1;next} u&&/inet /{if($2!~/^100\./){f=1}; u=0} END{exit !f}'; then
    STATE="Connected"
  else
    STATE="Disconnected"
  fi
fi

if ! pgrep -qx GlobalProtect; then
  sketchybar --set "$NAME" icon="$ICON_VPN_OFF" icon.color=$MUTED label="GP" label.color=$MUTED
  exit 0
fi

case "$STATE" in
  Connected)
    sketchybar --set "$NAME" icon="$ICON_VPN" icon.color=$GREEN label="GP" label.color=$TEXT ;;
  Connecting*|Authenticating*|Discover*)
    sketchybar --set "$NAME" icon="$ICON_VPN" icon.color=$YELLOW label="GP" label.color=$TEXT ;;
  *)
    sketchybar --set "$NAME" icon="$ICON_VPN_OFF" icon.color=$TEXT_DIM label="GP" label.color=$TEXT_DIM ;;
esac
