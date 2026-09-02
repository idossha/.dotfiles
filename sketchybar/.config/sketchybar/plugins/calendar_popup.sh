#!/bin/bash
# Monthly calendar with today highlighted, plus next few events if `icalBuddy` exists.
TODAY="$(date +%-d)"
{
  cal -h | sed -e '/^[[:space:]]*$/d' | awk 'NR==1{gsub(/^ +| +$/,""); print "*"$0; next} NR==2{print "#"$0; next} {print}'
  if command -v icalBuddy >/dev/null 2>&1; then
    echo "#"
    echo "*Upcoming"
    icalBuddy -n -nc -nrd -iep "datetime,title" -po "datetime,title" -ps "| · |" -b "" -df "%a %d" -tf "%H:%M" -ea eventsToday+3 2>/dev/null | head -8
  fi
} | "$CONFIG_DIR/plugins/popup_rows.sh" clock_popup cal.row "Hack Nerd Font Mono:Regular:12.0"

# highlight the row containing today (best effort: the first grid row with today's number as a word)
n=0
cal -h | sed -e '/^[[:space:]]*$/d' | while IFS= read -r line; do
  n=$((n+1))
  [ $n -le 2 ] && continue
  if echo " $line " | grep -qE "(^|[^0-9])$TODAY([^0-9]|$)"; then
    sketchybar --set "cal.row.$n" label.color=0xffeed49f
    break
  fi
done
sketchybar --set "cal.row.$(( $(cal -h | sed -e '/^[[:space:]]*$/d' | wc -l) + 1 ))" click_script="open -a Calendar; sketchybar --set clock_popup popup.drawing=off" 2>/dev/null
