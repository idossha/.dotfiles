# Unified Skills

This directory is the canonical source for reusable agent skills.

## Layout

```text
agent/skills/
  <skill-name>/
    SKILL.md
    references/
    scripts/
    templates/
```

`SKILL.md` must start with YAML frontmatter:

```yaml
---
name: <skill-name>
description: Specific trigger-oriented description.
---
```

The `name` must match the directory name. Keep descriptions focused on routing:
what the skill does and when an agent should load it.

## Harness Links

Run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh
```

The sync script creates these links:

```text
~/.claude/skills -> ~/.dotfiles/agent/skills
~/.pi/agent/skills -> ~/.dotfiles/agent/skills
~/.codex/skills/<skill-name> -> ~/.dotfiles/agent/skills/<skill-name>
```

Codex is linked per skill so `~/.codex/skills/.system` remains available.

## Validation

Run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh --check
```

This verifies that each skill has a `SKILL.md`, a matching frontmatter `name`,
and a frontmatter `description`.
