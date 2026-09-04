# Codex adapter

The shared ownership contract is in [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).
This directory contains Codex-specific policy; sync renders real files under `~/.codex`.

- `config.toml` supplies stable settings and per-tool MCP overrides. Server connection definitions
  come only from `agent/mcps/mcp-servers.json`.
- `rules/default.rules` supplies portable command approvals. Extra local approvals stay in the ignored
  overlay and generated destination.
- Global instructions point to `agent/memory/global.md`; the project map is the repository's
  `AGENTS.md`. Personal and engineering skills are discovered through `~/.agents/skills`.

Generated settings preserve unowned runtime fields, including new provider tables, model preferences,
plugin state, hooks and project trust. Canonical keys win where both exist. Never link a mutable
destination to its tracked policy source. A sync from an unlanded worktree would redirect live links
to temporary paths; sync the canonical checkout after landing.

Use `agentctl doctor` after a harness update and `codex features list` to inspect feature support.
Use `codex exec --help` for current headless flags. An unattended mode is not authority to disable
sandboxing; the GNHF adapter supplies an explicit execution mode.

Discovery and schema references, checked 2026-09-04:
[OpenAI skills](https://learn.chatgpt.com/docs/build-skills),
[configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).
These are compatibility references, not a guarantee about future releases.
