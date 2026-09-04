#!/bin/bash
source "$CONFIG_DIR/plugins/codex_lib.sh"
codex_refresh
codex_set_label

bar() {
  local filled=$(( ($1 + 5) / 10 )) i out=""
  [ "$filled" -gt 10 ] && filled=10
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then out="$out#"; else out="$out."; fi
  done
  printf '%s' "$out"
}

rows() {
  local windows id label pct reset
  if ! windows="$(codex_windows)"; then
    echo "#no usage data yet"
    echo "#Codex usage will appear after the first refresh"
    return
  fi
  echo "*Codex usage"
  while IFS=$'\t' read -r id label pct reset; do
    printf '  %-18s %3s%%  %s\n' "$label" "$pct" "$(bar "$pct")"
    [ -n "$reset" ] && printf '#  %-18s resets %s\n' "" "$(date -j -f '%Y-%m-%dT%H:%M:%S' "${reset%%.*}" '+%a %H:%M' 2>/dev/null || printf '%s' "$reset")"
  done <<< "$windows"
  echo "#"
  echo "#updated $(date '+%H:%M')"
}

rows | "$CONFIG_DIR/plugins/popup_rows.sh" codex_popup codex.row "Hack Nerd Font Mono:Regular:12.0"
