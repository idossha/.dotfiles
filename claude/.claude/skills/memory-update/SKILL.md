---
name: memory-update
description: Update project memory files with new learnings
disable-model-invocation: true
---

# Memory Update Skill

You are updating the project's persistent memory files. Follow these steps exactly.

## Step 1: Find the Memory File

The project auto-memory file is at the path shown in the system context under "user's auto-memory". It typically lives at:
```
~/.claude/projects/<project-path-encoded>/memory/MEMORY.md
```

Read this file to understand the current contents.

## Step 2: Ask What to Change

Ask the user:
1. **What to add?** — New learnings, patterns, gotchas, completed tracks
2. **What to update?** — Corrections to existing entries
3. **What to remove?** — Stale or incorrect information

Wait for the user's response before proceeding.

## Step 3: Check for Duplicates

Before adding anything:
- Search the existing MEMORY.md for similar content
- If a duplicate or near-duplicate exists, ask the user if they want to update the existing entry or add a new one
- Do NOT add redundant information

## Step 4: Check Size

Count the current number of lines in MEMORY.md.
- If adding new content would push it over 200 lines, suggest:
  - Moving a large section to a separate topic file (e.g., `~/.claude/projects/<path>/memory/gui-patterns.md`)
  - Linking to it from MEMORY.md with a brief summary
  - Pruning outdated entries to make room
- Ask the user which approach they prefer

## Step 5: Organize by Topic

MEMORY.md should be organized by topic sections, NOT chronologically. Standard sections include:
- Completed Tracks
- API Import Pattern
- Architecture/Design Patterns
- Module-specific notes (Logger, GUI, Tests, etc.)
- Critical Gotchas
- Current date / status

When adding new content, place it in the appropriate existing section or create a new section if none fits.

## Step 6: Show Diff Before Saving

Present the proposed changes to the user as a clear before/after diff:
```
--- CHANGES ---
Section: <section name>
- Removed: <old content> (if applicable)
+ Added: <new content>
```

Ask for confirmation: "Apply these changes? (yes/no)"

## Step 7: Save

Only after user confirmation, write the updated MEMORY.md.

Do NOT commit — memory files are in the user's Claude config, not in the git repo.

Print confirmation of what was changed.
