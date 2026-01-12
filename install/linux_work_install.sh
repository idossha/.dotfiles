#!/bin/bash

########################################
# dotfiles Linux Work Installation script of Ido Haber
# Last update: January 12, 2026
# For work servers - no sudo required, focuses on home directory setup
########################################

# Exit on error with better error handling
set -euo pipefail

# ============================
# Get Script Directory
# ============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================
# OS Detection (Linux only)
# ============================
OS="$(uname)"
if [ "$OS" != "Linux" ]; then
  echo "ERROR: This script is for Linux only."
  exit 1
fi

# ============================
# Logging Configuration
# ============================
LOG_FILE="$SCRIPT_DIR/dotfiles_linux_work_install.log"
INSTALL_MANIFEST="$SCRIPT_DIR/install_manifest_linux_work.txt"

# Ensure log file directory exists and create log file
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
: > "$INSTALL_MANIFEST"  # Clear manifest file

# Redirect all output to both terminal and log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========== Linux Work Installation started at $(date) =========="
echo "OS: $OS"
echo "Log file: $LOG_FILE"
echo "Install manifest: $INSTALL_MANIFEST"
echo "NOTE: This script assumes basic tools (git, tmux, etc.) are already available"
echo "NOTE: No sudo permissions required - focuses on home directory configuration"

# ============================
# Cleanup and Error Handler
# ============================
TEMP_FILES=()
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
    echo "Use linux_uninstall.sh to safely remove what was installed."
  fi

  echo "========== Installation finished at $(date) =========="
}

trap cleanup EXIT

# ============================
# Helper Functions
# ============================

