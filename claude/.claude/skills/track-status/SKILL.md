---
name: track-status
description: Summarize progress of all active tracks
disable-model-invocation: true
---

# Track Status Skill

You are generating a dashboard of all active RALF tracks. Follow these steps exactly.

## Step 1: Read All Active Tracks

Use glob to find all files matching `tracks/active/*.md`.
Read each file and extract:
- **Track name**: from the `# Track:` heading
- **Status**: from the `**Status:**` field (PLANNING, IN PROGRESS, REVIEW, DONE)
- **Total phases**: count all `## Phase N:` headings (exclude Quality Gates from the count, but note it)
- **Current phase**: determine by looking for:
  - Unchecked checkboxes `- [ ]` vs checked `- [x]` in acceptance criteria
  - Status markers like "DONE", "COMPLETE", "IN PROGRESS" within phases
  - If no markers exist, assume Phase 1 is current

## Step 2: Check Git Branches

Run:
```
git branch -a | grep feature/
```

Map each branch to its corresponding track. Note any tracks without branches and any branches without tracks.

## Step 3: Check Open PRs

Run:
```
gh pr list --state open
```

Map PRs to tracks by branch name or title pattern `[Track]`.

## Step 4: Read Agent State

If `memory/agent-state.md` exists, read it and extract:
- Which track the last agent was working on
- What phase was completed
- Any blockers or open questions noted

## Step 5: Output Dashboard

Print a formatted table like this:

```
=== RALF Track Dashboard ===

| Track               | Status      | Phases | Current | Branch              | PR   | Blockers |
|---------------------|-------------|--------|---------|---------------------|------|----------|
| feature-name        | IN PROGRESS | 4+QG   | 2       | feature/feat-name   | #42  | None     |
| other-feature       | PLANNING    | 3+QG   | 1       | (none)              | --   | None     |
```

After the table, add a summary section:
- Total active tracks
- Tracks blocked or stalled
- Agent state summary (last active track, last phase completed)
- Any branches with no matching track file (orphaned branches)
- Any track files with no branch (not yet started)
