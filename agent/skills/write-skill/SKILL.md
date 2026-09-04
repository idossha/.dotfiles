---
name: write-skill
description: Create, refactor, or audit a reusable personal or domain skill shared across coding harnesses. Use for skill boundaries, triggers, supporting resources, and discovery; delegate provider-specific packaging to that provider's current authoring tools.
---

# Write Skill

Author one portable procedure and verify how each intended harness discovers it.

## Ownership

Personal and domain skills belong in `agent/skills/<name>/` in the dotfiles checkout assigned to
the task. Cross-project engineering procedures belong in the separate `agentic-rules` repository.
When work is isolated, edit only the allocated worktree; an installed skill path can point at another
checkout and is a reading location, not an editing instruction.

Use the provider's bundled skill creator for provider-specific packaging when available. This skill
owns the shared content and placement. Do not duplicate the creator's evolving schema or defaults here.

## Procedure

1. Read the existing inventory and the nearest related skills. State the task this skill owns, the
   neighboring owner it routes to, and the concrete failure duplication would cause.
2. Infer scope and defaults from the request. Reuse existing authorization; ask only for a missing
   decision that materially changes the work.
3. Write minimal frontmatter: `name` matching the directory and a specific `description` naming
   triggering tasks and near misses. A broad subject keyword alone is insufficient.
4. Write a short procedure: inputs, steps, verification, completion condition, and owner handoffs.
   Keep project facts in project `AGENTS.md`/docs and durable insight in the memory system.
5. Reference supporting files relative to the skill. Do not require Claude variables, injected shell
   syntax, a particular Agent tool, model names, context inheritance, or fixed token budgets in the
   shared procedure.
6. Check the current provider documentation before adding optional invocation metadata. Such fields
   are adapters; prose must state any essential constraint because another harness may ignore them.
   Invocation metadata does not grant authority or replace the harness permission boundary.
7. Check representative positive prompts and near misses against neighboring descriptions. A source
   validator can prove names and frontmatter, while activation quality still needs a model trial.
8. Run `agent/scripts/sync-agent-config.sh --check` and the repository tests. After landing the
   change in the canonical checkout, run `agentctl sync` and `agentctl doctor`.

## Discovery

Use the generated discovery locations in `agent/docs/CONFIGURATION.md`; all local harnesses
resolve personal and engineering skills to the same sources. Do not add a parallel plugin or legacy
skill path for an already managed procedure.

Use `agent/skills/README.md` in the working checkout for the inventory and ownership map.
Report the changed trigger/procedure, verification, and any provider discovery not exercised.
