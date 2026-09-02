#!/bin/bash
# wifi_join.sh <dev> <ssid> — join a saved network, showing progress in the bar.
DEV="$1"; SSID="$2"
sketchybar --set wifi label="joining $SSID…"
OUT="$(networksetup -setairportnetwork "$DEV" "$SSID" 2>&1)"
if [ -n "$OUT" ]; then
  # networksetup prints only on failure ("Could not find network", "Failed to join")
  sketchybar --set wifi label="$OUT" icon.color=0xfff38ba8
  sleep 4
fi
rm -f "${TMPDIR:-/tmp}/sketchybar-wifi-scan"   # force a rescan next open
sleep 2; sketchybar --update
