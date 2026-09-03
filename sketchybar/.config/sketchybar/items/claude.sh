#!/bin/bash
# Claude Code plan usage: session (5h) and weekly (7d) percentages. Click for details.
#
# The popup hangs off a bracket rather than the item itself: an item that owns its
# own popup races its click handler against its own hover events, so the popup
# sometimes fails to open. Every other popup here is owned by a separate item.
# The custom event must be registered before anything can subscribe to it;
# `--trigger` on an unregistered event exits 0 and does nothing, which left the
# label up to update_freq seconds behind the popup.
sketchybar --add event claude_usage

sketchybar --add item claude right \
  --set claude \
    icon="$ICON_CLAUDE" \
    update_freq=60 \
    script="$PLUGIN_DIR/claude_usage.sh" \
    click_script="$PLUGIN_DIR/popup.sh toggle claude_popup $PLUGIN_DIR/claude_popup.sh" \
  --subscribe claude claude_usage

sketchybar --add bracket claude_popup claude \
  --set claude_popup \
    popup.align=right \
    popup.height=18 \
    script="$PLUGIN_DIR/popup.sh" \
  --subscribe claude_popup mouse.exited.global
