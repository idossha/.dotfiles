
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# ============================
# Variables and Configuration
# ============================

# Directory where the dotfiles are located
DOTFILES_DIR="$HOME/.dotfiles"

# Home directory
HOME_DIR="$HOME"

# Define common and OS-specific packages
COMMON_PACKAGES=("bash" "zsh" "nvim" "tmux" "vscode")
MACOS_PACKAGES=("iterm2")
LINUX_PACKAGES=()  # Add any Linux-specific packages if needed

# Define Homebrew Cask and Brew packages
BREW_CASK_PACKAGES=(
  #iterm2            # macOS only (Commented out as per install.sh)
  rectangle         # macOS only
  keyboardcleantool # macOS only
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
# Function Definitions
# ============================

# Function to unstow dotfiles
unstow_dotfiles() {
  print_message "Unstowing Dotfiles..."

  if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory $DOTFILES_DIR does not exist. Skipping unstowing."
    return
  fi

  cd "$DOTFILES_DIR"

  # Unstow common packages
  for pkg in "${COMMON_PACKAGES[@]}"; do
    echo "Unstowing $pkg..."
    if stow -D "$pkg"; then
      echo "Unstowed $pkg successfully."
    else
      echo "Failed to unstow $pkg or it was not stowed."
    fi
  done

  # Unstow OS-specific packages
  if $is_mac; then
    for pkg in "${MACOS_PACKAGES[@]}"; do
      echo "Unstowing $pkg..."
      if stow -D "$pkg"; then
        echo "Unstowed $pkg successfully."
      else
        echo "Failed to unstow $pkg or it was not stowed."
      fi
    done
  elif $is_linux; then
    for pkg in "${LINUX_PACKAGES[@]}"; do
      echo "Unstowing $pkg..."
      if stow -D "$pkg"; then
        echo "Unstowed $pkg successfully."
      else
        echo "Failed to unstow $pkg or it was not stowed."
      fi
    done
  fi

  cd -

  echo "Dotfiles have been unstowed successfully."
}

# Function to uninstall Homebrew packages
uninstall_brew_packages() {
  print_message "Uninstalling Homebrew packages..."

  for package in "${BREW_PACKAGES[@]}"; do
    if brew list | grep -q "^$package\$"; then
      echo "Uninstalling $package..."
      brew uninstall "$package"
    else
      echo "$package is not installed via Homebrew. Skipping."
    fi
  done
}

# Function to uninstall Homebrew Cask packages (macOS only)
uninstall_brew_cask_packages() {
  if $is_mac; then
    print_message "Uninstalling Homebrew Cask packages..."

    for package in "${BREW_CASK_PACKAGES[@]}"; do
      if brew list --cask | grep -q "^$package\$"; then
        echo "Uninstalling $package..."
        brew uninstall --cask "$package"
      else
        echo "$package is not installed via Homebrew Cask. Skipping."
      fi
    done
  fi
}

# Function to uninstall font-hack-nerd-font
uninstall_font_hack() {
  print_message "Uninstalling font-hack-nerd-font..."

  if $is_mac; then
    if brew list --cask | grep -q "^font-hack-nerd-font\$"; then
      brew uninstall --cask font-hack-nerd-font
    else
      echo "font-hack-nerd-font is not installed via Homebrew Cask. Skipping."
    fi
  elif $is_linux; then
    # Assuming installed via Homebrew Cask
    if brew list --cask | grep -q "^font-hack-nerd-font\$"; then
      brew uninstall --cask font-hack-nerd-font
    else
      echo "font-hack-nerd-font is not installed via Homebrew Cask. Skipping."
    fi
  fi
}

# Function to uninstall Oh My Zsh
uninstall_oh_my_zsh() {
  print_message "Uninstalling Oh My Zsh..."

  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Removing Oh My Zsh directory..."
    rm -rf "$HOME/.oh-my-zsh"

    # Restore original .zshrc if a backup exists
    if [ -f "$HOME/.zshrc.bak" ]; then
      echo "Restoring original .zshrc from backup..."
      mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
    else
      # If no backup, remove Oh My Zsh references from .zshrc
      echo "Removing Oh My Zsh lines from .zshrc..."
      sed -i.bak '/^export ZSH=/d' "$HOME/.zshrc"
      sed -i.bak '/^ZSH_THEME=/d' "$HOME/.zshrc"
      sed -i.bak '/^plugins=/d' "$HOME/.zshrc"
      sed -i.bak '/^source \$ZSH\/oh-my-zsh.sh/d' "$HOME/.zshrc"
      echo "Oh My Zsh lines removed from .zshrc."
    fi
  else
    echo "Oh My Zsh is not installed. Skipping."
  fi
}

# Function to remove Zsh plugins
remove_zsh_plugins() {
  print_message "Removing Zsh plugins..."

  ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"

  # Define Zsh plugins to remove
  ZSH_PLUGINS=(
    zsh-autosuggestions
    zsh-syntax-highlighting
  )

  for plugin in "${ZSH_PLUGINS[@]}"; do
    if [ -d "${ZSH_CUSTOM_PLUGINS}/$plugin" ]; then
      echo "Removing $plugin..."
      rm -rf "${ZSH_CUSTOM_PLUGINS}/$plugin"
    else
      echo "$plugin is not installed. Skipping."
    fi
  done
}

# Function to uninstall Neovim plugins
uninstall_neovim_plugins() {
  print_message "Uninstalling Neovim plugins..."

  if command -v nvim &> /dev/null; then
    # Remove vim-plug
    if [ -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]; then
      echo "Removing vim-plug..."
      rm "$HOME/.local/share/nvim/site/autoload/plug.vim"
    fi

    # Remove Neovim plugins directory
    if [ -d "$HOME/.local/share/nvim/plugged" ]; then
      echo "Removing Neovim plugins..."
      rm -rf "$HOME/.local/share/nvim/plugged"
    fi

    echo "Neovim plugins uninstalled successfully."
  else
    echo "Neovim is not installed. Skipping Neovim plugin uninstallation."
  fi
}

# Function to uninstall Tmux plugins
uninstall_tmux_plugins() {
  print_message "Uninstalling Tmux plugins..."

  # Assuming tpm is already in tmux/tmux_plugins/tpm and stowed to ~/.tmux_plugins/tpm
  TPM_DIR="$HOME/.tmux_plugins/tpm"

  if [ -d "$TPM_DIR" ]; then
    echo "Removing Tmux Plugin Manager (TPM)..."
    rm -rf "$TPM_DIR"
  else
    echo "Tmux Plugin Manager (TPM) is not installed. Skipping."
  fi

  # Optionally, remove the tmux plugins directories
  if [ -d "$HOME/.tmux_plugins" ]; then
    echo "Removing Tmux plugins directory..."
    rm -rf "$HOME/.tmux_plugins"
  fi
}

# Function to remove dotfiles repository
remove_dotfiles_repo() {
  print_message "Removing Dotfiles repository..."

  if [ -d "$DOTFILES_DIR" ]; then
    echo "Removing $DOTFILES_DIR..."
    rm -rf "$DOTFILES_DIR"
    echo "Dotfiles repository removed."
  else
    echo "Dotfiles repository does not exist. Skipping."
  fi
}

# Function to optionally uninstall Homebrew
uninstall_homebrew() {
  print_message "Do you want to uninstall Homebrew? [y/N]"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Uninstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    echo "Homebrew uninstalled."
  else
    echo "Skipping Homebrew uninstallation."
  fi
}

# ============================
# Main Uninstallation Flow
# ============================

main() {
  # Unstow dotfiles
  unstow_dotfiles

  # Uninstall Homebrew Cask packages
  uninstall_brew_cask_packages

  # Uninstall Homebrew packages
  uninstall_brew_packages

  # Uninstall font-hack-nerd-font
  uninstall_font_hack

  # Uninstall Oh My Zsh
  uninstall_oh_my_zsh

  # Remove Zsh plugins
  remove_zsh_plugins

  # Uninstall Neovim plugins
  uninstall_neovim_plugins

  # Uninstall Tmux plugins
  uninstall_tmux_plugins

  # Remove dotfiles repository
  remove_dotfiles_repo

  # Optionally uninstall Homebrew
  uninstall_homebrew

  print_message "Uninstallation Completed!"
  echo "Your development environment has been successfully uninstalled."
}

# Execute the main function
main
