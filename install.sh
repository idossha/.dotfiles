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
  #iterm2            # macOS only
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
# Homebrew Installation
# ============================

install_homebrew() {
  print_message "Checking for Homebrew..."

  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if $is_mac; then
      # For Apple Silicon Macs
      if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        # For Intel Macs
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    elif $is_linux; then
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  else
    echo "Homebrew is already installed."
  fi

  # Update Homebrew
  print_message "Updating Homebrew..."
  brew update
}

# ============================
# Install GNU Stow
# ============================

install_stow() {
  print_message "Checking for GNU Stow..."

  if ! command -v stow &> /dev/null; then
    echo "GNU Stow not found. Installing GNU Stow..."
    brew install stow
  else
    echo "GNU Stow is already installed."
  fi
}

# ============================
# Stow Dotfiles
# ============================

stow_dotfiles() {
  print_message "Stowing Dotfiles..."

  cd "$DOTFILES_DIR"

  # Stow common packages
  for pkg in "${COMMON_PACKAGES[@]}"; do
    echo "Stowing $pkg..."
    stow "$pkg"
  done

  # Stow OS-specific packages
  if $is_mac; then
    for pkg in "${MACOS_PACKAGES[@]}"; do
      echo "Stowing $pkg..."
      stow "$pkg"
    done
  elif $is_linux; then
    for pkg in "${LINUX_PACKAGES[@]}"; do
      echo "Stowing $pkg..."
      stow "$pkg"
    done
  fi

  echo "Dotfiles have been symlinked successfully."

  cd -
}

# ============================
# Install Homebrew Cask Packages (macOS only)
# ============================

install_brew_cask_packages() {
  if $is_mac; then
    print_message "Installing Homebrew Cask packages..."

    for package in "${BREW_CASK_PACKAGES[@]}"; do
      if ! brew list --cask | grep -q "^$package\$"; then
        echo "Installing $package..."
        brew install --cask "$package"
      else
        echo "$package is already installed."
      fi
    done
  fi
}

# ============================
# Install Homebrew Packages
# ============================

install_brew_packages() {
  print_message "Installing Homebrew packages..."

  for package in "${BREW_PACKAGES[@]}"; do
    if ! brew list | grep -q "^$package\$"; then
      echo "Installing $package..."
      brew install "$package"
    else
      echo "$package is already installed."
    fi
  done
}

# ============================
# Install font-hack-nerd-font
# ============================

install_font_hack() {
  print_message "Installing font-hack-nerd-font..."

  if $is_mac; then
    if ! brew list --cask | grep -q "^font-hack-nerd-font\$"; then
      brew install --cask font-hack-nerd-font
    else
      echo "font-hack-nerd-font is already installed."
    fi
  elif $is_linux; then
    if ! fc-list | grep -i "Hack Nerd Font" &> /dev/null; then
      brew install --cask font-hack-nerd-font
    else
      echo "font-hack-nerd-font is already installed."
    fi
  fi
}

# ============================
# Install Oh My Zsh
# ============================

install_oh_my_zsh() {
  print_message "Setting Up Oh My Zsh..."

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh not found. Installing Oh My Zsh..."
    # Install Oh My Zsh without changing the default shell or starting a new shell
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "Oh My Zsh is already installed."
  fi
}

# ============================
# Install Zsh Plugins
# ============================

install_zsh_plugins() {
  print_message "Installing Zsh plugins..."

  ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"

  # Ensure the custom/plugins directory exists
  mkdir -p "$ZSH_CUSTOM_PLUGINS"

  # Define Zsh plugins
  ZSH_PLUGINS=(
    zsh-autosuggestions
    zsh-syntax-highlighting
  )

  # Clone each plugin if not present
  for plugin in "${ZSH_PLUGINS[@]}"; do
    if [ ! -d "${ZSH_CUSTOM_PLUGINS}/$plugin" ]; then
      echo "Cloning $plugin..."
      git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM_PLUGINS}/$plugin"
    else
      echo "$plugin is already installed."
    fi
  done
}

# ============================
# Install Neovim Plugins
# ============================

install_neovim_plugins() {
  print_message "Installing Neovim plugins..."

  if command -v nvim &> /dev/null; then
    # Assuming vim-plug is used
    if [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]; then
      echo "Installing vim-plug for Neovim..."
      curl -fLo "$HOME/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    echo "Running Neovim plugin installation..."
    nvim --headless +PlugInstall +qall || true
    echo "Neovim plugins installed successfully."
  else
    echo "Neovim is not installed. Skipping Neovim plugin installation."
  fi
}

# ============================
# Install Tmux Plugins
# ============================

install_tmux_plugins() {
  print_message "Installing Tmux plugins..."

  # Assuming tpm is already in tmux/tmux_plugins/tpm and stowed to ~/.tmux_plugins/tpm

  TPM_DIR="$HOME/.tmux_plugins/tpm"

  if [ -d "$TPM_DIR" ]; then
    echo "Installing Tmux plugins using TPM..."
    # Reload tmux environment and install plugins
    tmux new-session -d "tmux source ~/.tmux.conf; $TPM_DIR/bin/install_plugins"
    echo "Tmux plugins installed successfully."
  else
    echo "Tmux Plugin Manager (TPM) not found. Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "Tmux Plugin Manager cloned. Installing plugins..."
    tmux new-session -d "tmux source ~/.tmux.conf; $TPM_DIR/bin/install_plugins"
    echo "Tmux plugins installed successfully."
  fi
}

# ============================
# Main Installation Flow
# ============================

main() {
  install_homebrew
  install_stow
  stow_dotfiles
  install_brew_cask_packages
  install_brew_packages
  install_font_hack
  install_oh_my_zsh
  install_zsh_plugins
  install_neovim_plugins
  install_tmux_plugins

  print_message "Installation Completed!"
  echo "Your development environment is set up successfully."
}

# Execute the main function
main


