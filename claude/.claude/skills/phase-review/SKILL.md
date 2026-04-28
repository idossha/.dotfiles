---
name: phase-review
description: Review a completed phase against its track specification
disable-model-invocation: true
argument-hint: [track-name] [phase-number]
---

# Phase Review Skill

You are reviewing a completed phase of a RALF agent track. Follow these steps exactly.

## Step 1: Parse Arguments

`$ARGUMENTS` contains the track name and phase number, e.g., `mti-optimizer 3`.
- First token: track name (used to find `tracks/active/<track-name>.md`)
- Second token: phase number (integer)

If either is missing, ask the user.

## Step 2: Read the Track Spec

Read `tracks/active/<track-name>.md` and extract the specified phase section:
- **Files** listed for the phase
- **Tasks** listed for the phase
- **Acceptance criteria** for the phase

## Step 3: Get the Actual Changes

Run these commands to understand what changed:
```
git diff main...HEAD --name-only
git diff main...HEAD --stat
git log main..HEAD --oneline
```

If the branch is not ahead of main, fall back to checking recent commits:
```
git log --oneline -10
git diff HEAD~N..HEAD --name-only
```
where N is a reasonable number of commits for one phase.

## Step 4: Compare Spec vs Reality

Check each criterion:

### 4a. Files Coverage
- Were ALL files listed in the phase spec actually modified?
- Were any UNSPECIFIED files modified? (Flag these — they may be acceptable but need justification)

### 4b. Task Completion
- For each numbered task in the spec, determine if it was completed based on the diff
- Note any tasks that appear incomplete or skipped

### 4c. Acceptance Criteria
- Evaluate each acceptance criterion from the phase spec

## Step 5: Run Quality Checks

Run tests if available:
```
python -m pytest --tb=short -q 2>&1 | tail -20
```

Check formatting:
```
black --check tit/ 2>&1 | tail -10
```

If either command fails, note it but continue the review.

## Step 6: Report Results

Output a structured report:

```
=== Phase Review: <track-name> Phase <N> ===

VERDICT: PASS | FAIL | PARTIAL

## Files
- [x] path/to/expected_file.py (modified)
- [ ] path/to/missed_file.py (NOT modified)
- [!] path/to/unexpected_file.py (modified but not in spec)

## Tasks
- [x] Task 1 description — completed
- [ ] Task 2 description — NOT completed (reason)
- [~] Task 3 description — partially completed (details)

## Acceptance Criteria
- [x] Criterion 1 — met
- [ ] Criterion 2 — not met (details)

## Quality Checks
- Tests: PASS (132/132) | FAIL (details)
- Formatting: CLEAN | DIRTY (N files)

## Notes
- Any deviations, concerns, or recommendations
```

If the verdict is FAIL, list what must be fixed before the phase can be considered complete.
