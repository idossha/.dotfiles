#!/bin/bash

########################################
# dotfiles installation script of Ido Haber
# Last update: March 29, 2025
########################################

# Exit on error with better error handling
set -euo pipefail

# ============================
# Get Script Directory
# ============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================
# OS Detection (Early - needed by cleanup)
# ============================
OS="$(uname)"
is_mac=false
is_linux=false

if [ "$OS" == "Darwin" ]; then
  is_mac=true
elif [ "$OS" == "Linux" ]; then
  is_linux=true
else
  echo "ERROR: Unsupported OS: $OS"
  exit 1
fi

# ============================
# Logging Configuration
# ============================
LOG_FILE="$SCRIPT_DIR/dotfiles_install.log"
INSTALL_MANIFEST="$SCRIPT_DIR/install_manifest.txt"

# Ensure log file directory exists and create log file
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
: > "$INSTALL_MANIFEST"  # Clear manifest file

# Redirect all output to both terminal and log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========== Installation started at $(date) =========="
echo "OS: $OS (macOS: $is_mac, Linux: $is_linux)"
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
        if $is_mac; then
          for pkg in "${INSTALLED_PACKAGES[@]}"; do
            brew uninstall "$pkg" 2>/dev/null || true
          done
        elif $is_linux; then
          sudo apt remove -y "${INSTALLED_PACKAGES[@]}" || true
        fi
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
    echo "Use this file with uninstall.sh to safely remove what was installed."
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
    echo "Please install these tools before running this script:"
    if $is_mac; then
      echo "  xcode-select --install"
    elif $is_linux; then
      echo "  sudo apt update && sudo apt install -y git curl"
    fi
    exit 1
  fi
  
  # Check for sudo access on Linux
  if $is_linux; then
    if ! sudo -n true 2>/dev/null; then
      echo "This script requires sudo access. You may be prompted for your password."
      if ! sudo true; then
        print_error "Cannot obtain sudo access. Exiting."
        exit 1
      fi
    fi
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
          # Use proper sed syntax for macOS and Linux compatibility
          if $is_mac; then
            sed -i '' "s/name = .*/name = $existing_name/" "$HOME/.gitconfig"
            sed -i '' "s/email = .*/email = $existing_email/" "$HOME/.gitconfig"
          else
            sed -i "s/name = .*/name = $existing_name/" "$HOME/.gitconfig"
            sed -i "s/email = .*/email = $existing_email/" "$HOME/.gitconfig"
          fi
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

# Directory where the dotfiles are located
DOTFILES_DIR="$SCRIPT_DIR"

# Oh My Zsh installation directory
OH_MY_ZSH_DIR="$HOME/oh-my-zsh"

# Neovim version
NEOVIM_VERSION="0.11.0"

# Define common and OS-specific packages
COMMON_CONFS=("nvim" "tmux" "vscode" "github" "neofetch" "htop" "ghostty" "nushell" "misc" "karabiner") 
MACOS_CONFS=("zsh" "aerospace") 
LINUX_CONFS=("linux-bash")  # Linux-specific bash configuration

# Define common packages available via Homebrew on both macOS and Linux
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
)

# Define macOS-specific packages
BREW_CASK_PACKAGES=(
  keyboardcleantool
  #raycask
  ghostty
)

MACOS_BREW_PACKAGES=(
  nikitabobko/tap/aerospace
  stats
)

# Define Linux-specific packages via APT
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
  fd-find  # fd is called fd-find on Debian/Ubuntu
  imagemagick
  make
  gcc
  g++
  curl
  wget
)

# Optional Linux packages (not in standard repos, installed separately)
# - lazygit: Installed via GitHub releases if user wants it
# - lazydocker: Installed via GitHub releases if user wants it  
# - nushell: Available in newer distros or via snap

echo "Detected OS: $OS (macOS: $is_mac, Linux: $is_linux)" >> "$LOG_FILE"

# ============================
# Package Manager Installation
# ============================

install_homebrew() {
  print_message "Checking for Homebrew..."
  sleep 1
  if ! command -v brew &> /dev/null; then
    if confirm "Homebrew not found. Would you like to install it?"; then
      echo "Installing Homebrew..."
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
        # Add to both .profile and .bashrc for login and interactive shells
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
        if [ -f "$HOME/.bashrc" ]; then
          echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
        fi
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      fi
    else
      print_error "Homebrew is required but won't be installed. Exiting."
      exit 1
    fi
  else
    echo "Homebrew is already installed."
  fi

  # Update Homebrew
  print_message "Updating Homebrew..."
  brew update
}

