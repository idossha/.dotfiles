---
name: orchestrator
description: >-
  Parent-agent orchestration rules for Pi subagents: when to scout,
  research, plan, delegate, review, or ask the user. Use for complex
  tasks, multi-file changes, ambiguous requirements, or parallel
  research/implementation.
---

# Orchestrator

Use this skill in the parent Pi session for non-trivial tasks. Keep the parent context clean; delegate exploration and independent work.

## Default loop

1. **Clarify** — ask the user if requirements are ambiguous or a decision changes the implementation.
2. **Scout** — use `subagent` with `scout` for codebase reconnaissance before reading many files yourself.
3. **Research** — use `researcher` or `academic-researcher` for external docs/literature.
4. **Plan** — synthesize evidence into a short implementation/research plan.
5. **Worker** — delegate well-specified edits to `worker` when safe.
6. **Review** — run `reviewer` or `oracle` for correctness, simplicity, and missed assumptions.

## Subagent rules

- Subagents do not inherit all conversation context. Include exact task, constraints, paths, expected output, and relevant prior findings.
- Prefer parallel subagents for independent questions.
- Do not delegate decisions that require user preference; ask the user.
- Use `pi-intercom`/supervisor contact if a child is blocked and needs a decision.
- For risky work, ask `oracle` for critique before editing.

## When not to delegate

- Single-file targeted edits where you already know the location.
- Simple commands or one-line lookups.
- Tasks requiring live back-and-forth with the user.

## Parent context hygiene

- Do not read large files just to explore. Send `scout`.
- Read directly only to verify exact lines before editing or to inspect final diffs.
- Keep final answers grounded in evidence: file paths, command output, URLs, paper IDs, and validation results.
