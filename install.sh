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
if ! command -v brew &> /dev/null; then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Ensure your system is ready to brew.
echo "Running brew doctor..."
brew doctor

echo "Running brew update..."
brew update

# Check and Install Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
fi

# List of brew and cask packages
BREW_CASK_PACKAGES=(
  iterm2
  rectangle
  keyboardcleantool
)
BREW_PACKAGES=(
  tmux
  git
  neovim
  ripgrep
  node
  jq
  tree-sitter
  pillow
  pandoc
  ffmpeg
)

# Install Brew cask packages
echo "Installing brew cask packages..."
for package in "${BREW_CASK_PACKAGES[@]}"; do
  if ! brew list --cask | grep -q "^$package\$"; then
    brew install --cask $package
  fi
done

echo "Tapping into homebrew/cask-fonts..."
brew tap homebrew/cask-fonts

# Install Brew packages
echo "Installing brew packages..."
for package in "${BREW_PACKAGES[@]}"; do
  if ! brew list | grep -q "^$package\$"; then
    brew install $package
  fi
done

echo "Installing font-hack-nerd-font..."
if ! brew list | grep -q "^font-hack-nerd-font\$"; then
  brew install font-hack-nerd-font
fi

# Check for Oh My Zsh, install if we don't have it
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zsh-autosuggestions & zsh-syntax-highlighting
ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
if [ ! -d "${ZSH_CUSTOM_PLUGINS}/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM_PLUGINS}/zsh-autosuggestions
fi
if [ ! -d "${ZSH_CUSTOM_PLUGINS}/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM_PLUGINS}/zsh-syntax-highlighting
fi

echo "Script execution finished!"