install_apt_packages() {
  if $is_linux; then
    print_message "Updating APT..."
    # Capture both stdout and stderr for better error detection
    if sudo apt update 2>&1 | tee /tmp/apt_update.log; then
      echo "APT update completed successfully."
    else
      if grep -q "404.*Not Found" /tmp/apt_update.log; then
        echo "Warning: Some repositories failed to update (likely removed PPAs)."
        echo "This is not critical. Continuing with installation..."
      else
        print_error "APT update failed with unknown error."
      fi
    fi
    rm -f /tmp/apt_update.log

    print_message "Upgrading existing packages..."
    sudo apt upgrade -y

    print_message "Installing APT packages..."
    for package in "${LINUX_APT_PACKAGES[@]}"; do
      if ! dpkg -l | grep -q "^ii  $package "; then
        echo "Installing $package..."
        if sudo apt install -y "$package"; then
          track_installed "$package"
        else
          echo "Warning: Failed to install $package (may not be available in your repos)"
        fi
      else
        echo "$package is already installed."
      fi
    done
  fi
}

# ============================
# GNU Stow Installation
# ============================

install_stow() {
  print_message "Checking for GNU Stow..."
  sleep 1
  if ! command -v stow &> /dev/null; then
    echo "GNU Stow not found. Installing GNU Stow..."
    if $is_mac; then
      if brew install stow; then
        track_installed "stow"
      else
        print_error "Failed to install GNU Stow"
        exit 1
      fi
    elif $is_linux; then
      if sudo apt install -y stow; then
        track_installed "stow"
      else
        print_error "Failed to install GNU Stow"
        exit 1
      fi
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

  # Stow common packages
  for pkg in "${COMMON_CONFS[@]}"; do
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

  # Stow OS-specific packages
  if $is_mac; then
    for pkg in "${MACOS_CONFS[@]}"; do
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
  elif $is_linux; then
    for pkg in "${LINUX_CONFS[@]}"; do
      if [ -d "$pkg" ]; then
        echo "Stowing $pkg..."
        # Handle conflicts before stowing
        handle_stow_conflicts "$pkg"

        # Try to stow, and if it fails due to conflicts, try with --adopt
        if ! stow "$pkg" 2>/dev/null; then
          echo "Retrying $pkg with --adopt..."
          if stow --adopt "$pkg"; then
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
  fi

  echo "Dotfiles have been symlinked successfully."

  cd "$original_dir"
}

# ============================
# Install Homebrew Cask Packages (macOS only)
# ============================

install_brew_cask_packages() {
  if $is_mac; then
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
  fi
}

# ============================
# Install Homebrew Packages
# ============================

install_brew_packages() {
  if $is_mac || $is_linux; then
    print_message "Installing Homebrew packages..."
    sleep 1

    # Taps required for certain packages (macOS only)
    if $is_mac; then
      # Tap for aerospace
      if ! brew tap | grep -q "nikitabobko/tap"; then
        echo "Tapping nikitabobko/tap..."
        brew tap nikitabobko/tap
      fi
    fi

    # Install common packages
    for package in "${COMMON_BREW_PACKAGES[@]}"; do
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

    # Install macOS-specific packages
    if $is_mac; then
      for package in "${MACOS_BREW_PACKAGES[@]}"; do
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
    fi
  fi
}

# ============================
# Install Ghostty (Linux via Snap)
# ============================

install_ghostty() {
  if $is_linux; then
    print_message "Installing Ghostty..."
    sleep 1

    # Check if snap is available
    if command -v snap &> /dev/null; then
      echo "Installing Ghostty via snap..."
      if sudo snap install ghostty --classic; then
        track_installed "ghostty"
        record_action "SNAP_PACKAGE" "ghostty"
        echo "Ghostty installed successfully via snap"
      else
        print_error "Failed to install Ghostty via snap"
      fi
    else
      print_error "Snap is not available. Cannot install Ghostty."
      echo "You can install Ghostty manually with: sudo snap install ghostty --classic"
    fi
  fi
}

# ============================
# Install lazygit (Linux via GitHub Releases)
# ============================

