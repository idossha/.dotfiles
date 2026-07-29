---
name: orchestrator
description: >-
  When to delegate work to Claude Code subagents and, more often, when not to.
  Use for multi-file changes, broad codebase reconnaissance, or several
  independent questions that can be answered in parallel.
---

# Orchestrator

Delegation is a context-budget tool, not a quality tool. Doing the work yourself is the default; spawn a subagent only when handling it inline would flood the parent context.

Subagents are launched with the Agent tool.

## Subagent types

- `Explore` — read-only reconnaissance: locate files, map call sites, answer "where/how does X work".
- `Plan` — turn gathered evidence into an implementation plan you will execute yourself.
- `general-purpose` — a self-contained unit of work that needs both reading and editing.

## Do not spawn a subagent

- For work that finishes in a handful of tool calls, or when you already know the file and line.
- To verify, double-check, or re-review work you already did.
- For anything that needs live back-and-forth with the user.
- To settle a decision that depends on user preference — ask the user instead.

## When you do delegate

- Send all independent agents in **one message** so they run concurrently. Spawning them one per message serializes work that had no dependency.
- Subagents inherit none of the conversation. Give each the exact task, constraints, absolute paths, relevant prior findings, and the output shape you expect back.
- One agent, one question. Do not chain dependent steps through a single agent.
- Cap the fan-out at what you can actually merge; a wide fan-out you then skim is worse than three agents you read.

## Parent context hygiene

- Delegate broad exploration. Read files directly when you need the exact lines you are about to edit, or the diff you are about to report.
- Keep the final answer grounded in evidence: file paths, command output, URLs, validation results.
