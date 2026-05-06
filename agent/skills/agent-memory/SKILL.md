---
name: agent-memory
description: Decide where agent memory belongs and update durable memory safely. Use for global memory, project memory, Obsidian-backed memory, session notes, and pruning stale or sensitive memory.
disable-model-invocation: true
---

# Agent Memory

Use this skill when the user asks to remember, forget, summarize, centralize, or reorganize agent memory.

## Storage Layers

- **Global memory:** `~/.dotfiles/agent/memory/global.md`
- **Portable instructions:** `~/.dotfiles/agent/AGENTS.md`
- **Project memory:** project-local `AGENTS.md`, `CLAUDE.md`, `memory/`, or docs
- **Obsidian memory:** crystallized knowledge in `/Users/idohaber/00_development/vault/Zettelkasten`
- **SQLite memory:** raw logs, session events, telemetry, indexes, and high-volume machine-readable memory
- **Runtime state:** sessions, logs, todos, caches, auth, managed jobs

Do not centralize or commit runtime state as Markdown memory.

## What Belongs Where

- Put personal preferences and stable cross-repo habits in global memory.
- Put build/test commands, architecture, and current project context in project Markdown.
- Put research summaries, decisions, and reusable knowledge in the Obsidian Zettelkasten.
- Put raw events, high-volume telemetry, embeddings, or query-heavy data in SQLite.
- Do not store secrets, tokens, private keys, credentials, or sensitive personal data.

## Update Process

1. Identify the target memory layer.
2. Read the existing memory first.
3. Check for duplicates or stale contradictory entries.
4. Write a concise topic-oriented update, not a chronological transcript.
5. Preserve links to source files, issues, papers, or commands when useful.
6. Report the changed file and the exact memory added or updated.

## Obsidian vs SQLite

Use Obsidian when the memory is curated knowledge a human should browse, edit, and connect.

Use SQLite when the memory is structured, high-volume, frequently queried, or produced automatically.

Prefer a hybrid for agent memory: Obsidian for durable summaries and decisions; SQLite for raw session events, extracted metadata, retrieval indexes, and audit trails.

## CLI

Use:

```bash
~/.dotfiles/agent/scripts/remember crystal --topic "Topic" --message "Durable note"
~/.dotfiles/agent/scripts/remember project --topic "Topic" --message "Project-specific note"
~/.dotfiles/agent/scripts/remember raw --topic "event" --message "Raw event"
```

The `crystal` mode searches existing Zettelkasten notes, appends to a strong existing match, and adds related wikilinks automatically.