install_lazygit_linux() {
  if $is_linux; then
    print_message "Installing lazygit..."
    sleep 1
    
    if command -v lazygit &> /dev/null; then
      echo "lazygit is already installed: $(lazygit --version)"
      return 0
    fi
    
    if ! confirm "Would you like to install lazygit (git TUI)?"; then
      echo "Skipping lazygit installation."
      return 0
    fi
    
    echo "Installing lazygit from GitHub releases..."
    local lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    
    if [ -z "$lazygit_version" ]; then
      print_error "Failed to fetch lazygit version"
      return 1
    fi
    
    echo "Latest lazygit version: $lazygit_version"
    local temp_dir=$(mktemp -d)
    local original_dir="$PWD"
    
    cd "$temp_dir" || {
      print_error "Failed to enter temp directory"
      rm -rf "$temp_dir"
      return 1
    }
    
    local lazygit_url="https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lazygit_version}_Linux_x86_64.tar.gz"
    
    if curl -Lo lazygit.tar.gz "$lazygit_url"; then
      tar xf lazygit.tar.gz lazygit
      sudo install lazygit /usr/local/bin
      record_action "BINARY" "/usr/local/bin/lazygit"
      echo "lazygit installed successfully"
      cd "$original_dir" || cd /tmp
      rm -rf "$temp_dir"
    else
      print_error "Failed to download lazygit"
      cd "$original_dir" || cd /tmp
      rm -rf "$temp_dir"
      return 1
    fi
  fi
}

# ============================
# Install lazydocker (Linux via GitHub Releases)
# ============================

