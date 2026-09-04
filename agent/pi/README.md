# Pi Adapter

This directory contains only Pi-specific settings, extensions, and subagent definitions. Portable
instructions, skills, MCP declarations, engineering doctrine, and project facts live elsewhere so Pi,
Claude Code, and Codex receive the same policy.

## Ownership

| Path | Purpose |
|---|---|
| `settings.json` | Stable Pi defaults and exact package pins |
| `extensions/` | Pi event-loop integrations that cannot be expressed portably |
| `agents/` | Pi-subagents role definitions |
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

## Subagents

Files in `agents/` are read by `pi-subagents`. Tool lists are strict allowlists; remove names no installed
package provides. Use project/global context inheritance deliberately, and prefer shared skills over
embedding multi-step engineering procedures in role prompts.

FirstMate is the cross-harness fleet supervisor. Pi subagents remain useful for small, in-session
delegation; they are not a second project/worktree orchestrator.

## Verification

```bash
node agent/scripts/pi-resources.mjs
agent/scripts/agentctl doctor
agent/tests/run.sh
```

`pi -p` reads stdin until EOF. Redirect scripted print-mode runs from `/dev/null` unless piped content is
intentional, or an open stdin can make the process hang.
