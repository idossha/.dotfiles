# Pi Adapter

This directory contains only Pi-specific settings, extensions, and prompt templates. Portable
instructions, skills, MCP declarations, engineering doctrine, and project facts live elsewhere so Pi,
Claude Code, and Codex receive the same policy.

## Ownership

| Path | Purpose |
|---|---|
| `settings.json` | Stable Pi defaults and exact package pins |
| `extensions/` | Pi event-loop integrations that cannot be expressed portably |
| `prompts/` | Pi-only prompt templates |

The sync layer supplies global instructions, personal/domain skills, the separate agentic-rules skills,
and MCP servers from `agent/mcps/mcp-servers.json`. Runtime fields come from untracked overlays or
generated effective settings.

Do not add a second skills array or MCP declaration here: duplicate discovery can load conflicting tools
and instructions. Do not store project trust, auth, themes, changelog cursors, or session state in tracked
settings: Pi writes those values at runtime and would dirty the dotfiles repository.

## Packages and Extensions

Package references are exact pins. Installation is explicit through `agent/scripts/install-agent-tools.sh`;
syncing configuration does not execute downloaded code.

Local extensions should exist only when Pi's event loop is required. Treehouse owns worktree allocation;
session creation, health checks, upstream installs, FirstMate, bounded GNHF, and no-mistakes launches
belong in `agentctl` so every harness can use the same surface.

Herdr's generated `herdr-agent-state.ts` remains machine state and is ignored from `agent/pi/.gitignore`.
Do not put an ignore file inside `extensions/`: Pi honors it during discovery and would hide the Herdr
integration itself.

## Delegation

FirstMate is the cross-harness fleet supervisor. `agentctl fleet --harness pi` refreshes Herdr's Pi
integration before starting Pi from the FirstMate checkout and seeds FirstMate with the managed
`no-mistakes +yolo` project defaults from `agent/projects.json`. If Pi does not load the FirstMate
extensions, run `/trust` in that Pi session, approve the project, quit, and restart through
`agentctl fleet`. Pi's native subagent tools remain available when an interactive session explicitly
chooses them, but this adapter no longer ships custom Pi subagent role prompts.

## Verification

```bash
herdr integration install pi
herdr integration status
node agent/scripts/pi-resources.mjs
agent/scripts/agentctl doctor
agent/tests/run.sh
```

`pi -p` reads stdin until EOF. Redirect scripted print-mode runs from `/dev/null` unless piped content is
intentional, or an open stdin can make the process hang.


## Package guidance and native discovery

Treehouse owns worktrees and FirstMate owns persistent fleet supervision when selected. The
pi-subagents and pi-interactive-shell packages load their extensions but exclude bundled skills
through Pi's documented package filters, because those guides introduce alternate supervision and
worktree defaults. Read installed package help for mechanics when the chosen task needs them.

`node agent/scripts/pi-resources.mjs` probes the local CLI through offline RPC without a model
prompt or TUI. It reports available commands/skills and their source paths, not complete extension
diagnostics or project-context loading. This avoids the Pi 0.85.0 SDK's missing experimental server
dependency. Other versions must still satisfy the observed RPC response contract.