install_lazydocker_linux() {
  if $is_linux; then
    print_message "Installing lazydocker..."
    sleep 1
    
    if command -v lazydocker &> /dev/null; then
      echo "lazydocker is already installed"
      return 0
    fi
    
    if ! confirm "Would you like to install lazydocker (Docker TUI)?"; then
      echo "Skipping lazydocker installation."
      return 0
    fi
    
    echo "Installing lazydocker from GitHub releases..."
    local temp_dir=$(mktemp -d)
    local original_dir="$PWD"
    
    cd "$temp_dir" || {
      print_error "Failed to enter temp directory"
      rm -rf "$temp_dir"
      return 1
    }
    
    curl -sS https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    
    cd "$original_dir" || cd /tmp
    
    if [ -f "$HOME/.local/bin/lazydocker" ]; then
      sudo install "$HOME/.local/bin/lazydocker" /usr/local/bin/
      record_action "BINARY" "/usr/local/bin/lazydocker"
      echo "lazydocker installed successfully"
    else
      print_error "Failed to install lazydocker"
    fi
    
    rm -rf "$temp_dir"
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
        if $is_mac; then
          brew uninstall neovim 2>/dev/null || true
          # Also remove any manually installed version
          rm -rf "$HOME/.local/bin/nvim" "$HOME/.local/nvim" 2>/dev/null || true
        elif $is_linux; then
          sudo apt remove -y neovim 2>/dev/null || true
          # Also remove any manually installed version
          rm -rf "$HOME/.local/bin/nvim" "$HOME/.local/nvim" 2>/dev/null || true
        fi
      else
        echo "Keeping current Neovim version $current_version."
        return
      fi
    fi
  fi

  # Install build dependencies
  echo "Installing build dependencies..."
  if $is_mac; then
    # macOS - ensure cmake and other tools are available
    if ! command -v cmake &> /dev/null; then
      echo "Installing cmake..."
      brew install cmake || print_error "Failed to install cmake"
    fi
  elif $is_linux; then
    # Linux - install build dependencies
    echo "Installing build dependencies for Linux..."
    sudo apt update 2>&1 | tee /tmp/apt_update_nvim.log || true
    sudo apt install -y cmake make gcc g++ git ninja-build gettext libtool libtool-bin autoconf automake pkg-config unzip || print_error "Failed to install build dependencies"
    rm -f /tmp/apt_update_nvim.log
  fi

  # Build Neovim from source
  echo "Building Neovim $NEOVIM_VERSION from source..."

  # Save original directory before any operations
  local original_dir="$PWD"
  
  # Create temporary directory with unique name
  local nvim_temp_dir=$(mktemp -d)
  
  # Don't add to TEMP_FILES - we'll clean it up manually
  # TEMP_FILES+=("$nvim_temp_dir")

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
        if [ -d "$HOME/.local/bin" ]; then
          export PATH="$HOME/.local/bin:$PATH"
          echo "Added $HOME/.local/bin to PATH"
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
# Install Fonts
# ============================

install_font_hack() {
  print_message "Installing font-hack-nerd-font..."
  sleep 1
  if $is_mac; then
    if ! brew list --cask font-hack-nerd-font &>/dev/null; then
      brew tap homebrew/cask-fonts
      if brew install --cask font-hack-nerd-font; then
        track_installed "font-hack-nerd-font"
      else
        print_error "Failed to install font-hack-nerd-font"
      fi
    else
      echo "font-hack-nerd-font is already installed."
    fi
  elif $is_linux; then
    if ! fc-list | grep -i "Hack Nerd Font" &> /dev/null; then
      echo "Installing Hack Nerd Font..."
      local fonts_dir="$HOME/.local/share/fonts"
      local original_dir="$PWD"
      mkdir -p "$fonts_dir"
      track_directory "$fonts_dir"
      cd "$fonts_dir"
      
      # Download each font variant
      for variant in "Regular" "Bold" "Italic" "BoldItalic"; do
        echo "Downloading Hack ${variant}..."
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/${variant}/complete/Hack%20${variant}%20Nerd%20Font%20Complete.ttf"
        if curl -fLo "Hack ${variant} Nerd Font Complete.ttf" "$FONT_URL"; then
          record_action "FONT_FILE" "$fonts_dir/Hack ${variant} Nerd Font Complete.ttf"
        else
          print_error "Failed to download Hack ${variant} font"
        fi
      done
      
      # Update font cache
      fc-cache -fv
      cd "$original_dir"
      
      echo "Hack Nerd Font installed successfully."
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
    echo "Oh My Zsh not found."
    if confirm "Would you like to install Oh My Zsh?"; then
      # Set ZSH environment variable to install to $HOME/oh-my-zsh
      export ZSH="$OH_MY_ZSH_DIR"

      # Install Oh My Zsh without modifying .zshrc
      RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      
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
# Source .zshrc
# ============================

source_zshrc() {
  print_message "Sourcing .zshrc..."
  sleep 1
  # Source .zshrc if Zsh is the current shell
  if [ -n "$ZSH_VERSION" ]; then
    echo "Sourcing $HOME/.zshrc"
    source "$HOME/.zshrc" || true  # Don't fail if there are issues
    echo ".zshrc has been sourced."
  else
    echo "Current shell is not Zsh. Please restart your terminal or run 'source ~/.zshrc' manually."
  fi
}

# ============================
# Main Installation Flow
# ============================

main() {
  print_message "Starting dotfiles installation for $(hostname) (OS: $OS)"
  sleep 1

  # Check prerequisites first
  check_prerequisites

  # First check if the user wants to continue
  if ! confirm "This script will set up your development environment. Continue?"; then
    echo "Installation cancelled by user."
    exit 0
  fi

  # ============================
  # Common Setup (Both macOS and Linux)
  # ============================
  print_message "Phase 1: Common Setup"
  
  install_stow
  backup_existing_configs
  stow_dotfiles

  # ============================
  # macOS-Specific Installation
  # ============================
  if $is_mac; then
    print_message "Phase 2: macOS-Specific Setup"
    
    install_homebrew
    install_brew_cask_packages
    install_brew_packages
    install_font_hack
    install_oh_my_zsh
    install_zsh_plugins
    set_zsh_as_default
  fi

  # ============================
  # Linux-Specific Installation
  # ============================
  if $is_linux; then
    print_message "Phase 2: Linux-Specific Setup"
    
    install_apt_packages
    install_ghostty
    install_font_hack
    install_lazygit_linux
    install_lazydocker_linux
  fi

  # ============================
  # Common Tools (Both macOS and Linux)
  # ============================
  print_message "Phase 3: Common Tools Installation"
  
  install_neovim
  install_neovim_plugins
  install_tmux_plugins
  install_atuin

  # ============================
  # Finalization
  # ============================
  print_message "Installation Completed!"
  echo "Your development environment is set up successfully."
  
  # Print Neovim version as confirmation
  if command -v nvim &> /dev/null; then
    echo "Neovim version: $(nvim --version | head -n 1)"
  fi
  
  echo "Check $LOG_FILE for installation details and any errors."
  echo "Installation manifest: $INSTALL_MANIFEST"
  
  # Source shell config
  if $is_mac; then
    source_zshrc
    # Only offer to start zsh on macOS
    if [[ "$SHELL" != *"zsh"* ]] && confirm "Would you like to start a new Zsh shell now?"; then
      exec zsh
    fi
  elif $is_linux; then
    echo "Please restart your terminal or run 'source ~/.bashrc' to apply changes."
  fi
}

main