# Function to check prerequisites (work version - no sudo checks)
check_prerequisites() {
  local missing_tools=()

  # Check for essential tools (these should be available on work servers)
  local required_tools=("git" "curl")

  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      missing_tools+=("$tool")
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_error "Missing required tools: ${missing_tools[*]}"
    echo "Please ensure these tools are available on the work server."
    echo "This script assumes basic development tools are pre-installed."
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

# Function to handle stow conflicts (work version)
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
        local existing_name=$(echo "$existing_content" | grep -A 5 "\[user\]" | grep "name =" | sed 's/.*name = //' | xargs)
        local existing_email=$(echo "$existing_content" | grep -A 5 "\[user\]" | grep "email =" | sed 's/.*email = //' | xargs)
        if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
          sed -i "s/name = .*/name = $existing_name/" "$HOME/.gitconfig"
          sed -i "s/email = .*/email = $existing_email/" "$HOME/.gitconfig"
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

# Neovim version
NEOVIM_VERSION="0.11.0"

# Define common and Linux-specific packages (work version - no GUI apps)
COMMON_CONFS=("nvim" "tmux" "vscode" "github" "neofetch" "htop" "nushell" "misc")
LINUX_CONFS=("linux-bash")  # Linux-specific bash configuration

echo "Detected OS: $OS (Work installation - no sudo required)" >> "$LOG_FILE"

# ============================
# GNU Stow Installation (Work version - try local installation)
# ============================

install_stow_work() {
  print_message "Checking for GNU Stow..."
  sleep 1
  if ! command -v stow &> /dev/null; then
    echo "GNU Stow not found."
    if confirm "Would you like to install GNU Stow locally (no sudo required)?"; then
      echo "Installing GNU Stow to ~/.local/bin..."

      # Create local bin directory
      mkdir -p "$HOME/.local/bin"
      track_directory "$HOME/.local/bin"

      # Download and compile stow locally
      local temp_dir=$(mktemp -d)
      local original_dir="$PWD"

      cd "$temp_dir" || {
        print_error "Failed to enter temp directory"
        return 1
      }

      # Try to download stow source
      if curl -L -o stow.tar.gz "https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz" 2>/dev/null; then
        tar xzf stow.tar.gz
        cd stow-* 2>/dev/null || {
          print_error "Failed to extract stow"
          cd "$original_dir"
          rm -rf "$temp_dir"
          return 1
        }

        # Configure and make (no sudo needed)
        if ./configure --prefix="$HOME/.local" && make && make install; then
          echo "GNU Stow installed locally to ~/.local/bin"
          record_action "LOCAL_BINARY" "$HOME/.local/bin/stow"

          # Add to PATH for current session
          export PATH="$HOME/.local/bin:$PATH"
          echo "Added ~/.local/bin to PATH"

          cd "$original_dir"
          rm -rf "$temp_dir"
        else
          print_error "Failed to compile GNU Stow locally"
          cd "$original_dir"
          rm -rf "$temp_dir"
          return 1
        fi
      else
        print_error "Failed to download GNU Stow. You may need to install it manually or use system stow if available."
        cd "$original_dir"
        rm -rf "$temp_dir"
        return 1
      fi
    else
      echo "GNU Stow installation skipped. Some features may not work."
      return 1
    fi
  else
    echo "GNU Stow is already installed."
  fi
}

# ============================
# Backup Existing Config Files (Work version)
# ============================

backup_existing_configs() {
  print_message "Backing Up Existing Config Files..."
  sleep 1
  # List of config files to check
  CONFIG_FILES=(
    ".zshrc"
    ".bashrc"
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
# Stow Dotfiles (Work version)
# ============================

stow_dotfiles_work() {
  print_message "Stowing Dotfiles..."
  sleep 1

  # Debug: Show what directory we're looking in
  echo "Looking for dotfiles in: $DOTFILES_DIR"

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

  # Stow Linux-specific packages
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

  echo "Dotfiles have been symlinked successfully."

  cd "$original_dir"
}

# ============================
# Install Fonts (Work version - no sudo)
# ============================

install_font_hack_work() {
  print_message "Installing Hack Nerd Font locally..."
  sleep 1
  if ! fc-list | grep -i "Hack Nerd Font" &> /dev/null; then
    echo "Installing Hack Nerd Font to ~/.local/share/fonts..."
    local fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$fonts_dir"
    track_directory "$fonts_dir"
    cd "$fonts_dir"

    # Download Hack Nerd Font zip and extract
    echo "Downloading Hack Nerd Font..."
    FONT_ZIP_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
    if curl -fLo "hack-nerd-font.zip" "$FONT_ZIP_URL"; then
      # Extract only the TTF files we need
      unzip -j "hack-nerd-font.zip" "*Hack*Regular*.ttf" "*Hack*Bold*.ttf" "*Hack*Italic*.ttf" "*Hack*BoldItalic*.ttf" -d "$fonts_dir" 2>/dev/null || true
      rm -f "hack-nerd-font.zip"

      # Record the extracted fonts
      for font_file in "$fonts_dir"/*.ttf; do
        if [ -f "$font_file" ]; then
          record_action "FONT_FILE" "$font_file"
        fi
      done

      if [ "$(ls "$fonts_dir"/*.ttf 2>/dev/null | wc -l)" -gt 0 ]; then
        echo "Hack Nerd Font downloaded and extracted successfully."
      else
        print_error "Failed to extract fonts from zip file"
      fi
    else
      print_error "Failed to download Hack Nerd Font zip"
    fi

    # Update font cache if available (no sudo)
    if command -v fc-cache &>/dev/null; then
      fc-cache -fv
    else
      echo "Warning: fc-cache not available. Font cache not updated."
    fi

    echo "Hack Nerd Font installed locally."
  else
    echo "Hack Nerd Font is already installed."
  fi
}

# ============================
# Install Neovim Plugins (Work version)
# ============================

install_neovim_plugins_work() {
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
# Install Tmux Plugins (Work version)
# ============================

install_tmux_plugins_work() {
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
# Install Specific Neovim Version (Work version - no sudo)
# ============================

install_neovim_work() {
  print_message "Installing Neovim $NEOVIM_VERSION locally..."
  sleep 1

  # Check if Neovim is already installed with the right version
  if command -v nvim &> /dev/null; then
    current_version=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [ "$current_version" = "$NEOVIM_VERSION" ]; then
      echo "Neovim $NEOVIM_VERSION is already installed."
      return
    else
      echo "Neovim $current_version is installed, but we need $NEOVIM_VERSION."

      if confirm "Would you like to install version $NEOVIM_VERSION to ~/.local/bin?"; then
        echo "Installing to ~/.local/bin (will not conflict with system Neovim)"
      else
        echo "Keeping current Neovim version $current_version."
        return
      fi
    fi
  fi

  # Check for build dependencies (these should be available on work servers)
  local missing_deps=()
  local required_deps=("make" "gcc" "g++" "git")

  for dep in "${required_deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      missing_deps+=("$dep")
    fi
  done

  if [ ${#missing_deps[@]} -gt 0 ]; then
    print_error "Missing build dependencies: ${missing_deps[*]}"
    echo "Please ensure these tools are available on the work server."
    echo "You may need to request installation of build tools from system administrators."
    return 1
  fi

  # Build Neovim from source (to ~/.local)
  echo "Building Neovim $NEOVIM_VERSION from source..."

  # Save original directory before any operations
  local original_dir="$PWD"

  # Create temporary directory with unique name
  local nvim_temp_dir=$(mktemp -d)

  # Clone and build Neovim
  if git clone --depth 1 --branch v$NEOVIM_VERSION https://github.com/neovim/neovim.git "$nvim_temp_dir"; then
    cd "$nvim_temp_dir" || {
      print_error "Failed to enter Neovim build directory"
      rm -rf "$nvim_temp_dir"
      return 1
    }

    echo "Building Neovim with CMAKE_BUILD_TYPE=Release..."
    if make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local"; then
      echo "Installing Neovim locally..."
      if make install; then
        echo "Neovim installed successfully to ~/.local"
        record_action "NEOVIM" "$NEOVIM_VERSION"

        # Add Neovim to PATH for current session
        if [ -d "$HOME/.local/bin" ]; then
          export PATH="$HOME/.local/bin:$PATH"
          echo "Added ~/.local/bin to PATH"
        fi

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
# Ensure PATH is set in shell config
# ============================

ensure_path_in_shell_config() {
  print_message "Ensuring PATH is set in shell configuration..."
  sleep 1

  local path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
  local bashrc="$HOME/.bashrc"

  # Check if .bashrc exists and if PATH line is already there
  if [ -f "$bashrc" ] && ! grep -q "export PATH.*\$HOME/.local/bin" "$bashrc"; then
    echo "Adding ~/.local/bin to PATH in .bashrc..."
    echo "" >> "$bashrc"
    echo "# Added by dotfiles installation" >> "$bashrc"
    echo "$path_line" >> "$bashrc"
    echo "PATH updated in .bashrc. Please run 'source ~/.bashrc' to apply changes."
  elif [ -f "$bashrc" ]; then
    echo "PATH already configured in .bashrc"
  else
    echo "Warning: .bashrc not found. You may need to manually add: $path_line"
  fi
}

# ============================
# Main Installation Flow (Work version)
# ============================

main() {
  print_message "Starting dotfiles Linux Work installation for $(hostname)"
  sleep 1

  # Check prerequisites first
  check_prerequisites

  # First check if the user wants to continue
  if ! confirm "This script will set up your personal development environment on a work server (no sudo required). Continue?"; then
    echo "Installation cancelled by user."
    exit 0
  fi

  # ============================
  # Common Setup
  # ============================
  print_message "Phase 1: Common Setup"

  install_stow_work
  backup_existing_configs
  stow_dotfiles_work

  # ============================
  # Personal Tools Installation
  # ============================
  print_message "Phase 2: Personal Tools Installation"

  install_font_hack_work
  install_neovim_work
  install_neovim_plugins_work
  install_tmux_plugins_work
  ensure_path_in_shell_config

  # ============================
  # Finalization
  # ============================
  print_message "Installation Completed!"
  echo "Your personal development environment is set up on the work server."
  echo "All installations were done in your home directory (no sudo required)."

  # Print Neovim version as confirmation
  if command -v nvim &> /dev/null; then
    echo "Neovim version: $(nvim --version | head -n 1)"
  fi

  echo "Check $LOG_FILE for installation details and any errors."
  echo "Installation manifest: $INSTALL_MANIFEST"
  echo "Use linux_uninstall.sh to safely remove what was installed."

  # Final message
  echo "Please restart your terminal or run 'source ~/.bashrc' to apply changes."
}

main