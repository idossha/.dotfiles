#!/bin/bash
# Smoke tests for the SketchyBar config. Runs every plugin the way sketchybar does
# (minimal launchd-like environment) against the live bar and checks the results.
#
#   ~/.config/sketchybar/tests/run_tests.sh          # all
#   ~/.config/sketchybar/tests/run_tests.sh wifi     # only tests matching "wifi"
#
# Requires a running sketchybar (brew services start sketchybar).

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS="$CONFIG_DIR/plugins"
FILTER="${1:-}"
PASS=0; FAIL=0

# Same env sketchybar's launchd job gives to scripts: no shell rc, plain PATH.
run_as_bar() { # run_as_bar <NAME> <cmd...>
  local name="$1"; shift
  env -i USER="$USER" HOME="$HOME" LANG=en_US.UTF-8 \
      PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin \
      CONFIG_DIR="$CONFIG_DIR" NAME="$name" SENDER="${SENDER:-routine}" \
      bash --noprofile --norc -c "$*"
}
q() { sketchybar --query "$1" 2>/dev/null | jq -r "$2"; }
click() { run_as_bar "$1" "$(q "$1" .scripting.click_script)"; }

t() { # t <name> <command...>  (command must exit 0)
  local name="$1"; shift
  [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]] && return
  if "$@" >/dev/null 2>&1; then PASS=$((PASS+1)); printf '  ok   %s\n' "$name"
  else FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$name"; fi
}
export CONFIG_DIR PLUGINS
export -f run_as_bar q click

sketchybar --query bar >/dev/null 2>&1 || { echo "sketchybar is not running"; exit 2; }
# hotload reloads the bar whenever a file under CONFIG_DIR changes (this file included);
# wait until every item exists again, then let the first update cycle finish.
for _ in $(seq 1 20); do
  sketchybar --query battery >/dev/null 2>&1 && sketchybar --query wifi_popup >/dev/null 2>&1 && break
  sleep 0.5
done
sleep 2
echo "== bar =="
t "bar is at top"                 [ "$(q bar .position)" = "top" ]
t "all items exist"               bash -c 'for i in apple clock wifi docker vpn amphetamine cpu memory battery stats claude claude_popup clock_popup wifi_popup; do sketchybar --query $i >/dev/null || exit 1; done'
t "workspace items exist"         bash -c 'for s in $(aerospace list-workspaces --all); do sketchybar --query space.$s >/dev/null || exit 1; done'

echo "== plugins (periodic scripts) =="
t "clock sets a label"            bash -c 'run_as_bar clock "$PLUGINS/clock.sh"; [[ "$(q clock .label.value)" =~ [0-9]{2}:[0-9]{2} ]]'
t "cpu label is a percent"        bash -c 'run_as_bar cpu "$PLUGINS/cpu.sh"; [[ "$(q cpu .label.value)" =~ ^[0-9]+%$ ]]'
t "memory label is a percent"     bash -c 'run_as_bar memory "$PLUGINS/memory.sh"; [[ "$(q memory .label.value)" =~ ^[0-9]+%$ ]]'
t "battery label is a percent"    bash -c 'run_as_bar battery "$PLUGINS/battery.sh"; [[ "$(q battery .label.value)" =~ ^[0-9]+%$ ]]'
t "wifi label non-empty"          bash -c 'run_as_bar wifi "$PLUGINS/wifi.sh"; [ -n "$(q wifi .label.value)" ]'
t "docker plugin runs"            run_as_bar docker "$PLUGINS/docker.sh"
t "vpn plugin runs"               run_as_bar vpn "$PLUGINS/vpn.sh"
t "amphetamine plugin runs"       run_as_bar amphetamine "$PLUGINS/amphetamine.sh"
t "claude label is two percents" bash -c 'run_as_bar claude "$PLUGINS/claude_usage.sh"; [[ "$(q claude .label.value)" =~ ^([0-9]+%\ [0-9]+%|—)$ ]]'
t "claude usage cache is valid json" bash -c '[ ! -e "$HOME/.cache/sketchybar/claude_usage.json" ] || jq -e .five_hour.used_percentage "$HOME/.cache/sketchybar/claude_usage.json"'
t "focused workspace highlighted" bash -c 'f=$(aerospace list-workspaces --focused); run_as_bar space.$f "$PLUGINS/spaces.sh $f"; [ "$(q space.$f .geometry.background.drawing)" = "on" ]'

