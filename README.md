## Created: 20240223 0101

### Quick Start

1. Clone repo: `git clone https://github.com/idossha/.dotfiles`
2. cd .dotfiles
3. Run the appropriate installation script for your OS:

---

### Manual Installation (to be automated in the future)

- App store install: Microsoft Office apps, WireGuard, Keymap (zsa), Windows Desktop
- some macOS setting configs (example, karabiner elements)
- mouse speed, dock setting,
- github authentication via SSH pub key
- Download GlobalProtect via https://uwmadison.vpn.wisc.edu/global-protect/getsoftwarepage.esp

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

---

### Status Bar (SketchyBar + AeroSpace)

`sketchybar/` is stowed to `~/.config/sketchybar`. Left: Apple menu + AeroSpace
workspaces (focused highlighted, empty dimmed). Right: Claude Code plan usage,
cpu/mem/battery, Amphetamine, GlobalProtect, Docker, Wi-Fi, clock.

Clock, Wi-Fi, Docker, cpu/mem/battery and the Claude Code item each open a
details popup. Popups are read-only: their rows are plain text, with no click
targets and no hover highlight. Clicking an item opens or closes its popup,
except Amphetamine
(click toggles a keep-awake session) and GlobalProtect (click opens the app).

- Runs as a launchd service: `brew services start sketchybar`
- `install/macos_defaults.sh` hides the native menu bar and sets the Mission Control
  options AeroSpace needs (run by `apple_install.sh`, safe to re-run)
- Edit `~/.config/sketchybar/colors.sh` / `icons.sh` for theming; `sketchybar --reload`
- The Claude Code item reads `~/.cache/sketchybar/claude_usage.json`, which
  `agent/claude/statusline-command.sh` writes on every statusline render — the plan
  limits are only exposed there, so with no session open the numbers go stale (the
  item dims after 6h)
- `~/.config/sketchybar/tests/run_tests.sh` smoke-tests every item against the live bar

---

### Launcher (Vicinae)

[Vicinae](https://github.com/vicinaehq/vicinae) replaces Raycast (`brew install --cask vicinae`,
Apple Silicon only). `vicinae/` is stowed to `~/.config/vicinae` and
`~/.local/share/vicinae/themes`.

- Toggle with `alt+space`; vim keybinding scheme; ⌘K action panel, ⌘, settings
- `settings.json` is what the GUI writes to; curated config lives in `base.json` (imported)
- Theme `tokyo-sketchy` matches the SketchyBar palette; `vicinae theme set <id>` to switch
- Grant Accessibility + Input Monitoring in System Settings for paste-to-window / snippets
- `vicinae server` restarts the daemon, `vicinae logs` shows what it loaded

---

### Agent Configuration

Reusable agentic-coding configuration lives under `agent/`:

- `agent/skills/` — canonical skills
- `agent/mcps/mcp-servers.json` — canonical MCP server definitions
- `agent/claude/` — durable Claude settings, statusline, and templates
- `agent/memory/global.md` — global user-level agent memory
- `agent/AGENTS.md` — portable agent instructions

Claude Code is the only harness in use; retired Codex and Pi config lives under
`deprecated/` and is not synced.

Sync `~/.claude` links/config after changes:

```bash
./agent/scripts/sync-agent-config.sh
```
