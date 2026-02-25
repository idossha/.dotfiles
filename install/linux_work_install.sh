#!/bin/bash

########################################
# dotfiles Linux Work installation script of Ido Haber
# For work/HPC servers — no sudo required
# Installs everything to $HOME/.local
# Last update: February 2026
########################################

set -euo pipefail

# ============================
# Core paths
# ============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================
# OS check
# ============================
if [ "$(uname)" != "Linux" ]; then
  echo "ERROR: This script is for Linux only."
  exit 1
fi

# ============================
# Logging
# ============================
LOG_FILE="$SCRIPT_DIR/linux_work_install.log"
INSTALL_MANIFEST="$SCRIPT_DIR/install_manifest_linux_work.txt"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
: > "$INSTALL_MANIFEST"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== Linux Work Installation started at $(date) ====="
echo "Host: $(hostname) | Dotfiles: $DOTFILES_DIR"
echo "NOTE: No sudo required — all installs go to \$HOME/.local"

# ============================
# Configuration
# ============================
NEOVIM_VERSION="0.11.0"

# server_config provides a lightweight nvim config + tmux config.
# It stows config/ → ~/.config/, giving us ~/.config/nvim correctly.
# However, server_config/config/.tmux.conf maps to ~/.config/.tmux.conf
# (not ~/.tmux.conf), so we create that symlink separately after stowing.
WORK_CONFS=(server_config github htop misc)
LINUX_CONFS=(linux-bash)

# ============================
# State tracking
# ============================
BACKED_UP_FILES=()

record_action() { echo "$1:$2" >> "$INSTALL_MANIFEST"; }
track_backup()  { BACKED_UP_FILES+=("$1"); record_action "BACKUP" "$1"; }

