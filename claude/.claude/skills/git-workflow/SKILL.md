---
name: git-workflow
description: Git branching, commit, and PR best practices. Use when performing git operations.
user-invocable: false
---

# Git Workflow Standards

## Branch Naming

- `feature/<name>` — new functionality
- `fix/<name>` — bug fixes
- `docs/<name>` — documentation only
- `refactor/<name>` — code restructuring with no behavior change
- Use kebab-case: `feature/add-user-auth`, not `feature/addUserAuth`

## Commit Messages

- **Imperative mood** in subject: "Add feature" not "Added feature" or "Adds feature"
- **Max 72 characters** in subject line
- **Why > what**: the diff shows *what* changed; the message explains *why*
- Blank line between subject and body
- Body wraps at 72 characters

```
Add retry logic for flaky API connections

The payment gateway occasionally returns 503 during peak hours.
Retry up to 3 times with exponential backoff before failing.
```

## Atomic Commits

- **One concern per commit**: a commit should be independently revertable
- Don't mix formatting changes with logic changes
- Don't mix refactoring with new features
- If you need to refactor to enable a feature, refactor in commit 1, add feature in commit 2

## Before Committing

- Always run `git status` to see what will be committed
- Always run `git diff` (staged and unstaged) to review changes
- **Stage specific files** by name, not `git add -A` or `git add .`
  - Prevents accidentally committing `.env`, credentials, build artifacts, large binaries
- Never skip hooks with `--no-verify` — if a hook fails, fix the underlying issue
- Never bypass signing with `--no-gpg-sign`

## Commit Discipline

- **Prefer new commits over amending**: `git commit --amend` rewrites history and is dangerous after hook failures (the failed commit never happened, so amend modifies the *previous* commit)
- After a pre-commit hook failure: fix the issue, re-stage, create a NEW commit
- Only amend when explicitly intended and the commit hasn't been pushed

## Pull Requests

- **One concern per PR**: don't bundle unrelated changes
- **Keep PRs reviewable**: aim for <400 lines changed. Split large changes into stacked PRs
- **Descriptive body** with structured sections:
  ```markdown
  ## Summary
  - What changed and why (2-3 bullets)

  ## Test Plan
  - How to verify the changes work
  ```
- Link to relevant issues
- PR title: short, imperative (`Add user authentication endpoint`)

## Branch Management

- **Never force-push shared branches** (main, develop, release/*)
- **Rebase local feature branches** before opening a PR to keep history clean
- Delete merged branches promptly
- Use `git worktree add` for parallel work on multiple branches:
  ```bash
  git worktree add ../project-feature feature/my-feature
  ```

## Merge Strategy

- Prefer merge commits or squash-merge for PRs (preserves PR context)
- Rebase for local branch cleanup before PR
- Never rebase commits that others have based work on

## Safety Rules

- Never `git reset --hard` without confirming intent — it destroys uncommitted work
- Never `git push --force` to main/master
- Never `git checkout .` or `git restore .` without reviewing what will be lost
- Use `git stash` to save work-in-progress before switching contexts
