## Created: 20240223 0101

Ido Haber
Last update: January 22, 2026

---

### Quick Start

1. Clone repo: `git clone https://github.com/idossha/.dotfiles`
2. cd .dotfiles
3. Run the appropriate installation script for your OS:

---

### Manual Installation (to be automated in the future)

- App store install: Microsoft Office apps
- some macOS setting configs (example, karabiner elements)
- github authentication


---

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

