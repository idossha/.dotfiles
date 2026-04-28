---
name: write-skill
description: Create or improve Claude Code skills following Anthropic best practices. Use when the user wants to write a new skill, refactor an existing one, or review skill quality. Covers frontmatter, structure, invocation control, content lifecycle, and the dotfiles symlink workflow.
disable-model-invocation: true
argument-hint: [skill-name]
allowed-tools: Bash(ls *) Read Write Edit Glob Grep
---

# Write Skill

You are writing or improving a Claude Code skill. Follow this guide precisely.

## File location

All skills live in the dotfiles repo and are symlinked to the local machine:

```
Source:  ~/.dotfiles/claude/.claude/skills/<skill-name>/SKILL.md
Symlink: ~/.claude/skills -> ~/.dotfiles/claude/.claude/skills
```

Never create skills directly in `~/.claude/skills/`. Always write to `~/.dotfiles/claude/.claude/skills/<skill-name>/SKILL.md`. The symlink makes them available immediately.

If the skill needs supporting files (templates, examples, scripts), place them alongside SKILL.md in the same directory:

```
~/.dotfiles/claude/.claude/skills/<skill-name>/
  SKILL.md           # Required: main instructions
  template.md        # Optional: template for Claude to fill
  examples/          # Optional: example outputs
  scripts/           # Optional: helper scripts
```

Reference supporting files from SKILL.md so Claude knows they exist. Use `${CLAUDE_SKILL_DIR}` to reference files relative to the skill directory.

## Step 1: Determine intent

If `$ARGUMENTS` is provided, use it as the skill name.

Ask the user (skip questions already answered):
1. **What does this skill do?** One sentence.
2. **Who invokes it?** Determines invocation mode:
   - Both user and Claude (default) -- no special frontmatter
   - User only (`disable-model-invocation: true`) -- for workflows with side effects
   - Claude only (`user-invocable: false`) -- for background domain knowledge
3. **Does it need arguments?** If yes, what are they?
4. **Should it run in a forked context?** (`context: fork`) -- for isolated tasks that should not see conversation history.

## Step 2: Write the frontmatter

The YAML frontmatter block controls all skill behavior. Every field and its purpose:

```yaml
---
name: my-skill                        # Lowercase, hyphens only. Max 64 chars. Becomes /my-skill.
description: >-                       # REQUIRED in practice. Front-load the key use case.
  One-paragraph description of what    # Claude reads this to decide relevance.
  this skill does and when to use it.  # Truncated at 1,536 chars (combined with when_to_use).
when_to_use: >-                       # Optional. Appended to description for matching.
  Additional trigger conditions.       # Counts toward the 1,536-char cap.
argument-hint: [arg1] [arg2]          # Shown in autocomplete. Helps user know what to pass.
arguments: arg1 arg2                  # Named positional args. Maps to $arg1, $arg2 in content.
disable-model-invocation: true        # true = only user can invoke via /name. Default: false.
user-invocable: false                 # false = hidden from / menu. For background knowledge. Default: true.
allowed-tools: Bash(git *) Read Edit  # Tools Claude can use without permission prompts.
model: sonnet                         # Model override. Options: sonnet, opus, haiku, inherit.
effort: high                          # Effort override: low, medium, high, xhigh, max.
context: fork                         # fork = run in isolated subagent context.
agent: Explore                        # Subagent type when context: fork. Options: Explore, Plan, general-purpose.
paths: "src/**/*.py, tests/**"        # Glob patterns limiting when skill activates.
shell: bash                           # Shell for inline commands. bash (default) or powershell.
---
```

### Frontmatter rules

- **`name`**: Omit to use the directory name. Prefer explicit for clarity.
- **`description`**: This is the most important field. Claude uses it to decide when to auto-invoke. Front-load the primary use case. Be specific about trigger conditions. The combined `description` + `when_to_use` text truncates at 1,536 characters -- put the most important information first.
- **`disable-model-invocation: true`**: Use for anything with side effects (deploys, commits, sends messages, creates PRs, modifies external systems). Prevents Claude from invoking without explicit user request.
- **`user-invocable: false`**: Use for domain knowledge that Claude should auto-load when relevant. The user never needs to type `/skill-name` for these.
- **`allowed-tools`**: Pre-approve tools to avoid repeated permission prompts during the skill. Only grant what the skill actually needs. Use glob patterns for Bash: `Bash(git *)`, `Bash(npm *)`.
- **Never combine** `disable-model-invocation: true` with `user-invocable: false` -- they are mutually exclusive intents.

### Invocation control summary

