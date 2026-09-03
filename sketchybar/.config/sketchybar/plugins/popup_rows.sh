#!/bin/bash
# popup_rows.sh <owner-item> <prefix> <font> <<< "line\nline..."
# Replaces the rows of a popup with the lines read on stdin (one sketchybar call).
# Rows are display-only: no click_script, no hover highlight.
OWNER="$1"; PREFIX="$2"; FONT_SPEC="$3"
source "$CONFIG_DIR/colors.sh"
args=()
for old in $(sketchybar --query "$OWNER" | jq -r '.popup.items[]?' 2>/dev/null); do
  args+=(--remove "$old")
done
i=0
while IFS= read -r line; do
  i=$((i+1))
  color=$TEXT
  # lines prefixed with "#" render dimmed (headers/notes); "*" = accent,
  # "+" = green (healthy), "!" = yellow (needs attention)
  case "$line" in
    "#"*) color=$TEXT_DIM; line="${line#\#}" ;;
    "*"*) color=$ACCENT;   line="${line#\*}" ;;
    "+"*) color=$GREEN;    line="${line#+}"   ;;
    "!"*) color=$YELLOW;   line="${line#!}"   ;;
  esac
  # sketchybar mis-measures labels with leading whitespace (they get clipped), so
  # turn indentation into label padding instead: ~7px per space at 12pt mono.
  indent="${line%%[! ]*}"; line="${line#"${indent}"}"
  pad=$((10 + ${#indent} * 7))
  args+=(--add item "$PREFIX.$i" "popup.$OWNER" \
    --set "$PREFIX.$i" icon.drawing=off \
      label="$line" label.font="$FONT_SPEC" label.color=$color \
      label.padding_left=$pad label.padding_right=10 \
      padding_left=0 padding_right=0 background.drawing=off)
done
[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}" 2>/dev/null
