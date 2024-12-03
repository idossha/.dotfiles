
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
MACOS_PACKAGES=()
LINUX_PACKAGES=()  # Add any Linux-specific packages if needed

# Define Homebrew Cask and Brew packages
BREW_CASK_PACKAGES=(
  rectangle         # macOS only
  keyboardcleantool # macOS only
  kitty             # Kitty terminal emulator
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
  sleep 1
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
  sleep 1
  if ! command -v stow &> /dev/null; then
    echo "GNU Stow not found. Installing GNU Stow..."
    brew install stow
  else
    echo "GNU Stow is already installed."
  fi
}

# ============================
# Backup Existing Config Files
# ============================

backup_existing_configs() {
  print_message "Backing Up Existing Config Files..."
  sleep 1
  # List of config files to check
  CONFIG_FILES=(
    ".zshrc"
    ".bashrc"
    ".tmux.conf"
    ".zprofile"
    ".bash_profile"
    ".config/kitty/kitty.conf"
  )

  for config in "${CONFIG_FILES[@]}"; do
    target="$HOME/$config"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "Backing up $target to $target.backup"
      mv "$target" "$target.backup"
    fi
  done
}

# ============================
# Stow Dotfiles
# ============================

stow_dotfiles() {
  print_message "Stowing Dotfiles..."
  sleep 1
  cd "$DOTFILES_DIR"

  # Stow common packages
  for pkg in "${COMMON_PACKAGES[@]}"; do
    echo "Stowing $pkg..."
    stow --ignore='\.DS_Store' "$pkg"
  done

  echo "Dotfiles have been symlinked successfully."

  cd -
}

# ============================
# Install Homebrew Cask Packages (macOS only)
# ============================

install_brew_cask_packages() {
  if $is_mac; then
    print_message "Installing Homebrew Cask packages..."
    sleep 1
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
  sleep 1
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
  sleep 1
  if $is_mac; then
    if ! brew list --cask | grep -q "^font-hack-nerd-font\$"; then
      brew tap homebrew/cask-fonts
      brew install --cask font-hack-nerd-font
    else
      echo "font-hack-nerd-font is already installed."
    fi
  elif $is_linux; then
    if ! fc-list | grep -i "Hack Nerd Font" &> /dev/null; then
      # Install font manually or via package manager
      echo "Installing Hack Nerd Font..."
      mkdir -p ~/.local/share/fonts
      cd ~/.local/share/fonts && curl -fLo "Hack Regular Nerd Font Complete.ttf" \
        https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete.ttf
      fc-cache -fv
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
  sleep 1
  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "Oh My Zsh not found. Installing Oh My Zsh..."

    # Set ZSH environment variable to install to $HOME/oh-my-zsh
    export ZSH="$OH_MY_ZSH_DIR"

    # Install Oh My Zsh without modifying .zshrc
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "Oh My Zsh is already installed."
  fi
}

# ============================
# Install Zsh Plugins
# ============================

install_zsh_plugins() {
  print_message "Installing Zsh plugins..."
  sleep 1
  ZSH_CUSTOM_PLUGINS="$OH_MY_ZSH_DIR/custom/plugins"

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
  print_message "Installing Neovim plugins with lazy.nvim..."
  sleep 1
  if command -v nvim &> /dev/null; then
    # Install lazy.nvim if not already installed
    LAZY_NVIM_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
    if [ ! -d "$LAZY_NVIM_DIR" ]; then
      echo "Installing lazy.nvim plugin manager..."
      git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZY_NVIM_DIR"
    else
      echo "lazy.nvim is already installed."
    fi

    echo "Running Neovim to install plugins via lazy.nvim..."
    nvim --headless "+Lazy! sync" +qa

    echo "Neovim plugins installed successfully using lazy.nvim."
  else
    echo "Neovim is not installed. Skipping Neovim plugin installation."
  fi
}

# ============================
# Install Tmux Plugins
# ============================

install_tmux_plugins() {
  print_message "Installing Tmux plugins..."
  sleep 1
  TPM_DIR="$HOME/.tmux/plugins/tpm"

  if [ ! -d "$TPM_DIR" ]; then
    echo "Tmux Plugin Manager (TPM) not found. Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  else
    echo "Tmux Plugin Manager is already installed."
  fi

  # Install Tmux plugins
  if command -v tmux &> /dev/null; then
    echo "Installing Tmux plugins..."

    # Start a new detached tmux session that runs the necessary commands
    tmux new-session -d -s plugin_install_session \
      "tmux source-file ~/.tmux.conf; ~/.tmux/plugins/tpm/scripts/install_plugins.sh; sleep 5"

    # Wait for the session to complete
    sleep 15  # Adjust this if needed

    # Kill the temporary session
    tmux kill-session -t plugin_install_session

    echo "Tmux plugins installed successfully."
  else
    echo "Tmux is not installed. Skipping Tmux plugin installation."
  fi
}

# ============================
# Source .zshrc
# ============================

source_zshrc() {
  print_message "Sourcing .zshrc..."
  sleep 1
  # Source .zshrc if Zsh is the current shell
  if [ -n "$ZSH_VERSION" ]; then
    echo "Sourcing $HOME/.zshrc"
    source "$HOME/.zshrc"
    echo ".zshrc has been sourced."
  else
    echo "Current shell is not Zsh. Please restart your terminal or run 'source ~/.zshrc' manually."
  fi
}

# ============================
# Main Installation Flow
# ============================

main() {
  install_homebrew
  install_stow
  backup_existing_configs
  stow_dotfiles
  install_brew_cask_packages
  install_brew_packages
  install_font_hack
  install_oh_my_zsh
  install_zsh_plugins
  install_neovim_plugins
  install_tmux_plugins
  source_zshrc

  print_message "Installation Completed!"
  echo "Your development environment is set up successfully."
}

# Execute the main function
main

