---
name: pi-skill-authoring
description: Write or improve skills for the pi-mono coding harness. Use when creating a new Pi skill, reviewing skill quality, adapting Claude/Codex skills, or deciding what belongs in a skill versus an extension, agent, or AGENTS.md.
---

# Pi Skill Authoring

Write Pi skills for **progressive disclosure**: the description is always visible, but the full `SKILL.md` is only loaded on demand. Front-load routing clues and keep the body focused.

## Pi-specific facts

- Pi discovers skills from `~/.pi/agent/skills/`, `.pi/skills/`, package `skills/`, settings `skills`, and `--skill` paths.
- In Pi skill directories, the folder must contain `SKILL.md`.
- `name` must match the parent directory and use lowercase letters, numbers, and hyphens only.
- `description` is required; missing descriptions are not loaded.
- Pi is lenient about most validation issues, but bad names/descriptions still hurt routing.
- Skill descriptions are included in the agent prompt; full instructions are loaded later via `read`.
- Unknown frontmatter keys are generally ignored by Pi, so do not assume Claude/Codex-specific fields have runtime meaning here.

## Supported frontmatter

Use these as the safe Pi header surface:

```yaml
---
name: my-skill
description: Specific trigger-oriented description.
disable-model-invocation: true
allowed-tools: read bash edit
license: MIT
compatibility: Requires MATLAB R2023b
metadata:
  domain: neuroscience
  maturity: stable
---
```

### Fields that matter

- `name` — required
- `description` — required
- `disable-model-invocation` — manual-only skill
- `allowed-tools` — experimental pre-approval hint
- `license`, `compatibility`, `metadata` — documentation/organization

### Fields to avoid relying on

Pi does **not** document Claude-style skill headers like these as active Pi controls:

- `user-invocable`
- `argument-hint`
- `arguments`
- `when_to_use`
- `context`
- `model`
- `effort`
- `agent`
- `paths`
- `shell`

If you keep such fields for cross-harness reuse, treat them as inert metadata unless you have verified Pi support.

## Do

1. **Make the description specific and trigger-oriented.** Say what the skill does and when to use it.
2. **Keep one skill focused on one job.** Split large topics into separate skills or supporting files.
3. **Put critical instructions early.** The beginning survives best under compaction and partial loading.
4. **Use imperative instructions.** “Read X”, “Check Y”, “Ask Z”, “Stop if…”
5. **Use supporting files for long reference material.** Keep `SKILL.md` concise; move tables/examples to sibling files when needed.
6. **Use relative paths from the skill directory** when referencing scripts or docs.
7. **State setup and prerequisites explicitly.** Include commands, env vars, versions, and expected tools.
8. **Define output shape.** Tell Pi what a good result should look like.
9. **Prefer skills for workflows/domain knowledge** and extensions for new tools/UI/stateful behavior.
10. **Adapt cross-harness skills carefully.** Remove Claude-specific fields unless you intentionally want tolerated-but-ignored metadata.

## Don't

- **Don’t use vague descriptions** like “helps with MATLAB” or “useful for neuroimaging”.
- **Don’t turn a single tool call into a skill** unless the skill adds workflow, judgment, or domain conventions.
- **Don’t duplicate repo facts** that belong in `AGENTS.md`, `CLAUDE.md`, or project docs.
- **Don’t hide side effects.** If a skill performs risky actions, make that obvious in the instructions.
- **Don’t bury the important part** after huge reference dumps.
- **Don’t overload one skill** with unrelated responsibilities.
- **Don’t assume Pi will infer setup.** Write exact commands and file locations.

## Skill vs other Pi mechanisms

- **Skill:** repeatable workflow, domain playbook, reference knowledge.
- **Extension:** new tools, slash commands, TUI/editor behavior, event hooks.
- **Agent (`.pi/agent/agents/*.md`):** subagent persona with tool allowlist and prompt.
- **AGENTS.md / project docs:** persistent repo facts, conventions, architecture notes.

## Recommended structure

```text
my-skill/
├── SKILL.md
├── references/
├── examples/
└── scripts/
```

## Minimal template

```markdown
---
name: my-skill
description: Specific task + trigger conditions.
---

# My Skill

## When to use
narrow trigger conditions

## Steps
1. Do the first thing.
2. Validate.
3. Report in a fixed format.

## References
See [references/API.md](references/API.md).
```

## Quality checklist

- Description is specific enough for auto-routing.
- Name matches directory.
- First section tells Pi exactly how to use the skill.
- Steps are actionable and finite.
- Output format is explicit.
- Long reference content is split out.
- The skill adds value beyond a bare tool call.

## Sources used for this guidance

- Pi `docs/skills.md`
- `badlogic/pi-skills` examples
- Anthropic skills examples/best-practice patterns
