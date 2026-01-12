## Created: 20240223 0101

Ido Haber
Last update: January 12, 2026

---

### Quick Start

1. Clone repo: `git clone https://github.com/idossha/.dotfiles`
2. cd .dotfiles
3. Run the appropriate installation script for your OS:

   **macOS:**
   ```bash
   ./install/apple_install.sh
   ```

   **Linux Desktop/Server (with sudo access):**
   ```bash
   ./install/linux_install.sh desktop    # Full installation with GUI apps
   ./install/linux_install.sh server     # Server installation without GUI apps
   # or just ./install/linux_install.sh (defaults to desktop)
   ```

   **Linux Work Server (no sudo access):**
   ```bash
   ./install/linux_work_install.sh       # Personal config only, uses server-optimized configs
   ```

### Available Scripts

- `install/apple_install.sh` - Full macOS installation with all tools and GUI applications
- `install/linux_install.sh` - Linux installation with sudo (accepts `desktop` or `server` argument)
- `install/linux_work_install.sh` - Linux work server installation (no sudo, uses server configs)
- `install/apple_uninstall.sh` - Uninstall macOS installation
- `install/linux_uninstall.sh` - Uninstall Linux installation

### What Gets Installed

#### Common (macOS & Linux)
- GNU Stow for dotfile management
- Neovim (compiled from source)
- Tmux with plugins
- Development tools (git, ripgrep, fzf, etc.)
- Shell configurations (zsh/bash)

#### macOS Specific
- Homebrew package manager
- GUI applications (Ghostty, Keyboard Clean Tool, etc.)
- Oh My Zsh with plugins
- macOS-specific tools

#### Linux Specific (with sudo)
- APT package manager updates and packages
- Desktop: Ghostty terminal (via snap)
- Server: Skips GUI applications
- Font installations
- Optional tools (lazygit, lazydocker, Atuin)

#### Linux Work Server (no sudo)
- Personal dotfile configuration via GNU Stow
- **Uses server_config/** for nvim and tmux (lighter, server-optimized configs)
- Creates symlinks: `~/.config` → `server_config/config` and `~/.tmux.conf` → `server_config/config/.tmux.conf`
- Neovim compiled to ~/.local/bin
- Font downloads to ~/.local/share/fonts
- Tmux plugins in home directory and config automatically sourced
- Assumes basic tools (git, tmux, etc.) are pre-installed

---

### Docker Testing (for Linux Server Testing)

Test the Linux server installation in a Docker container:

```bash
# Quick test - build and run automated test
./testing/test_docker.sh test

# Or build and run interactively
./testing/test_docker.sh build
./testing/test_docker.sh run

# Inside container, test manually:
# ./install/linux_install.sh server
# ./install/linux_uninstall.sh
```

**Quick validation (fast, ~2 seconds):**
```bash
./testing/quick_test.sh
```

The Docker setup provides a clean Ubuntu environment to test:
- Linux server installation (no GUI apps)
- Installation/uninstallation process
- Package dependencies
- Configuration management

**Note:** The full test may take several minutes on ARM64 systems due to package compilation.

---

### Manual Installation (Alternative)

Command line: Brew install, Git install

Applications from web: Arc, Docker Desktop, Raycast, Zoom, Slack, Cursor, Karabiner Elements

Git clone

Bash install.sh (old unified script)

App store install: Outlook


---
# Development Notes:

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Clone zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Clone zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

