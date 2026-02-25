#!/bin/bash

########################################
# dotfiles Linux installation script of Ido Haber
# Last update: February 2026
########################################

set -euo pipefail

# ============================
# Core paths
# ============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================
# Argument parsing
# ============================
INSTALL_TYPE="desktop"
if [ $# -gt 0 ]; then
  case "$1" in
    desktop|server) INSTALL_TYPE="$1" ;;
    *) echo "Usage: $0 [desktop|server]"; exit 1 ;;
  esac
fi

# ============================
# OS check
# ============================
if [ "$(uname)" != "Linux" ]; then
  echo "ERROR: This script is for Linux only. For macOS, use apple_install.sh"
  exit 1
fi

# ============================
# Logging
# ============================
LOG_FILE="$SCRIPT_DIR/linux_install_${INSTALL_TYPE}.log"
INSTALL_MANIFEST="$SCRIPT_DIR/install_manifest_linux_${INSTALL_TYPE}.txt"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
: > "$INSTALL_MANIFEST"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== Linux Installation (${INSTALL_TYPE}) started at $(date) ====="
echo "Host: $(hostname) | Dotfiles: $DOTFILES_DIR"

# ============================
# Configuration
# ============================
NEOVIM_VERSION="0.11.0"

# Packages to stow (common to all Linux installs)
COMMON_CONFS=(nvim tmux vscode github neofetch htop ghostty nushell misc)
LINUX_CONFS=(linux-bash)

# APT packages to install
# Note: 'bat' binary is 'batcat' on Debian/Ubuntu; 'fd-find' binary is 'fdfind'
# Note: 'navi' is NOT in standard Ubuntu/Debian repos — install manually via cargo if needed
LINUX_APT_PACKAGES=(
  tmux git bat zoxide ripgrep nodejs npm jq direnv tree
  pandoc ffmpeg htop fzf zsh neofetch fd-find imagemagick
  make gcc g++ curl wget stow
)

# ============================
# State tracking
# ============================
INSTALLED_PACKAGES=()
BACKED_UP_FILES=()

record_action()  { echo "$1:$2" >> "$INSTALL_MANIFEST"; }
track_installed() { INSTALLED_PACKAGES+=("$1"); record_action "PACKAGE" "$1"; }
track_backup()   { BACKED_UP_FILES+=("$1"); record_action "BACKUP" "$1"; }

# ============================
# Cleanup / exit handler
# ============================
cleanup() {
  local exit_code=$?
  echo ""
  echo "===== Finished at $(date) (exit code: ${exit_code}) ====="
  if [ "$exit_code" -ne 0 ]; then
    echo "Installation FAILED. See $LOG_FILE for details."
  else
    echo "Installation SUCCEEDED."
    echo "Manifest: $INSTALL_MANIFEST"
  fi
}
trap cleanup EXIT

# ============================
# Helper functions
# ============================
print_message() {
  echo ""
  echo "========================================"
  echo "  $1"
  echo "========================================"
}

print_error() { echo "ERROR: $1" >&2; }

confirm() {
  local ans
  read -r -p "$1 (y/n) " ans
  [[ "${ans,,}" == y* ]]
}

# ============================
# Prerequisites
# ============================
check_prerequisites() {
  print_message "Checking prerequisites..."
  for tool in git curl; do
    if ! command -v "$tool" &>/dev/null; then
      print_error "Missing required tool: $tool"
      echo "  sudo apt update && sudo apt install -y git curl"
      exit 1
    fi
  done
  if ! sudo -n true 2>/dev/null; then
    echo "Sudo access required. You may be prompted for your password."
    if ! sudo true; then
      print_error "Cannot obtain sudo access."
      exit 1
    fi
  fi
  echo "Prerequisites OK."
}

# ============================
# GNU Stow installation
# ============================
install_stow() {
  print_message "Installing GNU Stow..."
  if command -v stow &>/dev/null; then
    echo "stow already installed: $(stow --version 2>&1 | head -1)"
    return 0
  fi
  if sudo apt install -y stow; then
    track_installed "stow"
    echo "stow installed."
  else
    print_error "Failed to install stow"
    exit 1
  fi
}