| Frontmatter combo                    | User invokes | Claude invokes | Description in context |
|--------------------------------------|-------------|----------------|----------------------|
| (default)                            | Yes         | Yes            | Yes                  |
| `disable-model-invocation: true`     | Yes         | No             | No                   |
| `user-invocable: false`              | No          | Yes            | Yes                  |

## Step 3: Write the content body

The markdown body after the frontmatter is what Claude follows when the skill is invoked. Apply these principles:

### Structure

1. **Start with a one-line role statement**: "You are doing X." Sets Claude's frame.
2. **Use numbered steps** for procedural skills. Use sections for reference skills.
3. **Keep SKILL.md under 500 lines.** Move reference material to separate files in the skill directory.
4. **Be imperative**: "Run X", "Check Y", "Ask the user Z". Not "You could run X" or "Consider checking Y".
5. **Specify exit conditions**: What does "done" look like? What should Claude output when finished?

### Variable substitution

Use these in the markdown body:

| Variable               | Description                                    |
|------------------------|------------------------------------------------|
| `$ARGUMENTS`           | All arguments passed when invoking             |
| `$ARGUMENTS[N]`        | Specific argument by 0-based index             |
| `$N`                   | Shorthand for `$ARGUMENTS[N]`                  |
| `$name`                | Named arg from `arguments` frontmatter         |
| `${CLAUDE_SKILL_DIR}`  | Directory containing this SKILL.md             |
| `${CLAUDE_SESSION_ID}` | Current session ID                             |
| `${CLAUDE_EFFORT}`     | Current effort level                           |

### Dynamic context injection

Run shell commands before skill content loads using `` !`command` `` syntax:

```markdown
## Current branch info
!`git branch --show-current`
!`git log --oneline -5`
```

Multi-line version:
````markdown
```!
gh pr list --state open --limit 5
```
````

Output replaces the placeholder before Claude sees the skill.

### Content lifecycle awareness

- Invoked skill content **stays in context for the rest of the session**.
- After auto-compaction, the first **5,000 tokens** of each skill are preserved.
- Combined budget for all re-attached skills: **25,000 tokens**.
- Most recently invoked skills get priority.
- **Implication**: Put the most critical instructions in the first 5,000 tokens. Put reference tables and examples later -- they may be trimmed.

## Step 4: Quality checklist

Before saving, verify:

- [ ] **Description is specific and front-loaded** -- Claude can decide relevance from the first sentence
- [ ] **Invocation mode matches intent** -- side effects require `disable-model-invocation: true`; background knowledge requires `user-invocable: false`
- [ ] **No overlap with CLAUDE.md** -- skills are for procedures and reference; CLAUDE.md is for facts and conventions
- [ ] **Under 500 lines** -- long reference material moved to supporting files
- [ ] **Critical content in first 5,000 tokens** -- survives compaction
- [ ] **Imperative voice throughout** -- "Do X", not "You might want to X"
- [ ] **Steps have clear exit conditions** -- Claude knows when it is done
- [ ] **`allowed-tools` is minimal** -- only tools the skill actually needs
- [ ] **No generic or vague description** -- bad: "Helps with code"; good: "Generate Python dataclass from JSON schema, with frozen=True and type hints"
- [ ] **Arguments documented** if the skill accepts them -- `argument-hint` set, variables used in body
- [ ] **Supporting files referenced** from SKILL.md if they exist
- [ ] **File is in dotfiles** at `~/.dotfiles/claude/.claude/skills/<name>/SKILL.md`, not directly in `~/.claude/`

## Step 5: Save and verify

1. Write the SKILL.md to `~/.dotfiles/claude/.claude/skills/<skill-name>/SKILL.md`.
2. Verify the symlink is intact: `ls -la ~/.claude/skills/<skill-name>/SKILL.md`.
3. If the symlink is broken or missing, warn the user. The top-level symlink should already exist:
   ```
   ~/.claude/skills -> ../.dotfiles/claude/.claude/skills
   ```
4. Show the user the final file and confirm it is live.

## Common anti-patterns to avoid

- **Wall-of-text descriptions**: The description field is for Claude's routing, not documentation. Keep it to 2-3 sentences max.
- **Mixing invocation modes**: A skill should not be both background knowledge and an interactive workflow.
- **Putting facts in skills**: Facts about the codebase belong in CLAUDE.md. Skills are for procedures, checklists, and reference material that load on-demand.
- **Duplicating tool functionality**: Don't write a skill that wraps a single tool call. Skills add value when they encode multi-step procedures or domain knowledge.
- **Forgetting `allowed-tools`**: If the skill uses tools, pre-approve them. Otherwise the user gets prompted repeatedly, which defeats the purpose.
- **Overscoping**: One skill, one job. If you need to combine "create component" and "write tests", make two skills.
