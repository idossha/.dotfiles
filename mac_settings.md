show full path in finder
remove warning when changing extensions 
remove spotlight shortcut


```bash

#!/bin/bash
# Disable Spotlight shortcut
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{enabled = 0; value = { parameters = ( 100, 0, 1048576 ); type = standard; }; }"

# Disable extension warnings
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false


```
