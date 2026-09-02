#!/bin/bash
# Wi-Fi popup: power toggle, then networks in range (strongest first) with
# signal bars; the connected one is marked. Saved networks join on click,
# others open Wi-Fi settings (they need a password).
#
# Opens instantly from the last scan (cached 60s). If the cache is stale it
# shows saved networks meanwhile, scans in the background (~4s) and re-renders.
# When macOS hides SSIDs from scans (Location Services off) it stays on the
# saved list.
source "$CONFIG_DIR/plugins/wifi_lib.sh"
DEV="$(wifi_dev)"
POWER="$(wifi_power "$DEV")"
IP="$(ipconfig getifaddr "$DEV" 2>/dev/null)"
SSID="$(wifi_ssid "$DEV")"
RSSI="$(wifi_rssi)"
OFF="sketchybar --set wifi_popup popup.drawing=off"
SETTINGS="open 'x-apple.systempreferences:com.apple.wifi-settings-extension'"
FONT="Hack Nerd Font Mono:Regular:12.0"
SAVED="$(wifi_saved "$DEV")"

render() {   # $1 = scan ("SSID\tRSSI" lines) or ""
  local scan="$1" list mode
  if [ -n "$scan" ]; then mode=scan; list="$(printf '%s\n' "$scan" | head -12)"
  else mode=saved; list="$(printf '%s\n' "$SAVED" | head -12)"; fi

  {
    if [ "$POWER" = "On" ]; then echo "*Wi-Fi on — click to turn off"; else echo "*Wi-Fi off — click to turn on"; fi
    [ -n "$IP" ] && echo "#Connected: ${SSID:-unknown} · $IP${RSSI:+ · $(wifi_bars "$RSSI") ${RSSI} dBm}"
    echo "#"
    if [ "$mode" = scan ]; then echo "#Networks in range (click to join)"
    elif [ "$POWER" = "On" ] && [ "$2" = scanning ]; then echo "#Saved networks (scanning…)"
    else echo "#Saved networks (click to join)"; fi
    printf '%s\n' "$list" | while IFS=$'\t' read -r n r; do
      [ -z "$n" ] && continue
      mark="  "; [ -n "$SSID" ] && [ "$n" = "$SSID" ] && mark="*● "
      if [ "$mode" = scan ]; then
        saved=""; printf '%s\n' "$SAVED" | grep -qxF -- "$n" || saved="  ⚿"
        printf '%s%-22s %s%s\n' "$mark" "$n" "$(wifi_bars "$r")" "$saved"
      else
        echo "$mark$n"
      fi
    done
    echo "#"
    echo "#Other networks…"
  } | "$CONFIG_DIR/plugins/popup_rows.sh" wifi_popup wifi.row "$FONT"

  # clicks: header toggles power, network rows join (or open settings), last row opens settings
  local toggle n ssid r args
  toggle=$([ "$POWER" = "On" ] && echo off || echo on)
  args=(--set wifi.row.1 click_script="$OFF; networksetup -setairportpower $DEV $toggle; sleep 2; sketchybar --update")
  n=$([ -n "$IP" ] && echo 4 || echo 3)
  while IFS=$'\t' read -r ssid r; do
    [ -z "$ssid" ] && continue
    n=$((n+1))
    if printf '%s\n' "$SAVED" | grep -qxF -- "$ssid"; then
      args+=(--set "wifi.row.$n" click_script="$OFF; $CONFIG_DIR/plugins/wifi_join.sh $DEV \"$ssid\"")
    else
      args+=(--set "wifi.row.$n" click_script="$OFF; $SETTINGS")
    fi
  done <<< "$list"
  args+=(--set "wifi.row.$((n+2))" click_script="$OFF; $SETTINGS")   # "Other networks…"
  sketchybar "${args[@]}"
}

if [ "$POWER" != "On" ]; then render ""; exit 0; fi

if wifi_scan_fresh; then
  render "$(wifi_scan)"
  exit 0
fi

render "" scanning
(
  scan="$(wifi_scan)"
  # still open, and nobody re-rendered meanwhile?
  [ "$(sketchybar --query wifi_popup | jq -r '.popup.drawing')" = "on" ] || exit 0
  [ -n "$scan" ] && render "$scan" || render ""
) &
