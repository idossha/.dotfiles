#!/bin/bash

# The directory where the dotfiles are located
DOTFILES_DIR="$HOME/.dotfiles"

# The home directory where the symlinks will be created
HOME_DIR="$HOME"

# Loop through all files and directories in the .dotfiles directory
for file in "$DOTFILES_DIR"/.*; do
    # Get the base filename
    filename=$(basename "$file")
    # Skip the . and .. directories
    if [ "$filename" == "." ] || [ "$filename" == ".." ] || [ "$filename" == ".git" ]; then
        continue
    fi
    # Create a symlink in the home directory, forcing overwrite if necessary
    ln -sf "$file" "$HOME_DIR/$filename"
done

echo "Symlinks created successfully."

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Ensure your system is ready to brew.
echo "Running brew doctor..."
brew doctor

echo "Running brew update..."
brew update

# Install Xcode Command Line Tools
xcode-select --install

# Brew install packages
BREW_CASK_PACKAGES=(
  iterm2
  rectangle
)

BREW_PACKAGES=(
  tmux
  git
  neovim
  ripgrep
  node
  jq
)

echo "Installing brew cask packages..."
for package in "${BREW_CASK_PACKAGES[@]}"; do
  brew install --cask $package
done

echo "Tapping into homebrew/cask-fonts..."
brew tap homebrew/cask-fonts

echo "Installing brew packages..."
for package in "${BREW_PACKAGES[@]}"; do
  brew install $package
done

echo "Installing font-hack-nerd-font..."
brew install font-hack-nerd-font

# Check for Oh My Zsh, install if we don't have it
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zsh-autosuggestions & zsh-syntax-highlighting
ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM_PLUGINS}/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM_PLUGINS}/zsh-syntax-highlighting

echo "Script execution finished!"

