---
name: git-collaboration
description: Collaborate safely with Git and GitHub/GitLab through branches, remotes, PRs, issues, and review discussion. Use when inspecting or changing version-control state or preparing collaboration text; commit grammar, changelogs and releases belong to changelog-release in agentic-rules.
---

# Git Collaboration

Preserve existing work and make the authorized change reviewable.

## Authority and ownership

- Inspect status, staged/unstaged diffs, branch, upstream and remotes before changing Git state.
- Honor authorization already given in the session. Pushes, PRs, issues and messages require applicable
  authorization; do not ask for the same grant again.
- Never reset, clean, rebase, amend, force-push or discard someone else's work without authority for
  that exact action. Keep hooks and signing enabled in interactive workflows.
- Use SSH for configured remotes. Never place credentials in URLs, commits, logs or discussion text.
- Use Treehouse for every agent-owned worktree. The orchestrator that allocated it owns its lifecycle.
- Commit/release grammar, attribution, changelog entries and release scripts have one procedural owner:
  `changelog-release in agentic-rules`. Load it for those tasks, even for a short commit message.
- In an opted-in GNHF run, GNHF owns iteration commits and rollback of its exclusive worktree.
  Do not create competing commits inside its iteration. Review the actual diff and run status after exit.
- Project test commands and CI remain project-owned. Delivery tools invoke them; they do not define a
  second test or release pipeline.

## Working sequence

1. Read project instructions, contribution guidance, templates, protections, and recent history.
2. Split the authorized work into coherent changes. Use the assigned worktree and stage explicit paths.
3. Run the project's required checks, inspect the staged diff for unintended files and secret material,
   and use the changelog-release procedure for commits.
4. Before a push, verify the exact destination and outgoing commits. Existing authorization is enough;
   request a new decision only if the destination or effect exceeds it.
5. Use the available GitHub wrapper (`gh-axi` in this setup) when it supports the operation. Native
   `gh` remains a fallback for unsupported endpoints. Both are clients for the same repository state.
6. Report the commit/branch, verification and any unresolved remote check.

## Collaboration writing

Scale PRs to the change: problem, resulting behavior, verification, and material limitations.
Follow project templates; use `references/templates.md` only when none exists.
Review comments need concrete evidence and a proposed action. Separate confirmed failures from
uncertainties; avoid speculative warnings.

Use structured body arguments or a temporary body file so Markdown keeps real newlines and shell
syntax cannot execute. Never claim a check passed without current evidence.