# ============================
# APT packages
# ============================
install_apt_packages() {
  print_message "Installing APT packages..."

  echo "Updating package list..."
  sudo apt update 2>&1 | tail -5 || echo "Warning: apt update had issues (continuing)"
  sudo apt upgrade -y 2>&1 | tail -5 || true

  for pkg in "${LINUX_APT_PACKAGES[@]}"; do
    if dpkg -s "$pkg" &>/dev/null 2>&1; then
      echo "  [already] $pkg"
    else
      echo "  [installing] $pkg..."
      if sudo apt install -y "$pkg" 2>/dev/null; then
        track_installed "$pkg"
      else
        echo "  [skipped] $pkg (not available in repos)"
      fi
    fi
  done
}

# ============================
# Backup existing configs
# Pre-backup before stowing so stow finds no conflicts
# ============================
backup_existing_configs() {
  print_message "Backing up existing config files..."
  local ts; ts=$(date +%Y%m%d_%H%M%S)
  local configs=(.zshrc .bashrc .tmux.conf .bash_profile)

  for cfg in "${configs[@]}"; do
    local target="$HOME/$cfg"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      local backup="${target}.backup.${ts}"
      echo "  $target → $backup"
      cp "$target" "$backup"
      track_backup "$target"
      record_action "BACKUP_FILE" "$backup"
      rm -f "$target"
    fi
  done
}

# ============================
# Safe stow: resolve conflicts automatically
# Strategy: --adopt moves conflicting files into dotfiles,
# then git checkout restores the dotfiles to their committed state,
# leaving the target path clear for the correct symlink.
# ============================
safe_stow() {
  local pkg="$1"
  if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
    echo "  [skipped] $pkg — directory not found"
    return 0
  fi

  echo "  Stowing $pkg..."
  if stow --no-folding "$pkg" 2>/dev/null; then
    echo "  [ok] $pkg"
    record_action "STOW" "$pkg"
    return 0
  fi

  # Conflict: adopt existing files into dotfiles, then restore dotfiles
  echo "  [conflict] $pkg — resolving..."
  stow --no-folding --adopt "$pkg" 2>/dev/null || true
  git -C "$DOTFILES_DIR" checkout -- . 2>/dev/null || true

  if stow --no-folding "$pkg" 2>/dev/null; then
    echo "  [ok] $pkg (after conflict resolution)"
    record_action "STOW" "$pkg"
  else
    print_error "Could not stow $pkg — check manually"
  fi
}

# ============================
# Stow dotfiles
# ============================
stow_dotfiles() {
  print_message "Stowing dotfiles..."
  local original_dir="$PWD"
  cd "$DOTFILES_DIR"

  local pkgs=("${COMMON_CONFS[@]}")
  if [ "$INSTALL_TYPE" = "server" ]; then
    # Remove GUI-only packages for server installs
    pkgs=(${pkgs[@]/ghostty/})
    pkgs=(${pkgs[@]/vscode/})
    echo "  Server install: skipping ghostty and vscode configs"
  fi

  for pkg in "${pkgs[@]}" "${LINUX_CONFS[@]}"; do
    safe_stow "$pkg"
  done

  cd "$original_dir"
  echo "Dotfiles stowed."
}

# ============================
# Ghostty (desktop only)
# ============================
install_ghostty() {
  [ "$INSTALL_TYPE" = "server" ] && return 0
  print_message "Installing Ghostty..."
  if command -v ghostty &>/dev/null; then
    echo "Ghostty already installed."
    return 0
  fi
  if command -v snap &>/dev/null; then
    if sudo snap install ghostty --classic 2>/dev/null; then
      record_action "SNAP_PACKAGE" "ghostty"
      echo "Ghostty installed via snap."
    else
      echo "Warning: Ghostty snap install failed. Install manually if needed."
    fi
  else
    echo "snap not available; install Ghostty manually: sudo snap install ghostty --classic"
  fi
}

