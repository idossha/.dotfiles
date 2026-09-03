#!/bin/bash
# Popup rows for the Claude Code usage item: each window's usage and reset time.
source "$CONFIG_DIR/plugins/claude_lib.sh"

# Refresh the label from the same read that fills the popup, so the two can't
# show different numbers when the cache changed since the item's last tick.
claude_set_label

bar() {  # 10-cell meter
  local filled=$(( ($1 + 5) / 10 )) i out=""
  [ "$filled" -gt 10 ] && filled=10
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then out="$out#"; else out="$out."; fi
  done
  printf '%s' "$out"
}

rows() {
  local five seven age
  if ! read -r five seven age < <(claude_read); then
    echo "#no usage data yet"
    echo "#start a Claude Code session"
    return
  fi

  echo "*Claude Code usage"
  printf '  %-10s %3s%%  %s\n' "session" "$five"  "$(bar "$five")"
  printf '#  %-10s resets %s\n' "" "$(date -r "$(jq -r '.five_hour.resets_at' "$CLAUDE_CACHE")" '+%a %H:%M')"
  printf '  %-10s %3s%%  %s\n' "weekly"  "$seven" "$(bar "$seven")"
  printf '#  %-10s resets %s\n' "" "$(date -r "$(jq -r '.seven_day.resets_at' "$CLAUDE_CACHE")" '+%a %H:%M')"

  echo "#"
  if [ "$age" -lt 3600 ]; then
    echo "#updated $((age / 60))m ago"
  else
    echo "#updated $((age / 3600))h ago"
  fi
}

rows | "$CONFIG_DIR/plugins/popup_rows.sh" claude_popup claude.row "Hack Nerd Font Mono:Regular:12.0"
