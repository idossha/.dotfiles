---
name: phase-handoff
description: Prepare handoff context for the next RALF agent
disable-model-invocation: true
argument-hint: [track-name] [completed-phase]
---

# Phase Handoff Skill

You are preparing a handoff document so the next RALF agent can pick up where the previous one left off. Follow these steps exactly.

## Step 1: Parse Arguments

`$ARGUMENTS` contains the track name and completed phase number, e.g., `mti-optimizer 2`.
- First token: track name
- Second token: completed phase number (integer)

If either is missing, ask the user.

## Step 2: Read the Track Spec

Read `tracks/active/<track-name>.md` and extract:
- The completed phase (Phase N) — what was supposed to happen
- The next phase (Phase N+1) — what comes next
- The overall goal — for context

## Step 3: Analyze What Actually Changed

Run:
```
git log main..HEAD --oneline
git diff main...HEAD --stat
git diff main...HEAD --name-only
```

Summarize:
- Which files were created, modified, or deleted
- Key decisions visible in the diff (e.g., chose approach A over B)
- Any TODO/FIXME/HACK comments added

## Step 4: Identify Deviations

Compare the track spec for the completed phase against the actual changes:
- Tasks completed as specified
- Tasks skipped or deferred
- Extra work done beyond the spec
- Files touched that were not in the spec

## Step 5: Write Agent State

Create or update `memory/agent-state.md` with this format:

```markdown
# Agent State

**Track:** <track-name>
**Last completed phase:** <N>
**Date:** <today>
**Branch:** feature/<track-name>

## What Was Done (Phase <N>)
- [Bullet points of actual changes]
- [Key decisions made and why]

## Deviations from Spec
- [Any differences from the track file, or "None"]

## Context for Next Agent
- [Important things the next agent needs to know]
- [Any gotchas, edge cases, or non-obvious state]
- [Relevant file paths and their roles]

## Open Questions / Blockers
- [Anything unresolved, or "None"]

## Next Phase Summary
Phase <N+1>: <phase name>
- [Brief list of what Phase N+1 requires]
- [Which files will be touched]
```

## Step 6: Commit the State Update

Stage and commit:
```
git add memory/agent-state.md
git commit -m "chore: update agent state after Phase <N> of <track-name>"
```

## Step 7: Print Handoff Summary

Output a brief summary to the user:
```
=== Handoff Complete ===

Track:           <track-name>
Completed:       Phase <N>
Next:            Phase <N+1>: <phase name>
Agent state:     memory/agent-state.md (committed)
Branch:          feature/<track-name>

To start the next agent:
  claude "Read tracks/active/<track-name>.md and memory/agent-state.md, then begin Phase <N+1>"
```
