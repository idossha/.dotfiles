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

window() {  # window <name> <pct> <reset-epoch>
  printf '  %-10s %3s%%  %s\n' "$1" "$2" "$(bar "$2")"
  [ -n "$3" ] && printf '#  %-10s resets %s\n' "" "$(date -r "$3" '+%a %H:%M')"
}

rows() {
  local plan; plan="$(claude_plan)"
  if ! claude_read; then
    [ -n "$plan" ] && printf '#plan %s\n' "$plan"
    echo "#no usage data yet"
    echo "#start a Claude Code session"
    return
  fi
  local age=$CLAUDE_AGE

  echo "*Claude Code usage"
  [ -n "$plan" ] && printf '  %-10s %s\n' "plan" "$plan"
  if [ -n "$CLAUDE_FIVE$CLAUDE_SEVEN" ]; then
    if [ -n "$CLAUDE_FIVE" ]; then window session "$CLAUDE_FIVE" "$CLAUDE_FIVE_RESET"
    else printf '#  %-10s not reported\n' "session"
    fi
    if [ -n "$CLAUDE_SEVEN" ]; then window weekly "$CLAUDE_SEVEN" "$CLAUDE_SEVEN_RESET"
    else printf '#  %-10s not reported\n' "weekly"
    fi
  fi
  if [ -n "$CLAUDE_SPEND" ]; then
    window spend "$CLAUDE_SPEND" "$CLAUDE_SPEND_RESET"
    [ -n "$CLAUDE_SPEND_LIMIT" ] && printf '#  %-10s $%.2f of $%.2f %s\n' "" \
      "$CLAUDE_SPEND_USED" "$CLAUDE_SPEND_LIMIT" "$CLAUDE_SPEND_PERIOD"
  fi

  echo "#"
  if [ "$age" -lt 3600 ]; then
    echo "#updated $((age / 60))m ago"
  else
    echo "#updated $((age / 3600))h ago"
  fi
}

rows | "$CONFIG_DIR/plugins/popup_rows.sh" claude_popup claude.row "Hack Nerd Font Mono:Regular:12.0"
