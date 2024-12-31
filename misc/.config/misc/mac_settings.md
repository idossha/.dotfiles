show full path in finder
remove warning when changing extensions 
remove spotlight shortcut


```bash

#!/bin/bash
# Disable Spotlight shortcut
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{enabled = 0; value = { parameters = ( 100, 0, 1048576 ); type = standard; }; }"

# Disable extension warnings
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true


```
