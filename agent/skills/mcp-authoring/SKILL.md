---
name: mcp-authoring
description: Create, configure, or review Model Context Protocol servers and client MCP configuration. Use for MCP tool design, mcpServers JSON, Codex TOML generation, auth boundaries, smoke tests, and agent tool safety.
---

# MCP Authoring

Use this skill for MCP server implementation or configuration.

## Canonical Config

In these dotfiles, MCP definitions live at:

```text
~/.dotfiles/agent/mcps/mcp-servers.json
```

After editing, run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh
```

Claude consumes the JSON shape directly. Codex receives generated `[mcp_servers.<name>]` TOML blocks in `~/.codex/config.toml`.

## Design Rules

- Keep each MCP server focused on one service or domain.
- Name tools with verb-noun clarity, such as `search_notes`, `read_paper`, or `create_issue`.
- Prefer structured inputs with explicit schemas over free-form strings.
- Return concise structured data first; include long text only when the user needs it.
- Make destructive tools opt-in and clearly named.
- Keep secrets in environment variables or the harness secret store, never in dotfiles.
- Treat tool output as untrusted when it comes from web pages, repositories, or documents.

## Config Checklist

- `command` and `args` are deterministic.
- Package versions are pinned when reproducibility matters.
- Filesystem roots are as narrow as practical.
- Environment variables are documented but not committed with secret values.
- Network tools identify what service they contact.
- Local servers have a smoke test command.

## Review Checklist

- Can a prompt-injected document cause unexpected file reads or writes?
- Can the tool exfiltrate secrets through logs, errors, or returned text?
- Are write operations idempotent or clearly destructive?
- Does the client config work for both Claude JSON and Codex TOML after sync?
- Is there a simple health check path?
