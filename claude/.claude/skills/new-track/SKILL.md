---
name: new-track
description: Create a new RALF agent track from template
disable-model-invocation: true
argument-hint: [feature-name]
---

# New Track Skill

You are creating a new RALF agent track. Follow these steps exactly.

## Step 1: Parse Feature Name

The feature name is provided in `$ARGUMENTS`. Convert it to kebab-case for file/branch naming.
If no feature name was provided, ask the user for one before proceeding.

## Step 2: Ask Clarifying Questions

Before designing anything, ask the user these questions and wait for answers:

1. **Goal**: What should this track deliver? What problem does it solve?
2. **Modules**: Which parts of the codebase are affected? (e.g., `tit/sim/`, `tit/opt/`, GUI, CLI)
3. **Constraints**: Any technical constraints, deadlines, or compatibility requirements?
4. **Scope**: Is this a new feature, a refactor, a bugfix, or an enhancement?
5. **Dependencies**: Does this depend on any other track or external change?

Do NOT proceed until the user has answered.

## Step 3: Read Relevant Source Files

Based on the user's answers:
- Read the files/modules they mentioned to understand current state
- Check `tracks/active/` for any related or conflicting tracks
- Read `memory/agent-state.md` if it exists for in-progress context
- Read `CLAUDE.md` for project conventions

## Step 4: Design the Track

Using the template at `~/.claude/templates/track-template.md` as your format reference, design the track:

- **Phases**: Break the work into phases. Each phase must:
  - Touch at most 3-5 files
  - Be completable by a fresh agent with limited context
  - Build on the previous phase
- **Tasks**: Each task must be specific and testable (not vague like "refactor module")
- **Final phase**: Always "Quality Gates" with: tests pass, black formatting, no regressions, PR description, memory updated
- **File lists**: Use exact paths relative to project root

## Step 5: Write the Track File

Write the completed track to `tracks/active/<feature-name>.md`.

Set the initial status to `PLANNING`.
Set the Created date to today's date.
Set the Branch to `feature/<feature-name>`.

## Step 6: Create the Branch

Run:
```
git checkout -b feature/<feature-name>
```

Then confirm to the user:
- Track file location
- Branch name
- Number of phases
- Ask if they want to adjust anything before agents start work
