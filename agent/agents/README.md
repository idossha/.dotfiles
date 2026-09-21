# Claude Code Subagents

Canonical source for Claude Code subagent definitions. `agent/scripts/sync-agent-config.sh` links each
`<name>.md` here to `~/.claude/agents/<name>.md`; the discovery root stays a real directory so
user-authored or project agents can live beside them. Only Claude Code reads these; Codex and Pi have
their own delegation adapters under `agent/codex/` and `agent/pi/`.

## Roster

Each role ships in two tiers. Pick the cheaper one when the spec is concrete; escalate when the task
carries ambiguity, design decisions, or many files.

| Role | Opus (capable) | Sonnet (nimble) | Writes files |
|---|---|---|---|
| Research | `researcher-opus` | `researcher-sonnet` | no |
| Build | `builder-opus` | `builder-sonnet` | yes |
| Refactor | `refactorer-opus` | `refactorer-sonnet` | yes |

Invoke with the Agent tool (`subagent_type: "builder-sonnet"`) or by asking Claude Code to hand off to
one by name.

## Authoring rules

- Frontmatter needs `name` (matching the filename), `description` (when to pick it over its sibling
  tier), and `model` set to `opus` or `sonnet`. Omit `tools` to inherit everything; read-only agents
  list an explicit allowlist.
- The body is the agent's system prompt. Keep it under forty lines: ground rules, then the report
  format, because the caller only sees the final message.
- After changing a file here, run `agent/scripts/sync-agent-config.sh --check`, then
  `agent/scripts/agentctl sync` from the primary checkout.
