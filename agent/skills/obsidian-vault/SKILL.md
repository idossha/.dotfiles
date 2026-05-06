---
name: obsidian-vault
description: Work safely with an Obsidian vault. Use when creating, editing, linking, reorganizing, or reviewing Markdown notes, frontmatter, wikilinks, tags, canvases, or vault conventions.
---

# Obsidian Vault

Use this skill for direct work in an Obsidian vault.

## Vault Discovery

Default known vault path:

```text
/Users/idohaber/00_development/vault
```

If that path does not exist, inspect Pi settings for `obsidianVault` or ask the user for the vault path.

## Editing Rules

- Preserve existing note style, folder names, heading depth, and frontmatter conventions.
- Prefer Markdown links or wikilinks consistently with the surrounding vault.
- Do not rename or move notes without checking backlinks or user intent.
- Do not overwrite hand-written notes with generated summaries.
- Keep generated sections clearly bounded if updating an existing note.
- Avoid dumping raw logs into notes. Summarize and link to source artifacts instead.

## Frontmatter

Use frontmatter only when the vault already uses it or the user asks for structured metadata.

```yaml
---
type: note
tags:
  - agent-memory
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: agent
---
```

## Link Hygiene

- Use stable note titles.
- Add backlinks only when they carry meaning.
- Prefer one canonical note per concept.
- Search before creating a new note to avoid duplicates.
- Keep aliases in frontmatter when a concept has multiple common names.
- When appending crystallized memory, update the most relevant existing note and add related wikilinks instead of creating an agent-only duplicate.

## Verification

After editing, verify the target files exist, inspect the edited section, and search for duplicate note titles or obvious broken links when relevant.
