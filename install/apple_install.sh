#!/bin/bash

########################################
# dotfiles macOS installation script of Ido Haber
# Last update: January 12, 2026
########################################

# Exit on error with better error handling
set -euo pipefail

# ============================
# Get Script Directory
# ============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================
# OS Detection (macOS only)
# ============================
OS="$(uname)"
if [ "$OS" != "Darwin" ]; then
  echo "ERROR: This script is for macOS only. For Linux, use linux_install.sh"
  exit 1
fi

# ============================
# Logging Configuration
# ============================
LOG_FILE="$SCRIPT_DIR/dotfiles_apple_install.log"
INSTALL_MANIFEST="$SCRIPT_DIR/install_manifest_apple.txt"

# Ensure log file directory exists and create log file
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
: > "$INSTALL_MANIFEST"  # Clear manifest file

# Redirect all output to both terminal and log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========== macOS Installation started at $(date) =========="
echo "OS: $OS"
echo "Log file: $LOG_FILE"
echo "Install manifest: $INSTALL_MANIFEST"

# ============================
# Cleanup and Error Handler
# ============================
TEMP_FILES=()
INSTALLED_PACKAGES=()
BACKED_UP_FILES=()
CREATED_DIRS=()

# Function to record installation actions to manifest
record_action() {
  local action_type="$1"
  local item="$2"
  echo "$action_type:$item" >> "$INSTALL_MANIFEST"
}

