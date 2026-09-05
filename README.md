## Created: 20240223 0101

### Quick Start

1. Clone repo: `git clone git@github.com:idossha/.dotfiles.git`
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

### Verification

The agent platform has one local/CI test entrypoint:

```bash
./agent/tests/run.sh
./agent/scripts/agentctl doctor
```

For a separate Linux container environment and installer syntax smoke check:

```bash
./testing/test_docker.sh test
```

This requires Docker Compose, builds an Ubuntu image and checks tools and shell syntax.
It does not install or uninstall dotfiles. `testing/quick_test.sh` invokes that same check;
the old `work-test` mode is retired because it swallowed failures. For a manual installer
trial, use `build` and `run`, copy the read-only `/workspace` source into a writable directory
inside the disposable container, then follow the installer instructions there. No host Docker
socket is mounted.

---

### Status Bar (SketchyBar + AeroSpace)

`sketchybar/` is stowed to `~/.config/sketchybar`. Left: Apple menu + AeroSpace
workspaces (focused highlighted, empty dimmed). Right: Claude Code and Codex plan usage,
cpu/mem/battery, Amphetamine, GlobalProtect, Docker, Wi-Fi, clock.

Clock, Wi-Fi, Docker, cpu/mem/battery, Claude Code and Codex each open a
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
- The Codex item reads usage through `quota-axi` and caches it at `~/.cache/sketchybar/codex_usage.json`

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

### Dictation (OpenSuperWhisper)

[OpenSuperWhisper](https://github.com/starmel/OpenSuperWhisper) replaces the commercial
superwhisper (`brew install --cask opensuperwhisper`, Apple Silicon, macOS 14+). It runs
whisper.cpp entirely on-device — no account, no network.

- Press **option+space** to start recording, again to transcribe and paste at the cursor
- Settings live in the `ru.starmel.OpenSuperWhisper` defaults domain rather than a text
  config, so there is no stow package. `install/macos_defaults.sh` seeds that domain with
  `defaults write` instead, one key at a time and only when the key is missing — the app
  rewrites the whole domain on quit, so it must be seeded before launch and must never
  stomp a setting changed in the GUI
- The engine is FluidAudio (`parakeet-tdt-0.6b-v3`), not whisper.cpp; the model downloads
  from the onboarding screen into `~/Library/Application Support/FluidAudio/Models`, so
  `whisper-models/` staying empty is expected
- Grant Microphone (prompted on the first recording) and Accessibility in System Settings,
  or the paste step silently no-ops
- `install/macos_defaults.sh` also registers it as a hidden login item

---

### Agent Configuration

Reusable agentic-coding configuration lives under `agent/`:

- `agent/skills/` — canonical skills
- `agent/mcps/mcp-servers.json` — canonical MCP server definitions
- `agent/claude/` — durable Claude settings, statusline, and templates
- `agent/policy/global.md` — global user-level agent policy; idosleep owns memory capture and recall
- `agent/AGENTS.md` — portable agent instructions

Claude Code, Codex and Pi use shared policy and procedures with generated harness adapters.
See [the agent contract](agent/docs/ARCHITECTURE.md) and
[configuration operations](agent/docs/CONFIGURATION.md) for ownership, bootstrap and upgrade checks.

After changes land in the primary checkout:

```bash
./agent/scripts/agentctl sync
./agent/scripts/agentctl doctor
```
