
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# ============================
# Variables and Configuration
# ============================

# Directory where the dotfiles are located
DOTFILES_DIR="$HOME/.dotfiles"

# Home directory
HOME_DIR="$HOME"

# Oh My Zsh installation directory
OH_MY_ZSH_DIR="$HOME/oh-my-zsh"

# Define common and OS-specific packages
COMMON_PACKAGES=("bash" "zsh" "nvim" "tmux" "vscode" "kitty")

# Define Homebrew Cask and Brew packages
BREW_CASK_PACKAGES=(
  rectangle
  keyboardcleantool
  kitty
  font-hack-nerd-font  # Include the font for uninstallation
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
  htop
  lazygit
  lazydocker
  stow  # Include stow in the list to uninstall it as well
)

# Function to print messages with separators for better readability
print_message() {
  echo "========================================"
  echo "$1"
  echo "========================================"
}

# ============================
# OS Detection
# ============================

OS="$(uname)"
is_mac=false
is_linux=false

if [ "$OS" == "Darwin" ]; then
  is_mac=true
elif [ "$OS" == "Linux" ]; then
  is_linux=true
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# ============================
# Unstow Dotfiles
# ============================

unstow_dotfiles() {
  print_message "Unstowing Dotfiles..."
  sleep 1
  cd "$DOTFILES_DIR"

  # Unstow common packages
  for pkg in "${COMMON_PACKAGES[@]}"; do
    echo "Unstowing $pkg..."
    stow -D --ignore='\.DS_Store' "$pkg"
  done

  echo "Dotfiles have been unstowed successfully."

  cd -
}

# ============================
# Restore Backup Config Files
# ============================

restore_backup_configs() {
  print_message "Restoring Backup Config Files..."
  sleep 1
  # List of config files to check
  CONFIG_FILES=(
    ".zshrc"
    ".bashrc"
    ".tmux.conf"
    ".zprofile"
    ".config/kitty/kitty.conf"
  )

  for config in "${CONFIG_FILES[@]}"; do
    target="$HOME/$config"
    backup="$HOME/${config}.backup"
    if [ -f "$backup" ]; then
      echo "Restoring backup for $config"
      mv "$backup" "$target"
    else
      echo "No backup found for $config"
    fi
  done
}

# ============================
# Uninstall Homebrew Cask Packages (macOS only)
# ============================

uninstall_brew_cask_packages() {
  if $is_mac; then
    print_message "Uninstalling Homebrew Cask packages..."
    sleep 1
    for package in "${BREW_CASK_PACKAGES[@]}"; do
      if brew list --cask | grep -q "^$package\$"; then
        echo "Uninstalling $package..."
        brew uninstall --cask "$package"
      else
        echo "$package is not installed."
      fi
    done
  fi
}

# ============================
# Uninstall Homebrew Packages
# ============================

uninstall_brew_packages() {
  print_message "Uninstalling Homebrew packages..."
  sleep 1
  for package in "${BREW_PACKAGES[@]}"; do
    if brew list | grep -q "^$package\$"; then
      echo "Uninstalling $package..."
      brew uninstall "$package"
    else
      echo "$package is not installed."
    fi
  done
}

# ============================
# Remove Oh My Zsh and Zsh Plugins
# ============================

remove_oh_my_zsh() {
  print_message "Removing Oh My Zsh..."
  sleep 1
  if [ -d "$OH_MY_ZSH_DIR" ]; then
    echo "Removing Oh My Zsh directory..."
    rm -rf "$OH_MY_ZSH_DIR"
  else
    echo "Oh My Zsh is not installed."
  fi
}

# ============================
# Remove Neovim Plugins and Configuration
# ============================

remove_neovim_plugins() {
  print_message "Removing Neovim plugins and configuration..."
  sleep 1
  NEOVIM_DATA_DIR="$HOME/.local/share/nvim"
  NEOVIM_CONFIG_DIR="$HOME/.config/nvim"

  if [ -d "$NEOVIM_DATA_DIR" ]; then
    echo "Removing Neovim data directory..."
    rm -rf "$NEOVIM_DATA_DIR"
  else
    echo "Neovim data directory does not exist."
  fi

  if [ -d "$NEOVIM_CONFIG_DIR" ]; then
    echo "Removing Neovim configuration directory..."
    rm -rf "$NEOVIM_CONFIG_DIR"
  else
    echo "Neovim configuration directory does not exist."
  fi
}

# ============================
# Remove Tmux Plugins
# ============================

remove_tmux_plugins() {
  print_message "Removing Tmux plugins..."
  sleep 1
  TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"

  if [ -d "$TMUX_PLUGIN_DIR" ]; then
    echo "Removing Tmux plugins directory..."
    rm -rf "$TMUX_PLUGIN_DIR"
  else
    echo "Tmux plugins directory does not exist."
  fi
}

# ============================
# Uninstall Homebrew (Optional)
# ============================

uninstall_homebrew() {
  print_message "Uninstalling Homebrew (Optional)..."
  sleep 1
  if command -v brew &> /dev/null; then
    echo "Uninstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
  else
    echo "Homebrew is not installed."
  fi
}

# ============================
# Main Uninstallation Flow
# ============================

main() {
  unstow_dotfiles
  restore_backup_configs
  uninstall_brew_cask_packages
  uninstall_brew_packages
  remove_oh_my_zsh
  remove_neovim_plugins
  remove_tmux_plugins
  #uninstall_homebrew  # Uncomment this line if you want to uninstall Homebrew

  print_message "Uninstallation Completed!"
  echo "Your development environment has been cleaned up."
}

# Execute the main function
main

