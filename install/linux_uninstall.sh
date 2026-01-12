#!/bin/bash

########################################
# dotfiles Linux uninstallation script of Ido Haber
# Last update: January 12, 2026
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
  echo "ERROR: This script is for Linux only. For macOS, use apple_uninstall.sh"
  exit 1
fi

# ============================
# Configuration
# ============================
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_MANIFEST_DESKTOP="$SCRIPT_DIR/install_manifest_linux_desktop.txt"
INSTALL_MANIFEST_SERVER="$SCRIPT_DIR/install_manifest_linux_server.txt"
INSTALL_MANIFEST=""  # Will be set based on which one exists
HOME_DIR="$HOME"

# ============================
# Helper Functions
# ============================

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

# Function for user confirmation
confirm() {
  read -p "$1 (y/n) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

# ============================
# Check for Installation Manifest
# ============================

check_manifest() {
  # Check for desktop manifest first
  if [ -f "$INSTALL_MANIFEST_DESKTOP" ]; then
    INSTALL_MANIFEST="$INSTALL_MANIFEST_DESKTOP"
    echo "Found desktop installation manifest."
  elif [ -f "$INSTALL_MANIFEST_SERVER" ]; then
    INSTALL_MANIFEST="$INSTALL_MANIFEST_SERVER"
    echo "Found server installation manifest."
  else
    print_error "No installation manifest found."
    echo "Looked for:"
    echo "  $INSTALL_MANIFEST_DESKTOP"
    echo "  $INSTALL_MANIFEST_SERVER"
    echo ""
    echo "This means either:"
    echo "  1. The installation was not completed successfully"
    echo "  2. The manifest file was deleted"
    echo "  3. You're running uninstall from a different directory"
    echo ""
    if confirm "Do you want to proceed with manual uninstallation (not recommended)?"; then
      echo "Proceeding with manual uninstallation..."
      return 1
    else
      echo "Uninstallation cancelled. Please locate the correct manifest file."
      exit 0
    fi
  fi
  return 0
}

# ============================
# Parse Manifest and Uninstall
# ============================

uninstall_from_manifest() {
  print_message "Uninstalling based on manifest..."

  local packages_to_remove=()
  local snap_packages_to_remove=()
  local stow_packages=()
  local backup_files=()
  local directories_to_remove=()
  local font_files=()
  local binary_files=()
  local symlinks_to_remove=()
  local neovim_installed=false

  # Parse the manifest file
  while IFS=: read -r action_type item; do
    case "$action_type" in
      PACKAGE)
        packages_to_remove+=("$item")
        ;;
      SNAP_PACKAGE)
        snap_packages_to_remove+=("$item")
        ;;
      STOW)
        stow_packages+=("$item")
        ;;
      BACKUP)
        backup_files+=("$item")
        ;;
      BACKUP_FILE)
        # These are the actual backup file paths
        echo "Found backup file: $item"
        ;;
      DIRECTORY)
        directories_to_remove+=("$item")
        ;;
      FONT_FILE)
        font_files+=("$item")
        ;;
      BINARY)
        binary_files+=("$item")
        ;;
      NEOVIM)
        neovim_installed=true
        ;;
      SYMLINK)
        symlinks_to_remove+=("$item")
        ;;
      CLONED_REPO)
        echo "Note: Repository was cloned at: $item"
        ;;
    esac
  done < "$INSTALL_MANIFEST"

  # Unstow packages
  if [ ${#stow_packages[@]} -gt 0 ]; then
    print_message "Unstowing dotfiles packages..."
    local original_dir="$PWD"
    cd "$DOTFILES_DIR"
    for pkg in "${stow_packages[@]}"; do
      if [ -d "$pkg" ]; then
        echo "Unstowing $pkg..."
        stow -D "$pkg" 2>/dev/null || echo "Warning: Failed to unstow $pkg"
      fi
    done
    cd "$original_dir"
  fi

  # Remove symlinks
  if [ ${#symlinks_to_remove[@]} -gt 0 ]; then
    print_message "Removing symlinks..."
    for link in "${symlinks_to_remove[@]}"; do
      if [ -L "$link" ]; then
        echo "Removing symlink: $link"
        rm -f "$link"
      fi
    done
  fi

  # Restore backups
  if [ ${#backup_files[@]} -gt 0 ]; then
    print_message "Restoring backup files..."
    for file in "${backup_files[@]}"; do
      # Look for the most recent backup
      local backup_pattern="${file}.backup.*"
      local latest_backup=$(ls -t ${backup_pattern} 2>/dev/null | head -n 1)
      if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
        echo "Restoring backup for $file from $latest_backup"
        mv "$latest_backup" "$file"
        # Remove any other backups
        rm -f ${backup_pattern} 2>/dev/null || true
      else
        echo "No backup found for $file"
      fi
    done
  fi

  # Remove packages
  if [ ${#packages_to_remove[@]} -gt 0 ]; then
    if confirm "Do you want to remove installed packages? (${#packages_to_remove[@]} packages)"; then
      print_message "Removing packages..."
      for pkg in "${packages_to_remove[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
          echo "Removing $pkg..."
          sudo apt remove -y "$pkg" 2>/dev/null || echo "Warning: Failed to remove $pkg"
        fi
      done
    fi
  fi

  # Remove snap packages
  if [ ${#snap_packages_to_remove[@]} -gt 0 ]; then
    if confirm "Do you want to remove snap packages? (${#snap_packages_to_remove[@]} packages)"; then
      print_message "Removing snap packages..."
      for pkg in "${snap_packages_to_remove[@]}"; do
        if snap list | grep -q "^$pkg "; then
          echo "Removing $pkg..."
          sudo snap remove "$pkg" || echo "Warning: Failed to remove $pkg"
        fi
      done
    fi
  fi

  # Remove Neovim if it was installed
  if $neovim_installed; then
    if confirm "Do you want to remove custom Neovim installation?"; then
      print_message "Removing Neovim..."
      remove_custom_neovim
    fi
  fi

  # Remove font files
  if [ ${#font_files[@]} -gt 0 ]; then
    if confirm "Do you want to remove installed fonts? (${#font_files[@]} files)"; then
      print_message "Removing font files..."
      for font in "${font_files[@]}"; do
        if [ -f "$font" ]; then
          echo "Removing $font..."
          rm -f "$font"
        fi
      done
      # Update font cache if available
      if command -v fc-cache &>/dev/null; then
        fc-cache -f 2>/dev/null || true
      fi
    fi
  fi

  # Remove binary files (lazygit, lazydocker, etc.)
  if [ ${#binary_files[@]} -gt 0 ]; then
    if confirm "Do you want to remove installed binaries? (${#binary_files[@]} files)"; then
      print_message "Removing binary files..."
      for binary in "${binary_files[@]}"; do
        if [ -f "$binary" ]; then
          echo "Removing $binary..."
          sudo rm -f "$binary"
        fi
      done
    fi
  fi

  # Remove directories (ask individually for safety)
  if [ ${#directories_to_remove[@]} -gt 0 ]; then
    print_message "Checking directories created during installation..."
    for dir in "${directories_to_remove[@]}"; do
      if [ -d "$dir" ]; then
        # Check if directory is empty or only has dotfiles-related content
        local item_count=$(ls -A "$dir" 2>/dev/null | wc -l)
        if [ "$item_count" -eq 0 ]; then
          echo "Removing empty directory: $dir"
          rmdir "$dir" 2>/dev/null || true
        else
          if confirm "Directory $dir is not empty ($item_count items). Remove it?"; then
            echo "Removing directory: $dir"
            rm -rf "$dir"
          else
            echo "Keeping directory: $dir"
          fi
        fi
      fi
    done
  fi
}

# ============================
# Remove Custom Neovim Installation
# ============================

remove_custom_neovim() {
  echo "Removing custom Neovim installation..."
  local neovim_bin="$HOME/.local/bin/nvim"
  local neovim_share="$HOME/.local/share/nvim"
  local neovim_lib="$HOME/.local/lib/nvim"

  # Remove Neovim binary
  if [ -f "$neovim_bin" ]; then
    echo "Removing Neovim binary..."
    rm -f "$neovim_bin"
  fi

  # Remove Neovim share directory
  if [ -d "$neovim_share" ]; then
    if confirm "Remove Neovim data directory (includes plugins)? $neovim_share"; then
      echo "Removing Neovim share directory..."
      rm -rf "$neovim_share"
    fi
  fi

  # Remove Neovim lib directory
  if [ -d "$neovim_lib" ]; then
    echo "Removing Neovim lib directory..."
    rm -rf "$neovim_lib"
  fi

  # Remove Neovim config (ask first)
  local neovim_config="$HOME/.config/nvim"
  if [ -d "$neovim_config" ]; then
    if confirm "Remove Neovim configuration? $neovim_config"; then
      echo "Removing Neovim config directory..."
      rm -rf "$neovim_config"
    fi
  fi
}

# ============================
# Remove Additional Components (Optional)
# ============================

remove_additional_components() {
  print_message "Checking for additional components..."

  # Remove Atuin
  if [ -d "$HOME/.atuin" ] || command -v atuin &>/dev/null; then
    if confirm "Remove Atuin (shell history tool)?"; then
      echo "Removing Atuin..."
      rm -rf "$HOME/.atuin"
      local atuin_bin=$(command -v atuin 2>/dev/null || echo "")
      if [ -n "$atuin_bin" ] && [[ "$atuin_bin" == *"$HOME"* ]]; then
        rm -f "$atuin_bin"
      fi
    fi
  fi

  # Remove Tmux plugins
  if [ -d "$HOME/.tmux/plugins" ]; then
    if confirm "Remove Tmux plugins?"; then
      echo "Removing Tmux plugins..."
      rm -rf "$HOME/.tmux/plugins"
    fi
  fi
}

# ============================
# Main Uninstallation Flow
# ============================

main() {
  print_message "Dotfiles Linux Uninstallation Script"
  echo "OS: $OS"
  echo ""

  # Check for manifest
  if check_manifest; then
    echo "Found installation manifest with $(wc -l < "$INSTALL_MANIFEST") entries."
    echo ""
  else
    # Manual uninstallation mode (not recommended)
    print_error "Proceeding without manifest - cannot guarantee safe uninstallation"
    echo "This mode is not recommended and may not properly restore your system."
    return 1
  fi

  # Ask for confirmation
  echo "This script will uninstall components that were installed by the Linux dotfiles setup."
  echo "Your original configuration files will be restored from backups where available."
  echo ""
  if ! confirm "Are you sure you want to continue with the uninstallation?"; then
    echo "Uninstallation cancelled."
    exit 0
  fi

  # Uninstall from manifest
  uninstall_from_manifest

  # Ask about additional components
  if confirm "Do you want to check for additional components to remove?"; then
    remove_additional_components
  fi

  # Archive the manifest
  if [ -n "$INSTALL_MANIFEST" ] && [ -f "$INSTALL_MANIFEST" ]; then
    local archive_name="${INSTALL_MANIFEST}.$(date +%Y%m%d_%H%M%S).removed"
    mv "$INSTALL_MANIFEST" "$archive_name"
    echo "Installation manifest archived to: $archive_name"
  fi

  print_message "Uninstallation Completed!"
  echo "Your Linux system has been restored to its pre-installation state."
  echo "You may need to restart your terminal for all changes to take effect."
  echo ""
  echo "Note: Some system packages may still be installed as they might be used by other software."
}

# Execute the main function
main