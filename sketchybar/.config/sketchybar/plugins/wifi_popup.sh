#!/bin/bash
# Wi-Fi popup (display only): power state, the current connection, and the
# networks in range (strongest first) with signal bars; the connected one is marked.
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
FONT="Hack Nerd Font Mono:Regular:12.0"
SAVED="$(wifi_saved "$DEV")"

render() {   # $1 = scan ("SSID\tRSSI" lines) or ""; $2 = "scanning" while a scan runs
  local scan="$1" list mode
  if [ -n "$scan" ]; then mode=scan; list="$(printf '%s\n' "$scan" | head -12)"
  else mode=saved; list="$(printf '%s\n' "$SAVED" | head -12)"; fi

  {
    if [ "$POWER" = "On" ]; then echo "*Wi-Fi on"; else echo "*Wi-Fi off"; fi
    [ -n "$IP" ] && echo "#Connected: ${SSID:-unknown} · $IP${RSSI:+ · $(wifi_bars "$RSSI") ${RSSI} dBm}"
    echo "#"
    if [ "$mode" = scan ]; then echo "#Networks in range"
    elif [ "$POWER" = "On" ] && [ "$2" = scanning ]; then echo "#Saved networks (scanning…)"
    else echo "#Saved networks"; fi
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
  } | "$CONFIG_DIR/plugins/popup_rows.sh" wifi_popup wifi.row "$FONT"
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
