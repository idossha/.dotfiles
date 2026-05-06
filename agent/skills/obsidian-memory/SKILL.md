---
name: obsidian-memory
description: Update the user's Obsidian vault as a curated long-term memory base for agent work. Use when saving decisions, durable project knowledge, research summaries, or cross-session agent memory into Obsidian.
disable-model-invocation: true
argument-hint: "[topic]"
---

# Obsidian Memory

Use this skill to save curated crystallized knowledge into Obsidian.

## Default Position

Obsidian is the right memory base for human-readable, durable knowledge:

- decisions and rationale
- project summaries
- research notes
- recurring patterns and gotchas
- links between people, projects, papers, repos, and ideas

SQLite is better for machine-readable memory:

- raw session logs
- many small timestamped events
- embeddings or retrieval indexes
- task/status tables
- audit trails and metrics

Use a hybrid when both are needed: write curated summaries to Obsidian and keep raw/query-heavy data in SQLite.

## Vault Path

Default known vault:

```text
/Users/idohaber/00_development/vault
```

Crystallized notes go under:

```text
/Users/idohaber/00_development/vault/Zettelkasten
```

If missing, inspect `~/.pi/agent/settings.json` for `obsidianVault`.

## Update Flow

1. Ask what should be remembered if the topic/content is not explicit.
2. Search `Zettelkasten/` for an existing note on the topic.
3. Prefer updating an existing canonical note over creating a duplicate.
4. Link the target note to related notes using wikilinks.
5. Add concise, source-linked content.
6. Include the date only when chronology matters.
7. Do not store secrets, credentials, private personal data, or raw transcripts.
8. Report the note path and the exact memory added.

## CLI

Prefer the low-friction CLI for simple writes:

```bash
~/.dotfiles/agent/scripts/remember crystal --topic "Topic" --message "Durable note"
```

The CLI searches existing Zettelkasten notes, updates a strong existing match instead of creating a duplicate, and adds related wikilinks when relevant.

Use direct editing only when the note needs substantial restructuring or the automatic match is ambiguous.

## Suggested Structure

For agent memory, prefer existing `Zettelkasten/` notes. If no concept note exists, create one there rather than making a separate agent-only silo.

```text
Agent Memory/
  Index.md
  Projects/
  Research/
  Decisions/
  Patterns/
```

Create folders only when needed.
