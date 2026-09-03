#!/bin/bash
# GlobalProtect VPN status; click opens the GlobalProtect app
sketchybar --add item vpn right \
  --set vpn \
    icon="$ICON_VPN_OFF" \
    label="GP" \
    update_freq=10 \
    script="$PLUGIN_DIR/vpn.sh" \
    click_script="open -a GlobalProtect" \
  --subscribe vpn system_woke