# ============================
# Cleanup / exit handler
# ============================
cleanup() {
  local exit_code=$?
  echo ""
  echo "===== Finished at $(date) (exit code: ${exit_code}) ====="
  if [ "$exit_code" -ne 0 ]; then
    echo "Installation FAILED. See $LOG_FILE for details."
    # Restore backed-up configs if we failed
    for f in "${BACKED_UP_FILES[@]}"; do
      local ts_backup; ts_backup=$(ls "${f}.backup."* 2>/dev/null | tail -1)
      if [ -n "$ts_backup" ] && [ -f "$ts_backup" ]; then
        echo "Restoring: $ts_backup → $f"
        mv "$ts_backup" "$f"
      fi
    done
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
# Prerequisites (no sudo check)
# ============================
check_prerequisites() {
  print_message "Checking prerequisites..."
  for tool in git curl; do
    if ! command -v "$tool" &>/dev/null; then
      print_error "Missing required tool: $tool"
      echo "  This should be available on any work server. Contact your sysadmin."
      exit 1
    fi
  done
  echo "Prerequisites OK."
}

# ============================
# GNU Stow — no sudo
# Try system stow first, then build locally from source
# ============================
install_stow_work() {
  print_message "Checking for GNU Stow..."
  if command -v stow &>/dev/null; then
    echo "stow already available: $(stow --version 2>&1 | head -1)"
    return 0
  fi

  # Try module system (common on HPC clusters)
  if command -v module &>/dev/null; then
    module load stow 2>/dev/null && command -v stow &>/dev/null && {
      echo "stow loaded via module system."
      return 0
    } || true
  fi

  echo "stow not found. Building locally (no sudo)..."
  mkdir -p "$HOME/.local/bin"
  local tmpdir; tmpdir=$(mktemp -d)

  if curl -fLo "$tmpdir/stow.tar.gz" \
      "https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz" 2>/dev/null; then
    tar -xzf "$tmpdir/stow.tar.gz" -C "$tmpdir"
    local stow_src; stow_src=$(find "$tmpdir" -maxdepth 1 -name "stow-*" -type d | head -1)
    if [ -n "$stow_src" ]; then
      cd "$stow_src"
      if ./configure --prefix="$HOME/.local" && make && make install; then
        export PATH="$HOME/.local/bin:$PATH"
        record_action "LOCAL_BINARY" "$HOME/.local/bin/stow"
        echo "stow built and installed to ~/.local/bin"
        cd "$DOTFILES_DIR"
        rm -rf "$tmpdir"
        return 0
      fi
      cd "$DOTFILES_DIR"
    fi
  fi

  rm -rf "$tmpdir"
  print_error "Could not install stow. Ask your sysadmin: 'sudo apt install stow' or 'module load stow'"
  exit 1
}

# ============================
# Backup existing configs
# ============================
backup_existing_configs() {
  print_message "Backing up existing config files..."
  local ts; ts=$(date +%Y%m%d_%H%M%S)
  local configs=(.bashrc .bash_profile .tmux.conf)

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
# then git checkout restores the dotfiles to committed state,
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
# Stow dotfiles (work version)
#
# server_config layout:
#   server_config/config/.tmux.conf  → stows to ~/.config/.tmux.conf
#   server_config/config/nvim/       → stows to ~/.config/nvim/
#
# ~/.config/.tmux.conf is NOT where tmux looks. We therefore create
# ~/.tmux.conf as an additional symlink pointing to the same file.
# ============================
stow_dotfiles_work() {
  print_message "Stowing dotfiles..."
  local original_dir="$PWD"
  cd "$DOTFILES_DIR"

  for pkg in "${WORK_CONFS[@]}" "${LINUX_CONFS[@]}"; do
    safe_stow "$pkg"
  done

  # Create ~/.tmux.conf symlink (server_config stores it at ~/.config/.tmux.conf)
  local tmux_src="$DOTFILES_DIR/server_config/config/.tmux.conf"
  if [ -f "$tmux_src" ]; then
    if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
      local ts; ts=$(date +%Y%m%d_%H%M%S)
      mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.${ts}"
      echo "  Backed up existing ~/.tmux.conf"
    fi
    if [ ! -e "$HOME/.tmux.conf" ]; then
      ln -sfn "$tmux_src" "$HOME/.tmux.conf"
      record_action "SYMLINK" "$HOME/.tmux.conf → $tmux_src"
      echo "  [ok] ~/.tmux.conf → server_config/config/.tmux.conf"
    else
      echo "  ~/.tmux.conf already exists (symlink: $(readlink "$HOME/.tmux.conf"))"
    fi
  else
    echo "  Warning: server_config/.tmux.conf not found, skipping tmux symlink"
  fi

  cd "$original_dir"
  echo "Dotfiles stowed."
}

# ============================
# Hack Nerd Font (local, no sudo)
# Needed if using a local terminal on a work desktop.
# Safe to skip on headless servers.
# ============================
install_font_hack_work() {
  print_message "Installing Hack Nerd Font (local)..."
  if fc-list 2>/dev/null | grep -qi "Hack Nerd Font"; then
    echo "Hack Nerd Font already installed."
    return 0
  fi
  if ! confirm "Install Hack Nerd Font to ~/.local/share/fonts? (only needed for local terminals)"; then
    echo "Skipping font install."
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
    echo "Hack Nerd Font installed to $fonts_dir"
  else
    print_error "Failed to download Hack Nerd Font"
  fi
  rm -rf "$tmpdir"
}

# ============================
# Neovim — prebuilt binary, installed to ~/.local (no sudo)
# ============================
install_neovim_work() {
  print_message "Installing Neovim ${NEOVIM_VERSION} (local)..."
  if command -v nvim &>/dev/null; then
    local cv; cv=$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [ "$cv" = "$NEOVIM_VERSION" ]; then
      echo "Neovim ${NEOVIM_VERSION} already installed."
      return 0
    fi
    echo "Found Neovim ${cv}; will install ${NEOVIM_VERSION} to ~/.local/bin (no conflict with system nvim)."
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
install_neovim_plugins_work() {
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
    mkdir -p "$(dirname "$lazy_dir")"
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
# tmux plugins via TPM
# Install plugins directly — no tmux session gymnastics needed
# ============================
install_tmux_plugins_work() {
  print_message "Installing tmux plugins..."
  if ! command -v tmux &>/dev/null; then
    echo "tmux not available on this server. Skipping plugin install."
    return 0
  fi

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
# Ensure ~/.local/bin is in PATH persistently
# Only adds PATH line if not already present in shell config.
# (linux-bash stow package should handle this, but this is a safety net)
# ============================
ensure_path_in_shell_config() {
  print_message "Ensuring ~/.local/bin is in PATH..."
  local path_line='export PATH="$HOME/.local/bin:$PATH"'

  for rc in "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$rc" ] && ! grep -q '\.local/bin' "$rc"; then
      echo "" >> "$rc"
      echo "# Added by dotfiles installer" >> "$rc"
      echo "$path_line" >> "$rc"
      echo "  Added PATH to $rc"
    fi
  done
}

# ============================
# Main
# ============================
main() {
  print_message "Linux Work dotfiles installer — $(hostname)"
  echo "All installations go to \$HOME/.local — no sudo required."

  check_prerequisites

  if ! confirm "Set up personal dev environment on $(hostname) (no sudo)?"; then
    echo "Cancelled."
    exit 0
  fi

  # Ensure ~/.local/bin is in PATH immediately for this session
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"

  # Phase 1: Stow
  print_message "Phase 1: Stow"
  install_stow_work

  # Phase 2: Dotfiles (backup first, then stow)
  print_message "Phase 2: Dotfiles"
  backup_existing_configs
  stow_dotfiles_work

  # Phase 3: Tools
  print_message "Phase 3: Tools"
  install_font_hack_work
  install_neovim_work

  # Phase 4: Editor and shell plugins
  print_message "Phase 4: Editor & shell plugins"
  install_neovim_plugins_work
  install_tmux_plugins_work
  ensure_path_in_shell_config

  print_message "Installation complete!"
  echo "Log:      $LOG_FILE"
  echo "Manifest: $INSTALL_MANIFEST"
  echo ""
  command -v nvim &>/dev/null && echo "Neovim: $(nvim --version | head -1)"
  echo ""
  echo "Run 'source ~/.bashrc' or restart your terminal to apply PATH changes."
}

main
