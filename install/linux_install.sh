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
COMMON_CONFS=(nvim tmux github htop ghostty nushell misc)
LINUX_CONFS=(linux-bash)

LINUX_APT_PACKAGES=(
  tmux git bat zoxide ripgrep jq direnv tree
  pandoc ffmpeg htop btop fzf zsh fastfetch fd-find imagemagick
  make gcc g++ curl wget stow gh
  python3-pip python3-venv
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
# Backup existing configs + fix symlinks that block stow
# ============================
backup_existing_configs() {
  print_message "Backing up existing config files..."
  local ts; ts=$(date +%Y%m%d_%H%M%S)

  # ── Fix ~/.config ───────────────────────────────────────────────────────────
  # stow recurses INTO ~/.config to place per-tool symlinks. If ~/.config is
  # itself a symlink (e.g., from the work install script pointing to
  # server_config/config), stow cannot manage its contents and reports every
  # .config/* package as "existing target is not owned by stow: .config".
  if [ -L "$HOME/.config" ]; then
    local ct; ct=$(readlink "$HOME/.config")
    echo "  ~/.config is a symlink → $ct"
    echo "  Replacing with a real directory so stow can manage its contents..."
    rm "$HOME/.config"
    mkdir -p "$HOME/.config"
    record_action "FIXED_SYMLINK" "~/.config was → $ct (now a real directory)"
  else
    mkdir -p "$HOME/.config"
  fi

  # ── Remove stale absolute dotfile symlinks ──────────────────────────────────
  # The work install creates absolute symlinks (e.g., ~/.tmux.conf →
  # /abs/path/dotfiles/server_config/config/.tmux.conf). stow treats these as
  # "not owned by stow" and --adopt cannot resolve symlink conflicts (only file
  # conflicts). We must remove them before stowing so stow can create correct ones.
  local to_check=(.tmux.conf .gitconfig .zshrc .bashrc)
  for f in "${to_check[@]}"; do
    local t="$HOME/$f"
    if [ -L "$t" ]; then
      local dest; dest=$(readlink "$t")
      # Only remove symlinks that point into our dotfiles dir
      # (foreign symlinks are left alone)
      if [[ "$dest" == "$DOTFILES_DIR"* ]]; then
        echo "  Removing stale dotfile symlink: $t → $dest"
        rm "$t"
        record_action "REMOVED_SYMLINK" "$t was → $dest"
      fi
    fi
  done

  # ── Backup regular (non-symlink) config files ───────────────────────────────
  local configs=(.zshrc .bashrc .tmux.conf .bash_profile)
  for cfg in "${configs[@]}"; do
    local target="$HOME/$cfg"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      local backup="${target}.backup.${ts}"
      echo "  Backing up $target → $backup"
      cp "$target" "$backup"
      track_backup "$target"
      record_action "BACKUP_FILE" "$backup"
      rm -f "$target"
    fi
  done
}

# ============================
# Safe stow: resolve conflicts automatically
#
# Why --restow and NOT --no-folding:
#   --restow  = unstow + stow, so already-linked packages are re-linked cleanly
#   --no-folding interferes with previously folded directory symlinks (e.g.
#   ~/.config/nvim → dotfiles/nvim/.config/nvim) causing spurious conflicts.
#
# Conflict recovery:
#   --adopt moves conflicting target files INTO the dotfiles dir (overwriting),
#   then git checkout restores dotfiles to committed state.
#   Net effect: the conflicting file at the target is gone → stow succeeds.
# ============================
safe_stow() {
  local pkg="$1"
  if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
    echo "  [skipped] $pkg — directory not found"
    return 0
  fi

  echo "  Stowing $pkg..."
  local output
  if output=$(stow --restow "$pkg" 2>&1); then
    echo "  [ok] $pkg"
    record_action "STOW" "$pkg"
    return 0
  fi

  # Conflict: adopt into dotfiles, restore from git, then re-stow
  echo "  Resolving conflicts for $pkg..."
  stow --adopt "$pkg" 2>/dev/null || true
  git -C "$DOTFILES_DIR" checkout -- . 2>/dev/null || true

  if output=$(stow --restow "$pkg" 2>&1); then
    echo "  [ok] $pkg (conflicts resolved)"
    record_action "STOW" "$pkg"
  else
    # Non-fatal: warn and continue so one bad package doesn't abort everything
    echo "  [warning] $pkg — could not fully stow (manual fix may be needed):"
    echo "$output" | head -5 | sed 's/^/    /'
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
# Docker
# ============================
install_docker() {
  print_message "Installing Docker..."
  if command -v docker &>/dev/null; then
    echo "Docker already installed: $(docker --version 2>/dev/null || echo 'version unknown')"
    return 0
  fi
  if confirm "Install Docker?"; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && \
      sudo sh /tmp/get-docker.sh && \
      sudo usermod -aG docker "$USER" && \
      record_action "DOCKER" "installed" && \
      echo "Docker installed. You may need to log out/in for group changes." || \
      print_error "Failed to install Docker (non-fatal)"
    rm -f /tmp/get-docker.sh
  else
    echo "Skipping Docker."
  fi
}

# ============================
# k3s (lightweight Kubernetes)
# ============================
install_k3s() {
  print_message "Installing k3s..."
  if command -v k3s &>/dev/null; then
    echo "k3s already installed: $(k3s --version 2>/dev/null || echo 'version unknown')"
    return 0
  fi
  if confirm "Install k3s?"; then
    curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true sh - && \
      record_action "K3S" "installed" && \
      echo "k3s installed (service not started). Run: sudo k3s serve" || \
      print_error "Failed to install k3s (non-fatal)"
  else
    echo "Skipping k3s."
  fi
}

# ============================
# Node.js and npm via nvm
# ============================
install_node_nvm() {
  print_message "Installing Node.js and npm via nvm..."
  if command -v node &>/dev/null; then
    echo "Node.js already installed: $(node --version)"
    return 0
  fi
  if [ -d "$HOME/.nvm" ]; then
    echo "nvm already installed. Loading..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi
  if confirm "Install Node.js via nvm?"; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
      export NVM_DIR="$HOME/.nvm" && \
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
      nvm install --lts && \
      record_action "NODE_NVM" "installed" && \
      echo "Node.js installed via nvm." || \
      print_error "Failed to install Node.js via nvm (non-fatal)"
  else
    echo "Skipping Node.js."
  fi
}

# ============================
# Syncthing
# ============================
install_syncthing() {
  print_message "Installing Syncthing..."
  if command -v syncthing &>/dev/null; then
    echo "Syncthing already installed: $(syncthing --version 2>/dev/null | head -1)"
    return 0
  fi
  if confirm "Install Syncthing?"; then
    local tmpdir; tmpdir=$(mktemp -d)
    local version
    version=$(curl -fsSL "https://api.github.com/repos/syncthing/syncthing/releases/latest" \
      | grep '"tag_name"' | grep -oE 'v[0-9.]+' | head -1) || true
    if [ -z "$version" ]; then
      echo "Warning: Could not determine Syncthing version."
      return 0
    fi
    local arch
    arch=$(uname -m)
    case "$arch" in
      x86_64) arch="amd64" ;;
      aarch64|arm64) arch="arm64" ;;
    esac
    local url="https://github.com/syncthing/syncthing/releases/latest/download/syncthing-linux-${arch}-${version#v}.tar.gz"
    if curl -fLo "$tmpdir/syncthing.tar.gz" "$url"; then
      tar -xzf "$tmpdir/syncthing.tar.gz" -C "$tmpdir"
      sudo install -m 755 "$tmpdir/syncthing-linux-${arch}-${version#v}/syncthing" /usr/local/bin/syncthing
      record_action "SYNCTHING" "${version}"
      echo "Syncthing ${version} installed."
    else
      print_error "Failed to download Syncthing"
    fi
    rm -rf "$tmpdir"
  else
    echo "Skipping Syncthing."
  fi
}

# ============================
# Tailscale
# ============================
install_tailscale() {
  print_message "Installing Tailscale..."
  if command -v tailscale &>/dev/null; then
    echo "Tailscale already installed: $(tailscale --version 2>/dev/null || echo 'version unknown')"
    return 0
  fi
  if confirm "Install Tailscale?"; then
    curl -fsSL https://tailscale.com/install.sh | sh && \
      record_action "TAILSCALE" "installed" && \
      echo "Tailscale installed." || \
      print_error "Failed to install Tailscale (non-fatal)"
  else
    echo "Skipping Tailscale."
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
  install_neovim

  # Phase 4: Editor and shell plugin setup
  print_message "Phase 4: Editor & shell plugins"
  install_neovim_plugins
  install_tmux_plugins
  install_atuin

  # Phase 5: Server tools
  print_message "Phase 5: Server tools"
  install_docker
  install_k3s
  install_node_nvm
  install_syncthing
  install_tailscale

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