# ============================
# Hack Nerd Font (desktop only)
# ============================
install_font_hack() {
  [ "$INSTALL_TYPE" = "server" ] && return 0
  print_message "Installing Hack Nerd Font..."
  if fc-list 2>/dev/null | grep -qi "Hack Nerd Font"; then
    echo "Hack Nerd Font already installed."
    return 0
  fi
  local fonts_dir="$HOME/.local/share/fonts"
  mkdir -p "$fonts_dir"
  local tmpdir; tmpdir=$(mktemp -d)
  echo "Downloading Hack Nerd Font..."
  if curl -fLo "$tmpdir/Hack.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"; then
    unzip -j "$tmpdir/Hack.zip" "*.ttf" -d "$fonts_dir" 2>/dev/null || true
    fc-cache -fv "$fonts_dir" 2>/dev/null || true
    record_action "FONTS" "HackNerdFont"
    echo "Hack Nerd Font installed."
  else
    print_error "Failed to download Hack Nerd Font"
  fi
  rm -rf "$tmpdir"
}

# ============================
# lazygit
# ============================
install_lazygit() {
  print_message "Installing lazygit..."
  if command -v lazygit &>/dev/null; then
    echo "lazygit already installed: $(lazygit --version | head -1)"
    return 0
  fi
  local version
  version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep '"tag_name"' | grep -oE 'v[0-9.]+' | head -1) || true
  if [ -z "$version" ]; then
    echo "Warning: Could not determine lazygit version. Skipping."
    return 0
  fi
  local tmpdir; tmpdir=$(mktemp -d)
  local url="https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version#v}_Linux_x86_64.tar.gz"
  if curl -fLo "$tmpdir/lazygit.tar.gz" "$url"; then
    tar -xf "$tmpdir/lazygit.tar.gz" -C "$tmpdir" lazygit
    sudo install -m 755 "$tmpdir/lazygit" /usr/local/bin/lazygit
    record_action "BINARY" "/usr/local/bin/lazygit"
    echo "lazygit ${version} installed."
  else
    echo "Warning: Failed to download lazygit."
  fi
  rm -rf "$tmpdir"
}

# ============================
# lazydocker
# ============================
install_lazydocker() {
  print_message "Installing lazydocker..."
  if command -v lazydocker &>/dev/null; then
    echo "lazydocker already installed."
    return 0
  fi
  if ! command -v docker &>/dev/null; then
    echo "Docker not found — skipping lazydocker."
    return 0
  fi
  local tmpdir; tmpdir=$(mktemp -d)
  echo "Downloading lazydocker installer..."
  if curl -fsSL \
      https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh \
      | INSTALL_DIR="$tmpdir" bash 2>/dev/null; then
    if [ -f "$tmpdir/lazydocker" ]; then
      sudo install -m 755 "$tmpdir/lazydocker" /usr/local/bin/lazydocker
      record_action "BINARY" "/usr/local/bin/lazydocker"
      echo "lazydocker installed."
    fi
  else
    echo "Warning: Failed to install lazydocker."
  fi
  rm -rf "$tmpdir"
}

# ============================
# Neovim — prebuilt binary (much faster than building from source)
# ============================
install_neovim() {
  print_message "Installing Neovim ${NEOVIM_VERSION}..."
  if command -v nvim &>/dev/null; then
    local cv; cv=$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [ "$cv" = "$NEOVIM_VERSION" ]; then
      echo "Neovim ${NEOVIM_VERSION} already installed."
      return 0
    fi
    echo "Found Neovim ${cv}; replacing with ${NEOVIM_VERSION}."
    sudo apt remove -y neovim 2>/dev/null || true
    rm -f "$HOME/.local/bin/nvim"
  fi

  local tmpdir; tmpdir=$(mktemp -d)
  local url="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  echo "Downloading Neovim ${NEOVIM_VERSION}..."
  if curl -fLo "$tmpdir/nvim.tar.gz" "$url"; then
    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" --strip-components=1 -xzf "$tmpdir/nvim.tar.gz"
    export PATH="$HOME/.local/bin:$PATH"
    record_action "NEOVIM" "${NEOVIM_VERSION}"
    echo "Neovim ${NEOVIM_VERSION} installed to ~/.local/bin"
  else
    print_error "Failed to download Neovim. Check version: ${NEOVIM_VERSION}"
  fi
  rm -rf "$tmpdir"
}