cleanup() {
  echo "========== Cleanup triggered at $(date) =========="

  # Check if the script was successful or failed
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    echo "Error detected (code $exit_code). Performing cleanup..."

    # Restore backed up configs
    for file in "${BACKED_UP_FILES[@]}"; do
      if [ -f "${file}.backup" ]; then
        echo "Restoring backup: ${file}"
        mv "${file}.backup" "${file}"
      fi
    done

    # Remove installed packages (only if running interactively)
    if [ -t 0 ] && [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
      if confirm "Do you want to remove installed packages?"; then
        echo "Removing installed packages..."
        for pkg in "${INSTALLED_PACKAGES[@]}"; do
          brew uninstall "$pkg" 2>/dev/null || true
        done
      fi
    fi

    # Remove created directories (only if running interactively)
    if [ -t 0 ]; then
      for dir in "${CREATED_DIRS[@]}"; do
        if [ -d "$dir" ] && confirm "Remove directory: $dir?"; then
          echo "Removing directory: $dir"
          rm -rf "$dir"
        fi
      done
    fi

    # Clean up temp files (always do this)
    for file in "${TEMP_FILES[@]}"; do
      if [ -f "$file" ]; then
        echo "Removing temporary file: $file"
        rm -f "$file"
      fi
    done

    echo "Cleanup completed. Check $LOG_FILE for details."
    echo "Installation FAILED. Please check the log for errors."
    echo "To retry, fix the errors and run the script again."
  else
    echo "Installation SUCCEEDED."
    echo "A manifest of installed items has been saved to: $INSTALL_MANIFEST"
    echo "Use apple_uninstall.sh to safely remove what was installed."
  fi

  echo "========== Installation finished at $(date) =========="
}

trap cleanup EXIT

# ============================
# Helper Functions
# ============================

# Function to check prerequisites
check_prerequisites() {
  local missing_tools=()

  # Check for essential tools
  local required_tools=("git" "curl")

  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      missing_tools+=("$tool")
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_error "Missing required tools: ${missing_tools[*]}"
    echo "Please install these tools first:"
    echo "  xcode-select --install"
    exit 1
  fi

  echo "Prerequisites check passed."
}

# Function for user confirmation
confirm() {
  read -p "$1 (y/n) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to print messages with separators for better readability
print_message() {
  echo "========================================"
  echo "$1"
  echo "========================================"
}

# Function to print error messages
print_error() {
  echo "----------------------------------------"
  echo "ERROR: $1"
  echo "----------------------------------------"
}

# Function to track installed package
track_installed() {
  INSTALLED_PACKAGES+=("$1")
  record_action "PACKAGE" "$1"
  echo "Tracking installed package: $1" >> "$LOG_FILE"
}

# Function to track created directory
track_directory() {
  CREATED_DIRS+=("$1")
  record_action "DIRECTORY" "$1"
  echo "Tracking created directory: $1" >> "$LOG_FILE"
}

# Function to track backed up file
track_backup() {
  BACKED_UP_FILES+=("$1")
  record_action "BACKUP" "$1"
  echo "Tracking backed up file: $1" >> "$LOG_FILE"
}

# Function to handle stow conflicts
handle_stow_conflicts() {
  local package="$1"

  if [ "$package" = "github" ]; then
    # Handle .gitconfig merge
    if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
      echo "Merging existing .gitconfig with dotfiles version..."

      # Create backup with consistent timestamp
      local backup_timestamp=$(date +%Y%m%d_%H%M%S)
      local backup_file="$HOME/.gitconfig.backup.$backup_timestamp"
      cp "$HOME/.gitconfig" "$backup_file"
      track_backup "$HOME/.gitconfig"
      record_action "BACKUP_FILE" "$backup_file"

      # Read existing content
      local existing_content=""
      if [ -f "$HOME/.gitconfig" ]; then
        existing_content=$(cat "$HOME/.gitconfig")
      fi

      # Read dotfiles content
      local dotfiles_content=""
      if [ -f "$DOTFILES_DIR/github/.gitconfig" ]; then
        dotfiles_content=$(cat "$DOTFILES_DIR/github/.gitconfig")
      fi

      # Merge content (dotfiles version takes precedence for structure, but preserve existing user config)
      echo "$dotfiles_content" > "$HOME/.gitconfig"

      # Extract and preserve existing user config if different
      if echo "$existing_content" | grep -q "\[user\]"; then
        # Fix: Use xargs to trim whitespace properly without removing internal spaces
        local existing_name=$(echo "$existing_content" | grep -A 5 "\[user\]" | grep "name =" | sed 's/.*name = //' | xargs)
        local existing_email=$(echo "$existing_content" | grep -A 5 "\[user\]" | grep "email =" | sed 's/.*email = //' | xargs)
        if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
          # Use proper sed syntax for macOS
          sed -i '' "s/name = .*/name = $existing_name/" "$HOME/.gitconfig"
          sed -i '' "s/email = .*/email = $existing_email/" "$HOME/.gitconfig"
        fi
      fi

      # Preserve credential helper if it exists
      if echo "$existing_content" | grep -q "\[credential\]"; then
        local cred_helper=$(echo "$existing_content" | grep -A 5 "\[credential\]" | grep "helper =" | sed 's/.*helper = //' | xargs)
        if [ -n "$cred_helper" ] && ! grep -q "\[credential\]" "$HOME/.gitconfig"; then
          echo -e "\n[credential]\n\thelper = $cred_helper" >> "$HOME/.gitconfig"
        fi
      fi
    fi
  elif [ "$package" = "htop" ]; then
    # Handle htop config replacement
    if [ -f "$HOME/.config/htop/htoprc" ] && [ ! -L "$HOME/.config/htop/htoprc" ]; then
      echo "Backing up existing htop config..."
      local backup_timestamp=$(date +%Y%m%d_%H%M%S)
      local backup_file="$HOME/.config/htop/htoprc.backup.$backup_timestamp"
      cp "$HOME/.config/htop/htoprc" "$backup_file"
      track_backup "$HOME/.config/htop/htoprc"
      record_action "BACKUP_FILE" "$backup_file"
    fi
  fi
}

# ============================
# Variables and Configuration
# ============================

# Home directory
HOME_DIR="$HOME"

# Directory where the dotfiles are located (parent of script directory)
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Oh My Zsh installation directory
OH_MY_ZSH_DIR="$HOME/oh-my-zsh"

# Neovim version
NEOVIM_VERSION="0.11.0"

# Define packages to stow (all packages for macOS installation)
STOW_PACKAGES=("nvim" "tmux" "vscode" "github" "neofetch" "htop" "ghostty" "nushell" "misc" "karabiner" "zsh" "aerospace")

# Define Homebrew Cask packages
BREW_CASK_PACKAGES=(
  keyboardcleantool
  raycast
  cursor
  karabiner-elements
  docker
  zoom
  slack
  ghostty
  arc
  obs
)

# Define Homebrew packages (all packages for macOS installation)
BREW_PACKAGES=(
  tmux
  git
  gh
  ripgrep
  fzf
  tree-sitter
  zoxide
  bat
  direnv
  htop
  btop
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
  keycastr
  navi
  gromgit/brewtils/taproom # have not tested this yet
  nikitabobko/tap/aerospace
  stats
  ruby@3.3
  sqlite3
  postgresql
)

echo "Detected OS: $OS" >> "$LOG_FILE"

# ============================
# Package Manager Installation
# ============================

install_homebrew() {
  print_message "Checking for Homebrew..."
  sleep 1
  
  # Check if brew is in PATH
  if command -v brew &> /dev/null; then
    echo "Homebrew is already installed and in PATH."
  else
    # Check common Homebrew locations
    local brew_path=""
    if [[ $(uname -m) == 'arm64' ]] && [ -f "/opt/homebrew/bin/brew" ]; then
      brew_path="/opt/homebrew/bin/brew"
      echo "Found Homebrew at $brew_path, initializing..."
      eval "$($brew_path shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
      brew_path="/usr/local/bin/brew"
      echo "Found Homebrew at $brew_path, initializing..."
      eval "$($brew_path shellenv)"
    fi
    
    # Verify brew is now available
    if command -v brew &> /dev/null; then
      echo "Homebrew is now available."
    else
      # Homebrew not found, offer to install
      if confirm "Homebrew not found. Would you like to install it?"; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for current session
        # Note: Homebrew will be added to .zshrc by stow, not .zprofile
        # For Apple Silicon Macs
        if [[ $(uname -m) == 'arm64' ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        else
          # For Intel Macs
          eval "$(/usr/local/bin/brew shellenv)"
        fi
      else
        print_error "Homebrew is required but won't be installed. Exiting."
        exit 1
      fi
    fi
  fi

  # Update Homebrew
  print_message "Updating Homebrew..."
  brew update
}

# ============================
# GNU Stow Installation
# ============================

install_stow() {
  print_message "Checking for GNU Stow..."
  sleep 1
  if ! command -v stow &> /dev/null; then
    echo "GNU Stow not found. Installing GNU Stow..."
    if brew install stow; then
      track_installed "stow"
    else
      print_error "Failed to install GNU Stow"
      exit 1
    fi
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
  )

  for config in "${CONFIG_FILES[@]}"; do
    target="$HOME/$config"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      local backup_timestamp=$(date +%Y%m%d_%H%M%S)
      local backup_file="${target}.backup.$backup_timestamp"
      echo "Backing up $target to $backup_file"
      cp "$target" "$backup_file"
      track_backup "$target"
      record_action "BACKUP_FILE" "$backup_file"
    fi
  done
}

# ============================
# Stow Dotfiles
# ============================

stow_dotfiles() {
  print_message "Stowing Dotfiles..."
  sleep 1

  # Check if dotfiles directory exists
  if [ ! -d "$DOTFILES_DIR" ]; then
    print_error "Dotfiles directory not found at $DOTFILES_DIR"
    if confirm "Would you like to clone your dotfiles repository now?"; then
      echo "Enter your dotfiles repository URL:"
      read -r repo_url
      local parent_dir=$(dirname "$DOTFILES_DIR")
      mkdir -p "$parent_dir"
      if git clone "$repo_url" "$DOTFILES_DIR"; then
        track_directory "$DOTFILES_DIR"
        record_action "CLONED_REPO" "$DOTFILES_DIR"
      else
        print_error "Failed to clone repository. Exiting."
        exit 1
      fi
    else
      print_error "Dotfiles directory is required. Exiting."
      exit 1
    fi
  fi

  local original_dir="$PWD"
  cd "$DOTFILES_DIR"

  # Stow all packages
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
      echo "Stowing $pkg..."
      # Handle conflicts before stowing
      handle_stow_conflicts "$pkg"

      # Try to stow, and if it fails due to conflicts, try with --adopt
      if ! stow --ignore='\.DS_Store' "$pkg" 2>/dev/null; then
        echo "Retrying $pkg with --adopt..."
        if stow --ignore='\.DS_Store' --adopt "$pkg"; then
          record_action "STOW" "$pkg"
        else
          print_error "Failed to stow $pkg even with --adopt"
        fi
      else
        record_action "STOW" "$pkg"
      fi
    else
      echo "Warning: $pkg directory not found, skipping."
    fi
  done

  echo "Dotfiles have been symlinked successfully."

  cd "$original_dir"
}

# ============================
# Install Homebrew Cask Packages (macOS only)
# ============================

install_brew_cask_packages() {
  print_message "Installing Homebrew Cask packages..."
  sleep 1
  for package in "${BREW_CASK_PACKAGES[@]}"; do
    # Skip commented packages
    if [[ $package == \#* ]]; then
      continue
    fi
    if ! brew list --cask "$package" &>/dev/null; then
      echo "Installing $package..."
      if brew install --cask "$package"; then
        track_installed "$package"
      else
        print_error "Failed to install $package"
      fi
    else
      echo "$package is already installed."
    fi
  done
}

# ============================
# Install Homebrew Packages
# ============================

install_brew_packages() {
  print_message "Installing Homebrew packages..."
  sleep 1

  # Taps required for certain packages
  # Tap for aerospace
  if ! brew tap | grep -q "nikitabobko/tap"; then
    echo "Tapping nikitabobko/tap..."
    brew tap nikitabobko/tap
  fi

  # Install all packages
  for package in "${BREW_PACKAGES[@]}"; do
    # Skip commented packages
    if [[ $package == \#* ]]; then
      continue
    fi

    if ! brew list "$package" &>/dev/null; then
      echo "Installing $package..."
      if brew install "$package"; then
        track_installed "$package"
      else
        print_error "Failed to install $package"
      fi
    else
      echo "$package is already installed."
    fi
  done
}

# ============================
# Install Fonts
# ============================

install_font_hack() {
  print_message "Installing font-hack-nerd-font..."
  sleep 1
  if ! brew list --cask font-hack-nerd-font &>/dev/null; then
    # Fonts are now available directly from the main cask repository
    # No need to tap homebrew/cask-fonts (deprecated)
    if brew install --cask font-hack-nerd-font; then
      track_installed "font-hack-nerd-font"
    else
      print_error "Failed to install font-hack-nerd-font"
    fi
  else
    echo "font-hack-nerd-font is already installed."
  fi
}

# ============================
# Install Oh My Zsh
# ============================

install_oh_my_zsh() {
  print_message "Setting Up Oh My Zsh..."
  sleep 1
  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "Oh My Zsh not found."
    if confirm "Would you like to install Oh My Zsh?"; then
      # Set ZSH environment variable to install to $HOME/oh-my-zsh
      export ZSH="$OH_MY_ZSH_DIR"

      # Install Oh My Zsh without modifying .zshrc
      RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ""

      if [ -d "$OH_MY_ZSH_DIR" ]; then
        track_directory "$OH_MY_ZSH_DIR"
      else
        print_error "Failed to install Oh My Zsh"
      fi
    else
      echo "Skipping Oh My Zsh installation."
    fi
  else
    echo "Oh My Zsh is already installed."
  fi
}

# ============================
# Set Zsh as Default Shell
# ============================

set_zsh_as_default() {
  print_message "Checking shell configuration..."
  sleep 1

  # Check if zsh is installed
  if ! command -v zsh &> /dev/null; then
    print_error "Zsh is not installed. Please install it first."
    return 1
  fi

  # Check current shell
  if [[ "$SHELL" != *"zsh"* ]]; then
    if confirm "Your current shell is not Zsh. Would you like to set Zsh as your default shell?"; then
      echo "Setting Zsh as default shell..."
      ZSH_PATH=$(which zsh)

      # Check if zsh is in /etc/shells
      if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "Adding $ZSH_PATH to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
      fi

      # Change shell
      if chsh -s "$ZSH_PATH"; then
        echo "Shell changed to Zsh. Please log out and log back in for changes to take effect."
      else
        print_error "Failed to change shell to Zsh."
      fi
    else
      echo "Keeping current shell: $SHELL"
    fi
  else
    echo "Zsh is already your default shell."
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
  track_directory "$ZSH_CUSTOM_PLUGINS"

  # Define Zsh plugins
  ZSH_PLUGINS=(
    zsh-autosuggestions
    zsh-syntax-highlighting
  )

  # Clone each plugin if not present
  for plugin in "${ZSH_PLUGINS[@]}"; do
    if [ ! -d "${ZSH_CUSTOM_PLUGINS}/$plugin" ]; then
      echo "Cloning $plugin..."
      if git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM_PLUGINS}/$plugin"; then
        track_directory "${ZSH_CUSTOM_PLUGINS}/$plugin"
      else
        print_error "Failed to clone $plugin"
      fi
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

  if ! command -v nvim &> /dev/null; then
    echo "Warning: Neovim is not installed. Skipping Neovim plugin installation."
    return 0
  fi

  # Check if Neovim config exists
  if [ ! -d "$HOME/.config/nvim" ] && [ ! -f "$HOME/.config/nvim/init.lua" ] && [ ! -f "$HOME/.config/nvim/init.vim" ]; then
    echo "Warning: Neovim config not found. Skipping plugin installation."
    return 0
  fi

  # Install lazy.nvim if not already installed
  LAZY_NVIM_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
  if [ ! -d "$LAZY_NVIM_DIR" ]; then
    echo "Installing lazy.nvim plugin manager..."
    if git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZY_NVIM_DIR"; then
      track_directory "$LAZY_NVIM_DIR"
      record_action "DIRECTORY" "$LAZY_NVIM_DIR"
    else
      print_error "Failed to install lazy.nvim"
      return 1
    fi
  else
    echo "lazy.nvim is already installed."
  fi

  echo "Running Neovim to install plugins via lazy.nvim..."
  if nvim --headless "+Lazy! sync" +qa 2>&1 | tee /tmp/nvim_plugin_install.log; then
    echo "Neovim plugins installed successfully using lazy.nvim."
    rm -f /tmp/nvim_plugin_install.log
  else
    echo "Warning: Neovim plugin installation encountered some issues."
    echo "Check /tmp/nvim_plugin_install.log for details."
  fi
}

# ============================
# Install Atuin
# ============================
install_atuin() {
  print_message "Installing Atuin with Curl command"
  sleep 1
  if confirm "Would you like to install Atuin (shell history tool)?"; then
    if curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
      echo "Finished installing Atuin"
    else
      print_error "Failed to install Atuin"
    fi
  else
    echo "Skipping Atuin installation."
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
    echo "Tmux Plugin Manager (TPM) not found."
    if confirm "Would you like to install Tmux Plugin Manager?"; then
      mkdir -p "$HOME/.tmux/plugins"
      track_directory "$HOME/.tmux/plugins"
      if git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"; then
        track_directory "$TPM_DIR"
      else
        print_error "Failed to clone TPM"
        return 1
      fi
    else
      echo "Skipping Tmux Plugin Manager installation."
      return 0
    fi
  else
    echo "Tmux Plugin Manager is already installed."
  fi

  # Install Tmux plugins
  if command -v tmux &> /dev/null; then
    echo "Installing Tmux plugins..."

    # Check if tmux.conf exists
    if [ ! -f "$HOME/.tmux.conf" ]; then
      echo "Warning: ~/.tmux.conf not found. Skipping tmux plugin installation."
      return 0
    fi

    # Start a new detached tmux session
    if ! tmux new-session -d -s plugin_install_session; then
      print_error "Failed to create tmux session"
      return 1
    fi

    # Source tmux config and install plugins
    tmux send-keys -t plugin_install_session "tmux source-file ~/.tmux.conf" C-m
    tmux send-keys -t plugin_install_session "~/.tmux/plugins/tpm/scripts/install_plugins.sh" C-m

    # Wait a bit for installation
    echo "Waiting for Tmux plugins to install..."
    sleep 10

    # Check if the session is still running
    max_wait=30
    wait_count=0
    while tmux has-session -t plugin_install_session 2>/dev/null && [ $wait_count -lt $max_wait ]; do
      sleep 1
      wait_count=$((wait_count + 1))
    done

    # Kill the session if it's still running
    if tmux has-session -t plugin_install_session 2>/dev/null; then
      echo "Installation taking longer than expected, killing session..."
      tmux kill-session -t plugin_install_session
    fi

    echo "Tmux plugins installed successfully."
  else
    print_error "Tmux is not installed. Skipping Tmux plugin installation."
  fi
}

# ============================
# Install Specific Neovim Version
# ============================

install_neovim() {
  print_message "Installing Neovim $NEOVIM_VERSION from source..."
  sleep 1

  # Check if Neovim is already installed with the right version
  if command -v nvim &> /dev/null; then
    current_version=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [ "$current_version" = "$NEOVIM_VERSION" ]; then
      echo "Neovim $NEOVIM_VERSION is already installed."
      return
    else
      echo "Neovim $current_version is installed, but we need $NEOVIM_VERSION."

      if confirm "Would you like to remove the current version and install version $NEOVIM_VERSION?"; then
        # Remove existing Neovim installation
        if brew list neovim &>/dev/null; then
          brew uninstall neovim 2>/dev/null || true
        fi
        # Also remove any manually installed version
        rm -rf "$HOME/.local/bin/nvim" "$HOME/.local/nvim" 2>/dev/null || true
      else
        echo "Keeping current Neovim version $current_version."
        return
      fi
    fi
  fi

  # Install build dependencies
  echo "Installing build dependencies..."
  # macOS - ensure cmake and other tools are available
  if ! command -v cmake &> /dev/null; then
    echo "Installing cmake..."
    brew install cmake || print_error "Failed to install cmake"
  fi

  # Build Neovim from source
  echo "Building Neovim $NEOVIM_VERSION from source..."

  # Save original directory before any operations
  local original_dir="$PWD"

  # Create temporary directory with unique name
  local nvim_temp_dir=$(mktemp -d)

  # Clone and build Neovim
  # Use shallow clone for faster and more reliable cloning
  if git clone --depth 1 --branch v$NEOVIM_VERSION https://github.com/neovim/neovim.git "$nvim_temp_dir"; then
    cd "$nvim_temp_dir" || {
      print_error "Failed to enter Neovim build directory"
      rm -rf "$nvim_temp_dir"
      return 1
    }

    echo "Building Neovim with CMAKE_BUILD_TYPE=Release..."
    if make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local"; then
      echo "Installing Neovim..."
      if make install; then
        echo "Neovim installed successfully"
        record_action "NEOVIM" "$NEOVIM_VERSION"
        # Add Neovim to PATH for current session
        # Note: PATH is already configured in .zshrc via stow
        if [ -d "$HOME/.local/bin" ]; then
          export PATH="$HOME/.local/bin:$PATH"
          echo "Added $HOME/.local/bin to PATH for current session"
        fi
        # Return to original directory before cleanup
        cd "$original_dir" || cd /tmp
        rm -rf "$nvim_temp_dir"
      else
        print_error "Failed to install Neovim"
        cd "$original_dir" || cd /tmp
        rm -rf "$nvim_temp_dir"
        return 1
      fi
    else
      print_error "Failed to build Neovim"
      cd "$original_dir" || cd /tmp
      rm -rf "$nvim_temp_dir"
      return 1
    fi
  else
    print_error "Failed to clone Neovim repository"
    rm -rf "$nvim_temp_dir"
    return 1
  fi

  # Verify installation
  if command -v nvim &> /dev/null && nvim --version | grep -q "$NEOVIM_VERSION"; then
    echo "Neovim $NEOVIM_VERSION installed successfully:"
    nvim --version | head -n 1
  else
    print_error "Failed to install Neovim $NEOVIM_VERSION."
  fi
}

# ============================
# Source .zshrc
# ============================

source_zshrc() {
  print_message "Checking .zshrc configuration..."
  sleep 1
  # Check if .zshrc exists
  if [ ! -f "$HOME/.zshrc" ]; then
    echo "Warning: $HOME/.zshrc not found. It should have been created by stow."
    return 1
  fi
  
  # Source .zshrc if Zsh is the current shell
  if [ -n "$ZSH_VERSION" ]; then
    echo "Sourcing $HOME/.zshrc (errors will be suppressed)..."
    # Source with error suppression to handle missing dependencies gracefully
    source "$HOME/.zshrc" 2>/dev/null || true
    echo ".zshrc has been sourced."
  else
    echo "Current shell is not Zsh. Please restart your terminal or run 'source ~/.zshrc' manually."
    echo "Note: Some tools may not be available until you restart your terminal."
  fi
}

# ============================
# Main Installation Flow
# ============================

main() {
  print_message "Starting dotfiles macOS installation for $(hostname)"
  sleep 1

  # Check prerequisites first
  check_prerequisites

  # First check if the user wants to continue
  if ! confirm "This script will set up your macOS development environment. Continue?"; then
    echo "Installation cancelled by user."
    exit 0
  fi

  # ============================
  # Install Homebrew (First Step)
  # ============================
  print_message "Phase 1: Installing Homebrew"
  
  install_homebrew

  # ============================
  # Common Setup
  # ============================
  print_message "Phase 2: Common Setup"

  install_stow
  backup_existing_configs
  stow_dotfiles

  # ============================
  # macOS-Specific Installation
  # ============================
  print_message "Phase 3: macOS-Specific Setup"
  install_brew_cask_packages
  install_brew_packages
  install_font_hack
  install_oh_my_zsh
  install_zsh_plugins
  set_zsh_as_default

  # ============================
  # Common Tools
  # ============================
  print_message "Phase 4: Common Tools Installation"

  install_neovim
  install_neovim_plugins
  install_tmux_plugins
  install_atuin

  # ============================
  # Finalization
  # ============================
  print_message "Installation Completed!"
  echo "Your macOS development environment is set up successfully."

  # Print Neovim version as confirmation
  if command -v nvim &> /dev/null; then
    echo "Neovim version: $(nvim --version | head -n 1)"
  fi

  echo "Check $LOG_FILE for installation details and any errors."
  echo "Installation manifest: $INSTALL_MANIFEST"
  echo "Use apple_uninstall.sh to safely remove what was installed."

  # Source shell config and offer to start zsh
  source_zshrc
  if [[ "$SHELL" != *"zsh"* ]] && confirm "Would you like to start a new Zsh shell now?"; then
    exec zsh
  fi
}

main
