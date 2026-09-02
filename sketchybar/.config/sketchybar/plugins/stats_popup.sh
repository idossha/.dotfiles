#!/bin/bash
# System details popup for the cpu/mem/battery bracket.
LOAD="$(sysctl -n vm.loadavg | tr -d '{}' | awk '{print $1" "$2" "$3}')"
CORES="$(sysctl -n hw.ncpu)"
UP="$(uptime | sed -E 's/.*up +([^,]+(, +[0-9:]+)?),.*/\1/')"
MEM_TOTAL="$(( $(sysctl -n hw.memsize) / 1073741824 ))"
FREE_PCT="$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}')"
MEM_USED="$(awk -v t="$MEM_TOTAL" -v f="${FREE_PCT:-0}" 'BEGIN{printf "%.1f", t*(100-f)/100}')"
SWAP="$(sysctl -n vm.swapusage | awk '{print $6}')"
DISK="$(df -h / | awk 'NR==2{print $3" / "$2"  ("$5")"}')"
BATT="$(pmset -g batt | tail -1 | sed -E 's/.*\t//; s/ present.*//')"
CYCLES="$(system_profiler SPPowerDataType 2>/dev/null | awk -F': ' '/Cycle Count/{print $2} /Maximum Capacity/{cap=$2} END{if(cap) print "health " cap}' | paste -sd' ' -)"
TEMP="$(sudo -n powermetrics --samplers smc -n1 -i1 2>/dev/null | awk -F': ' '/CPU die temperature/{print $2}')"

{
  echo "*CPU"
  echo "load      $LOAD  ($CORES cores)"
  [ -n "$TEMP" ] && echo "temp      $TEMP"
  ps -Aceo pcpu,comm -r | awk 'NR>1 && NR<=4 {printf "· %-22.22s %5.1f%%\n", substr($0, index($0,$2)), $1}'
  echo "#"
  echo "*Memory"
  echo "used      ${MEM_USED} / ${MEM_TOTAL} GB"
  echo "swap      $SWAP"
  ps -Aceo rss,comm -m | awk 'NR>1 && NR<=4 {printf "· %-22.22s %5.1fG\n", substr($0, index($0,$2)), $1/1048576}'
  echo "#"
  echo "*Disk"
  echo "/         $DISK"
  echo "#"
  echo "*Battery"
  echo "$BATT"
  [ -n "$CYCLES" ] && echo "cycles    $CYCLES"
  echo "#"
  echo "#up $UP · click to open Stats"
} | "$CONFIG_DIR/plugins/popup_rows.sh" stats stats.row "Hack Nerd Font Mono:Regular:12.0"

LAST="$(sketchybar --query stats | jq -r '.popup.items | length')"
sketchybar --set "stats.row.$LAST" click_script="open -a Stats; sketchybar --set stats popup.drawing=off"
