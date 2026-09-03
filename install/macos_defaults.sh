#!/bin/bash
# macOS system settings for the SketchyBar + AeroSpace setup.
# Idempotent; safe to re-run. Called from apple_install.sh, or run directly.

set -euo pipefail

echo "Applying macOS defaults..."

# --- Menu bar: hide the native one so SketchyBar owns the top edge ---------
# "Automatically hide and show the menu bar" -> Always
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false
# Apply immediately without logging out
osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to true' >/dev/null 2>&1 || true

# --- Mission Control: required by AeroSpace ------------------------------
# Desktop & Dock -> Mission Control -> "Group windows by application" = on
defaults write com.apple.dock expose-group-apps -bool true
# Keep Spaces in a fixed order (AeroSpace manages workspaces itself)
defaults write com.apple.dock mru-spaces -bool false
# Displays have separate Spaces (recommended by AeroSpace for multi-monitor)
defaults write com.apple.spaces spans-displays -bool false

killall Dock >/dev/null 2>&1 || true

# --- sudoers: let the SketchyBar wifi plugin read the SSID via `wdutil info` -------
SUDOERS_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sudoers/sketchybar-wdutil"
SUDOERS_DST="/etc/sudoers.d/sketchybar-wdutil"
if [ -f "$SUDOERS_SRC" ] && ! sudo -n cmp -s "$SUDOERS_SRC" "$SUDOERS_DST" 2>/dev/null; then
  if visudo -cf "$SUDOERS_SRC" >/dev/null 2>&1 || sudo visudo -cf "$SUDOERS_SRC" >/dev/null; then
    echo "Installing $SUDOERS_DST (needs sudo; lets the bar show the Wi-Fi name)"
    sudo install -o root -g wheel -m 0440 "$SUDOERS_SRC" "$SUDOERS_DST" || echo "  skipped (no sudo)"
  fi
fi

# --- SketchyBar as a launchd service ------------------------------------
if command -v sketchybar >/dev/null 2>&1; then
  brew services start sketchybar >/dev/null 2>&1 || brew services restart sketchybar >/dev/null 2>&1 || true
fi

echo "macOS defaults applied. Log out/in if the menu bar is still visible."

# --- Vicinae launcher (Raycast replacement) ------------------------------
# Config is stowed to ~/.config/vicinae; custom theme to ~/.local/share/vicinae/themes.
# Vicinae registers itself as a login item on first launch. Toggle: alt+space.
if [ -d /Applications/Vicinae.app ] && ! pgrep -xq Vicinae; then
  open -a Vicinae >/dev/null 2>&1 || true
fi

# --- OpenSuperWhisper dictation ------------------------------------------
# Local whisper transcription (replaces the commercial superwhisper).
# Settings live in the ru.starmel.OpenSuperWhisper defaults domain, not in a
# stowed dotfile; the model is downloaded from the app's onboarding screen.
# Hold right-option to record, release to transcribe and paste.
if [ -d /Applications/OpenSuperWhisper.app ]; then
  if ! osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q OpenSuperWhisper; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/OpenSuperWhisper.app", hidden:true}' >/dev/null 2>&1 || true
  fi
  pgrep -xq OpenSuperWhisper || open -a OpenSuperWhisper >/dev/null 2>&1 || true
fi
