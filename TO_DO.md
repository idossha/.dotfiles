brew tap FelixKratz/formulae
brew install sketchybar

mkdir -p ~/.config/sketchybar/plugins
cp /opt/homebrew/opt/sketchybar/share/sketchybar/examples/sketchybarrc ~/.config/sketchybar/sketchybarrc
cp -r /opt/homebrew/opt/sketchybar/share/sketchybar/examples/plugins/ ~/.config/sketchybar/plugins/
chmod +x ~/.config/sketchybar/plugins/*

# Restart sketchybar to apply the changes
brew services restart felixkratz/formulae/sketchybar

# Run sketchybar at startup
brew services start sketchybar

brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# Fonts that I personally use
brew install --cask font-meslo-lg-nerd-font


# This shows the apple logo and rest of icons on the right
brew install --cask sf-symbols

# jq is used for parsing JSON data to extract specific pieces of information
# such as network status, media playback information, GitHub notifications, etc
brew install jq

# This installs the github cli tool
brew install gh

# This is used for switching audio sources and displaying microphone name
brew install switchaudio-osx

# This shows the icons for the apps
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.23/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf

cd ~/github/sketchybar
find . -name "*.sh" -type f -exec chmod +x {} +
find . -name "helper" -type f -exec chmod +x {} +
find . -name "*.sh" -type f -exec ls -l {} +
find . -name "helper" -type f -exec ls -l {} +

brew services start sketchybar

brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# Fonts that I personally use
brew install --cask font-meslo-lg-nerd-font
