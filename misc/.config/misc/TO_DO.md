### add this to installation sciprt and test 


```
brew tap FelixKratz/formulae
brew install sketchybar


- all bash script should be executable
cd ~/.config/sketchybar
find . -name "*.sh" -type f -exec chmod +x {} +
find . -name "helper" -type f -exec chmod +x {} +
find . -name "*.sh" -type f -exec ls -l {} +
find . -name "helper" -type f -exec ls -l {} +

- Restart sketchybar to apply the changes
brew services restart felixkratz/formulae/sketchybar

- Run sketchybar at startup
brew services start sketchybar

-fonts:
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install --cask font-meslo-lg-nerd-font
brew install --cask sf-symbols

- This installs the github cli tool
brew install gh

- This is used for switching audio sources and displaying microphone name
brew install switchaudio-osx

- This shows the icons for the apps
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.23/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf

```


### NVIM

Collect on NVIM key bindings in one place?
redo you NVIM directory strucutre to reduce cluter



