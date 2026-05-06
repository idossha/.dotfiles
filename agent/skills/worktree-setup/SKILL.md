---
name: worktree-setup
description: Create git worktree and branch for a new track
disable-model-invocation: true
argument-hint: [track-name]
---

# Worktree Setup Skill

You are setting up a git worktree for a RALF agent track. Follow these steps exactly.

## Step 1: Parse Track Name

The track name is provided in `$ARGUMENTS`. If not provided, ask the user.

## Step 2: Determine Paths

- Get the project root: run `git rev-parse --show-toplevel`
- Get the project directory name: basename of the project root
- Determine the parent directory: dirname of the project root
- Worktree path: `<parent>/<project-name>-<track-name>`
- Branch name: `feature/<track-name>`

## Step 3: Verify Preconditions

Check that:
- The branch `feature/<track-name>` does not already exist: `git branch --list feature/<track-name>`
- The worktree path does not already exist: `ls <worktree-path>`
- The track file exists: `tracks/active/<track-name>.md`

If the branch already exists, ask the user if they want to reuse it or pick a new name.
If the track file does not exist, warn the user and ask if they want to continue anyway.

## Step 4: Create Worktree

Run:
```
git worktree add <worktree-path> -b feature/<track-name>
```

Verify success by checking:
```
git worktree list
```

## Step 5: Open Draft PR (Optional)

Ask the user if they want to open a draft PR now. If yes:

First push the branch:
```
git -C <worktree-path> push -u origin feature/<track-name>
```

Then create the PR:
```
gh pr create --draft \
  --title "[Track] <track-name>: <goal from track file>" \
  --body "Track spec: tracks/active/<track-name>.md" \
  --head feature/<track-name>
```

## Step 6: Print Summary

Output:
```
=== Worktree Ready ===

Worktree path: <worktree-path>
Branch:        feature/<track-name>
Track spec:    tracks/active/<track-name>.md
PR:            <URL or "not created">

To start an agent on this track:
  cd <worktree-path>
  claude "Read tracks/active/<track-name>.md and begin Phase 1"
```
