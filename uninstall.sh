
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

# Define common and OS-specific packages (matching install.sh)
COMMON_CONFS=("bash" "nvim" "tmux" "vscode" "github" "neofetch" "htop" "ghostty" "nushell" "misc" "karabiner")
MACOS_CONFS=("zsh" "aerospace")
LINUX_CONFS=("linux-bash")

# Define packages matching install.sh structure
COMMON_BREW_PACKAGES=(
  tmux
  git
  ripgrep
  fzf
  tree-sitter
  zoxide
  bat
  direnv
  htop
  lazygit
  lazydocker
  neofetch
  node
  jq
  pandoc
  ffmpeg
  nushell
  imagemagick
  fd
  stow
)

BREW_CASK_PACKAGES=(
  keyboardcleantool
  ghostty
  font-hack-nerd-font
)

MACOS_BREW_PACKAGES=(
  nikitabobko/tap/aerospace
  stats
)

LINUX_APT_PACKAGES=(
  tmux
  git
  bat
  zoxide
  ripgrep
  nodejs
  npm
  jq
  direnv
  tree
  pandoc
  ffmpeg
  htop
  fzf
  zsh
  neofetch
  ghostty
  fd
)

# Function to print messages with separators for better readability
print_message() {
  echo "========================================"
  echo "$1"
  echo "========================================"
}

