#!/bin/bash
# Shared Wi-Fi helpers (sourced).

wifi_dev() {
  local d
  d="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2}')"
  echo "${d:-en0}"
}

# SSID from the root-only known-networks plist: the network most recently joined
# (by user or system). Needs the sudoers rule from install/sudoers/. Prints "" if
# unavailable.
wifi_ssid_from_known_networks() {
  sudo -n /usr/bin/plutil -convert xml1 -o - /Library/Preferences/com.apple.wifi.known-networks.plist 2>/dev/null \
  | python3 -c '
import plistlib, sys
try:
    d = plistlib.loads(sys.stdin.buffer.read())
except Exception:
    sys.exit(0)
best, best_t = "", None
for key, v in d.items():
    if not isinstance(v, dict): continue
    ssid = v.get("SSID")
    if isinstance(ssid, bytes):
        try: ssid = ssid.decode()
        except Exception: ssid = None
    if not ssid and key.startswith("wifi.network.ssid."):
        ssid = key[len("wifi.network.ssid."):]
    ts = [v.get(k) for k in ("JoinedByUserAt", "JoinedBySystemAt") if v.get(k) is not None]
    if not ssid or not ts: continue
    t = max(ts)
    if best_t is None or t > best_t: best, best_t = ssid, t
print(best)
' 2>/dev/null
}

# Current SSID or empty. Order: unprivileged tools (work when Location Services
# allows), `sudo -n wdutil info` (same restriction), then the known-networks plist.
wifi_ssid() {
  local dev="$1" s
  s="$(ipconfig getsummary "$dev" 2>/dev/null | awk -F' SSID : ' '/ SSID : /{print $2}')"
  case "$s" in ""|"<redacted>") s="" ;; esac
  if [ -z "$s" ]; then
    local info; info="$(sudo -n /usr/bin/wdutil info 2>/dev/null)"
    s="$(awk -F': *' '$1 ~ /^ *SSID *$/ {print $2; exit}' <<< "$info")"
    case "$s" in "<redacted>"|"None") s="" ;; esac
  fi
  if [ -z "$s" ] && [ -n "$(ipconfig getifaddr "$dev" 2>/dev/null)" ]; then
    s="$(wifi_ssid_from_known_networks)"
  fi
  printf '%s' "$s"
}

wifi_power() { networksetup -getairportpower "$1" 2>/dev/null | awk '{print $NF}'; }

wifi_saved() { networksetup -listpreferredwirelessnetworks "$1" 2>/dev/null | tail -n +2 | sed 's/^[[:space:]]*//'; }

# Current-network RSSI in dBm (unredacted even without Location Services).
wifi_rssi() {
  sudo -n /usr/bin/wdutil info 2>/dev/null | awk -F': *' '$1 ~ /^ *RSSI *$/ {print $2+0; exit}'
}

# dBm -> bar glyphs
wifi_bars() {
  local r="${1:-0}"
  if   [ "$r" -ge -55 ]; then echo "▂▄▆█"
  elif [ "$r" -ge -65 ]; then echo "▂▄▆_"
  elif [ "$r" -ge -75 ]; then echo "▂▄__"
  else                        echo "▂___"; fi
}

# Scan nearby networks: prints "SSID<TAB>RSSI" per line, strongest first, best
# RSSI per SSID. Takes ~4s. Names come out only when macOS lets us see them
# (Location Services -> System Services -> "Networking & wireless", or the root
# `wdutil scan` sudoers rule in install/sudoers/). Results cached 60s.
WIFI_SCAN_CACHE="${TMPDIR:-/tmp}/sketchybar-wifi-scan"
wifi_scan_fresh() {
  [ -f "$WIFI_SCAN_CACHE" ] && [ $(( $(date +%s) - $(stat -f %m "$WIFI_SCAN_CACHE") )) -lt 60 ]
}
wifi_scan() {
  local cache="$WIFI_SCAN_CACHE"
  if wifi_scan_fresh; then cat "$cache"; return; fi
  {
    # root wdutil scan (if allowed): columns  SSID  BSSID  RSSI ...
    sudo -n /usr/bin/wdutil scan 2>/dev/null | awk -F'  +' '
      /^ *SSID +BSSID/ {hdr=1; next}
      hdr && NF>=3 && $1!="" && $1!="<redacted>" { for(i=1;i<=NF;i++) if($i ~ /^-?[0-9]+ ?dBm/){ sub(/ ?dBm/,"",$i); print $1"\t"$i+0; break } }'
    # system_profiler (works when Location Services allows)
    system_profiler SPAirPortDataType 2>/dev/null | awk '
      /Other Local Wi-Fi Networks:/ {f=1; next}
      f && /^ {12}[^ ]/ { n=$0; sub(/^ +/,"",n); sub(/:$/,"",n) }
      f && /Signal \/ Noise:/ && n!="<redacted>" { split($0,a,":"); split(a[2],b," "); print n"\t"b[1]+0 }'
  } | awk -F'\t' '$1!="" { if(!($1 in m) || $2>m[$1]) m[$1]=$2 } END { for(k in m) print k"\t"m[k] }' \
    | sort -t$'\t' -k2,2nr > "$cache.tmp" && mv "$cache.tmp" "$cache"
  cat "$cache"
}
