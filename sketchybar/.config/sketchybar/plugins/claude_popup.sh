#!/bin/bash
# Popup rows for the `claude` item: each window's usage and when it resets.
CACHE="$HOME/.cache/sketchybar/claude_usage.json"

rows() {
  if [ ! -r "$CACHE" ]; then
    echo "#no usage data yet"
    echo "#start a Claude Code session"
    return
  fi

  echo "*Claude Code usage"

  emit() {  # emit <label> <jq-key>
    local pct reset
    pct="$(jq -r ".${2}.used_percentage // empty | round" "$CACHE" 2>/dev/null)"
    [ -z "$pct" ] && return
    reset="$(jq -r ".${2}.resets_at // empty" "$CACHE" 2>/dev/null)"
    printf '  %-10s %3s%%  %s\n' "$1" "$pct" "$(bar "$pct")"
    [ -n "$reset" ] && printf '#  %-10s resets %s\n' "" "$(date -r "$reset" '+%a %H:%M')"
  }

  emit "session" five_hour
  emit "weekly"  seven_day

  local age
  age=$(( ($(date +%s) - $(stat -f %m "$CACHE")) / 60 ))
  echo "#"
  if [ "$age" -lt 60 ]; then
    echo "#updated ${age}m ago"
  else
    echo "#updated $((age / 60))h ago"
  fi
}

bar() {  # 10-cell meter
  local filled=$(( ($1 + 5) / 10 )) i out=""
  [ "$filled" -gt 10 ] && filled=10
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then out="$out#"; else out="$out."; fi
  done
  printf '%s' "$out"
}

rows | "$CONFIG_DIR/plugins/popup_rows.sh" claude_popup claude.row "Hack Nerd Font Mono:Regular:12.0"