# Function for user confirmation
confirm() {
  read -p "$1 (y/n) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
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
  for pkg in "${COMMON_CONFS[@]}"; do
    if [ -d "$pkg" ]; then
      echo "Unstowing $pkg..."
      stow -D --ignore='\.DS_Store' "$pkg" 2>/dev/null || echo "Warning: Failed to unstow $pkg"
    fi
  done

  # Unstow OS-specific packages
  if $is_mac; then
    for pkg in "${MACOS_CONFS[@]}"; do
      if [ -d "$pkg" ]; then
        echo "Unstowing $pkg..."
        stow -D --ignore='\.DS_Store' "$pkg" 2>/dev/null || echo "Warning: Failed to unstow $pkg"
      fi
    done
  elif $is_linux; then
    for pkg in "${LINUX_CONFS[@]}"; do
      if [ -d "$pkg" ]; then
        echo "Unstowing $pkg..."
        stow -D "$pkg" 2>/dev/null || echo "Warning: Failed to unstow $pkg"
      fi
    done
  fi

  echo "Dotfiles have been unstowed successfully."

  cd - >/dev/null
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
      # Skip commented packages
      if [[ $package == \#* ]]; then
        continue
      fi
      if brew list --cask | grep -q "^$package\$"; then
        echo "Uninstalling $package..."
        brew uninstall --cask "$package" 2>/dev/null || echo "Warning: Failed to uninstall $package"
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
  if $is_mac || $is_linux; then
    print_message "Uninstalling Homebrew packages..."
    sleep 1

    # Uninstall common packages
    for package in "${COMMON_BREW_PACKAGES[@]}"; do
      # Skip commented packages
      if [[ $package == \#* ]]; then
        continue
      fi
      if brew list | grep -q "^$package\$"; then
        echo "Uninstalling $package..."
        brew uninstall "$package" 2>/dev/null || echo "Warning: Failed to uninstall $package"
      else
        echo "$package is not installed."
      fi
    done

    # Uninstall macOS-specific packages
    if $is_mac; then
      for package in "${MACOS_BREW_PACKAGES[@]}"; do
        # Skip commented packages
        if [[ $package == \#* ]]; then
          continue
        fi
        if brew list | grep -q "^$package\$"; then
          echo "Uninstalling $package..."
          brew uninstall "$package" 2>/dev/null || echo "Warning: Failed to uninstall $package"
        else
          echo "$package is not installed."
        fi
      done
    fi
  fi
}

# ============================
# Uninstall APT Packages
# ============================

uninstall_apt_packages() {
  if $is_linux; then
    print_message "Uninstalling APT packages..."
    sleep 1
    for package in "${LINUX_APT_PACKAGES[@]}"; do
      if dpkg -l | grep -q "^ii  $package "; then
        echo "Uninstalling $package..."
        sudo apt remove -y "$package" 2>/dev/null || echo "Warning: Failed to uninstall $package"
      else
        echo "$package is not installed."
      fi
    done
  fi
}

# ============================
# Remove Custom Neovim Installation
# ============================

remove_custom_neovim() {
  print_message "Removing custom Neovim installation..."
  sleep 1
  NEOVIM_LOCAL_DIR="$HOME/.local"
  NEOVIM_BIN_DIR="$HOME/.local/bin"
  NEOVIM_SHARE_DIR="$HOME/.local/share/nvim"

  # Remove Neovim binary and related files
  if [ -f "$NEOVIM_BIN_DIR/nvim" ]; then
    echo "Removing custom Neovim binary..."
    rm -f "$NEOVIM_BIN_DIR/nvim"
  fi

  if [ -d "$NEOVIM_SHARE_DIR" ]; then
    echo "Removing Neovim share directory..."
    rm -rf "$NEOVIM_SHARE_DIR"
  fi

  # Remove Neovim lib directory if it exists
  if [ -d "$NEOVIM_LOCAL_DIR/lib/nvim" ]; then
    echo "Removing Neovim lib directory..."
    rm -rf "$NEOVIM_LOCAL_DIR/lib/nvim"
  fi

  # Clean up empty directories
  if [ -d "$NEOVIM_BIN_DIR" ] && [ -z "$(ls -A $NEOVIM_BIN_DIR)" ]; then
    rmdir "$NEOVIM_BIN_DIR" 2>/dev/null || true
  fi
  if [ -d "$NEOVIM_LOCAL_DIR" ] && [ -z "$(ls -A $NEOVIM_LOCAL_DIR)" ]; then
    rmdir "$NEOVIM_LOCAL_DIR" 2>/dev/null || true
  fi
}

# ============================
# Remove Atuin
# ============================

remove_atuin() {
  print_message "Removing Atuin..."
  sleep 1
  # Atuin installs itself to ~/.atuin and adds to PATH
  if [ -d "$HOME/.atuin" ]; then
    echo "Removing Atuin directory..."
    rm -rf "$HOME/.atuin"
  fi

  # Remove Atuin binary if it exists
  if command -v atuin &>/dev/null; then
    ATUIN_PATH=$(which atuin)
    if [[ $ATUIN_PATH == *"$HOME"* ]]; then
      echo "Removing Atuin binary..."
      rm -f "$ATUIN_PATH"
    fi
  fi
}

# ============================
# Remove Zsh Plugins
# ============================

remove_zsh_plugins() {
  print_message "Removing Zsh plugins..."
  sleep 1
  ZSH_CUSTOM_PLUGINS="$OH_MY_ZSH_DIR/custom/plugins"

  # Remove specific plugins installed by the script
  PLUGINS_TO_REMOVE=("zsh-autosuggestions" "zsh-syntax-highlighting")
  for plugin in "${PLUGINS_TO_REMOVE[@]}"; do
    if [ -d "${ZSH_CUSTOM_PLUGINS}/$plugin" ]; then
      echo "Removing $plugin..."
      rm -rf "${ZSH_CUSTOM_PLUGINS}/$plugin"
    fi
  done

  # Clean up empty plugins directory
  if [ -d "$ZSH_CUSTOM_PLUGINS" ] && [ -z "$(ls -A $ZSH_CUSTOM_PLUGINS)" ]; then
    rmdir "$ZSH_CUSTOM_PLUGINS" 2>/dev/null || true
  fi
}

# ============================
# Remove Fonts
# ============================

remove_fonts() {
  print_message "Removing custom fonts..."
  sleep 1
  FONTS_DIR="$HOME/.local/share/fonts"

  if [ -d "$FONTS_DIR" ]; then
    echo "Removing fonts directory..."
    rm -rf "$FONTS_DIR"
  fi

  # Update font cache if fc-cache exists
  if command -v fc-cache &>/dev/null; then
    echo "Updating font cache..."
    fc-cache -f 2>/dev/null || true
  fi
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
  # Ask for confirmation
  echo "This script will uninstall all components installed by the dotfiles setup."
  echo "This includes removing packages, configurations, and custom installations."
  if ! confirm "Are you sure you want to continue with the uninstallation?"; then
    echo "Uninstallation cancelled."
    exit 0
  fi

  unstow_dotfiles
  restore_backup_configs

  # Remove custom installations first
  remove_custom_neovim
  remove_atuin
  remove_fonts
  remove_zsh_plugins

  # Remove packages
  if $is_mac; then
    uninstall_brew_cask_packages
  fi
  uninstall_brew_packages
  if $is_linux; then
    uninstall_apt_packages
  fi

  # Remove framework/tool installations
  remove_oh_my_zsh
  remove_neovim_plugins
  remove_tmux_plugins

  # Optional: uninstall Homebrew (commented out by default)
  #uninstall_homebrew

  print_message "Uninstallation Completed!"
  echo "Your development environment has been cleaned up."
  echo "Note: You may need to restart your shell or terminal for all changes to take effect."
}

# Execute the main function
main