# ============================
# Neovim plugins via lazy.nvim
# ============================
install_neovim_plugins() {
  print_message "Installing Neovim plugins..."
  if ! command -v nvim &>/dev/null; then
    echo "Warning: nvim not found, skipping plugin install."
    return 0
  fi
  if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Warning: ~/.config/nvim not found (stow may have failed). Skipping."
    return 0
  fi

  local lazy_dir="$HOME/.local/share/nvim/lazy/lazy.nvim"
  if [ ! -d "$lazy_dir" ]; then
    echo "Bootstrapping lazy.nvim..."
    git clone --filter=blob:none --branch=stable \
      https://github.com/folke/lazy.nvim.git "$lazy_dir" || {
      print_error "Failed to clone lazy.nvim"
      return 1
    }
  fi

  echo "Syncing plugins (this may take a minute)..."
  nvim --headless "+Lazy! sync" +qa 2>&1 || true
  echo "Plugin sync complete."
}

# ============================
# Atuin (shell history)
# ============================
install_atuin() {
  print_message "Installing Atuin..."
  if command -v atuin &>/dev/null; then
    echo "Atuin already installed."
    return 0
  fi
  if confirm "Install Atuin (shell history sync tool)?"; then
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || \
      print_error "Failed to install Atuin (non-fatal)"
  else
    echo "Skipping Atuin."
  fi
}

# ============================
# tmux plugins via TPM
# Install plugins directly — no tmux session gymnastics needed
# ============================
install_tmux_plugins() {
  print_message "Installing tmux plugins..."
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ ! -d "$tpm_dir" ]; then
    echo "Cloning Tmux Plugin Manager..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || {
      print_error "Failed to clone TPM"
      return 1
    }
  fi

  if [ ! -f "$HOME/.tmux.conf" ]; then
    echo "Warning: ~/.tmux.conf not found. Skipping tmux plugin install."
    return 0
  fi

  echo "Running TPM install script..."
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" \
    bash "$tpm_dir/scripts/install_plugins.sh" 2>/dev/null || true
  echo "tmux plugins installed."
}

# ============================
# Main
# ============================
main() {
  print_message "Linux dotfiles installer — ${INSTALL_TYPE} — $(hostname)"

  check_prerequisites

  if ! confirm "Set up Linux ${INSTALL_TYPE} environment on $(hostname)?"; then
    echo "Cancelled."
    exit 0
  fi

  # Ensure ~/.local/bin is available for this session immediately
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"

  # Phase 1: Package management and stow
  print_message "Phase 1: Package management"
  install_stow
  install_apt_packages

  # Phase 2: Dotfiles (backup first, then stow)
  print_message "Phase 2: Dotfiles"
  backup_existing_configs
  stow_dotfiles

  # Phase 3: Additional tools
  print_message "Phase 3: Additional tools"
  install_ghostty
  install_font_hack
  install_lazygit
  install_lazydocker
  install_neovim

  # Phase 4: Editor and shell plugin setup
  print_message "Phase 4: Editor & shell plugins"
  install_neovim_plugins
  install_tmux_plugins
  install_atuin

  print_message "Installation complete!"
  echo "Log:      $LOG_FILE"
  echo "Manifest: $INSTALL_MANIFEST"
  echo ""
  echo "Note: 'bat' binary is 'batcat' on Ubuntu/Debian. Add: alias bat=batcat"
  echo "Note: 'fd'  binary is 'fdfind' on Ubuntu/Debian. Add: alias fd=fdfind"
  echo ""
  command -v nvim &>/dev/null && echo "Neovim: $(nvim --version | head -1)"
  echo "Restart your terminal (or run 'source ~/.bashrc') to apply all changes."
}

main
