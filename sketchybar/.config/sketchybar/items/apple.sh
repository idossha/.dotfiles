#!/bin/bash
# Apple logo with a minimal popup menu

POPUP_OFF="sketchybar --set apple popup.drawing=off"

sketchybar --add item apple left \
  --set apple \
    icon="$ICON_APPLE" \
    icon.font="$FONT:Bold:16.0" \
    icon.color=$TEXT \
    icon.padding_left=8 \
    icon.padding_right=8 \
    label.drawing=off \
    padding_right=6 \
    script="$PLUGIN_DIR/popup.sh" \
    click_script="sketchybar --set apple popup.drawing=toggle" \
    popup.align=left \
    popup.height=24 \
  --subscribe apple mouse.exited.global

add_menu_item() {
  # $1 name, $2 label, $3 command
  sketchybar --add item "apple.$1" popup.apple \
    --set "apple.$1" \
      icon.drawing=off \
      label="$2" \
      label.font="$FONT:Regular:12.0" \
      label.padding_left=10 \
      label.padding_right=10 \
      padding_left=0 \
      padding_right=0 \
      background.height=20 \
      background.drawing=off \
      click_script="$POPUP_OFF; $3"
}

add_menu_item about        "About This Mac"     "open -b com.apple.systempreferences; open 'x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension'"
add_menu_item settings     "System Settings…"   "open -b com.apple.systempreferences"
add_menu_item activity     "Activity Monitor"   "open -a 'Activity Monitor'"
add_menu_item sep1         "──────────"      ":"
add_menu_item sleep        "Sleep"              "pmset sleepnow"
add_menu_item lock         "Lock Screen"        "$PLUGIN_DIR/apple_menu.sh lock"
add_menu_item sep2         "──────────"      ":"
add_menu_item restart      "Restart…"           "$PLUGIN_DIR/apple_menu.sh restart"
add_menu_item shutdown     "Shut Down…"         "$PLUGIN_DIR/apple_menu.sh shutdown"
add_menu_item logout       "Log Out…"           "$PLUGIN_DIR/apple_menu.sh logout"
add_menu_item sep3         "──────────"      ":"
add_menu_item reload       "Reload SketchyBar"  "sketchybar --reload"

for sep in sep1 sep2 sep3; do sketchybar --set "apple.$sep" label.color=$MUTED background.height=10; done