echo "== wifi ssid =="
source "$PLUGINS/wifi_lib.sh"
export -f wifi_dev wifi_ssid wifi_saved wifi_power wifi_ssid_from_known_networks wifi_rssi wifi_bars wifi_scan wifi_scan_fresh
if sudo -n /usr/bin/plutil -convert xml1 -o - /Library/Preferences/com.apple.wifi.known-networks.plist >/dev/null 2>&1; then
  t "ssid readable via known-networks" bash -c '[ -n "$(wifi_ssid "$(wifi_dev)")" ]'
else
  echo "  skip ssid test: sudoers rule not installed (run install/macos_defaults.sh)"
fi

echo "== popups (click scripts) =="
t "calendar popup opens with rows"   bash -c 'click clock; [ "$(q clock_popup .popup.drawing)" = on ] && [ "$(q clock_popup ".popup.items|length")" -ge 6 ]'
t "calendar first week not clipped"  bash -c 'q cal.row.3 .label.value | grep -q "1"'
t "calendar rows have no leading ws" bash -c '! q cal.row.3 .label.value | grep -q "^[[:space:]]"'
t "indented rows get label padding"  bash -c 'click wifi; p=$(q wifi.row.6 .label.padding_left); sketchybar --set wifi_popup popup.drawing=off; [ "$p" -gt 10 ]'
t "calendar popup closes on 2nd click" bash -c 'click clock; [ "$(q clock_popup .popup.drawing)" = off ]'
t "wifi popup opens fast (<1s)"      bash -c 's=$(date +%s); click wifi; e=$(date +%s); [ $((e-s)) -le 1 ] && [ "$(q wifi_popup .popup.drawing)" = on ]'
t "wifi popup lists saved networks"  bash -c 'first=$(wifi_saved "$(wifi_dev)" | head -1); sketchybar --query wifi_popup | jq -r ".popup.items[]" | while read r; do q $r .label.value; done | grep -q "$first"'
# sketchybar reports an unset script as the string "(null)".
unset_p() { [ -z "$1" ] || [ "$1" = "(null)" ]; }
export -f unset_p
t "popup rows are display-only"      bash -c 'for o in wifi_popup clock_popup stats claude_popup; do for r in $(sketchybar --query $o | jq -r ".popup.items[]?"); do unset_p "$(q $r .scripting.click_script)" || exit 1; unset_p "$(q $r .scripting.script)" || exit 1; done; done'
t "only popup toggles on view items" bash -c 'for i in wifi docker cpu memory battery claude clock; do c=$(q $i .scripting.click_script); unset_p "$c" && continue; case "$c" in *"popup.sh toggle"*) ;; *) exit 1 ;; esac; done'
t "amphetamine click toggles"        bash -c 'q amphetamine .scripting.click_script | grep -q "amphetamine.sh toggle"'
t "globalprotect click opens app"    bash -c 'q vpn .scripting.click_script | grep -q "open -a GlobalProtect"'
t "wifi popup closes on 2nd click"   bash -c 'click wifi; [ "$(q wifi_popup .popup.drawing)" = off ]'
t "stats popup opens with rows"      bash -c 'click cpu; [ "$(q stats .popup.drawing)" = on ] && [ "$(q stats ".popup.items|length")" -ge 10 ]'
t "stats popup closes on 2nd click"  bash -c 'click memory; [ "$(q stats .popup.drawing)" = off ]'
t "claude popup opens with rows"     bash -c 'click claude; [ "$(q claude_popup .popup.drawing)" = on ] && [ "$(q claude_popup ".popup.items|length")" -ge 2 ]'
t "claude popup closes on 2nd click" bash -c 'click claude; [ "$(q claude_popup .popup.drawing)" = off ]'
t "claude popup survives a refresh"  bash -c 'click claude; run_as_bar claude "$PLUGINS/claude_usage.sh"; SENDER=claude_usage run_as_bar claude "$PLUGINS/claude_usage.sh"; s=$(q claude_popup .popup.drawing); click claude; [ "$s" = on ]'
t "claude item owns no popup"        bash -c '[ "$(q claude ".popup.items|length")" -eq 0 ]'
t "claude exit event hides popup"    bash -c 'sketchybar --set claude_popup popup.drawing=on; SENDER=mouse.exited.global run_as_bar claude_popup "$PLUGINS/popup.sh"; [ "$(q claude_popup .popup.drawing)" = off ]'
t "apple popup has menu rows"        bash -c '[ "$(q apple ".popup.items|length")" -ge 8 ]'
t "mouse.exited.global hides popup"  bash -c 'sketchybar --set stats popup.drawing=on; SENDER=mouse.exited.global run_as_bar stats "$PLUGINS/popup.sh"; [ "$(q stats .popup.drawing)" = off ]'

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
