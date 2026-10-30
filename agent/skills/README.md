# Unified Skills

This directory is the canonical source for dotfiles-owned reusable agent skills. Claude Code, Pi and Codex discover the same dotfiles-owned personal skills through generated links;
the contract in `agent/docs/ARCHITECTURE.md` defines ownership, including tool-owned exceptions.

## Layout

```text
agent/skills/
  <skill-name>/
    SKILL.md
    references/
    scripts/
    templates/
```

`SKILL.md` must start with YAML frontmatter:

```yaml
---
name: <skill-name>
description: Specific trigger-oriented description.
---
```

The `name` must match the directory name. Keep descriptions focused on routing:
what the skill does and when an agent should load it.

## Harness discovery

From the assigned checkout, run `agent/scripts/sync-agent-config.sh --check`.
After landing, run `agent/scripts/agentctl sync` from the primary checkout.

Claude receives one link per dotfiles-owned personal and playbook skill in `~/.claude/skills`.
Pi and Codex use the same sources through `~/.agents/skills`. Both discovery roots are real generated
directories; tool-owned pointer skills may also install there but are not linked from this directory.
The duplicate Claude agentic-rules plugin is disabled so an older snapshot cannot supply a different
engineering procedure. Supporting references and scripts stay with their owning skill.

## Inventory

Domain knowledge (auto-loaded when relevant):

| Skill | Purpose |
|---|---|
| `bids` | BIDS dataset layout, entity order, sidecars, derivatives, validation. |
| `eeglab` | EEGLAB/MATLAB EEG processing reference. |
| `engineering-discipline` | Scope, evidence, and verification discipline for any code change. |
| `mne-python` | MNE-Python workflows plus an API lookup helper script. |
| `neuroimaging` | NIfTI/DICOM/SimpleITK/nibabel I/O, orientation, registration. |
| `python-production` | Python 3.11+ idioms and the bugs they prevent. |
| `scientific-computing` | NumPy/SciPy numerical correctness for neuroscience and imaging. |
| `security-review` | Security review checklist for code, tools, skills, and configuration. |

Workflows and playbooks:

| Skill | Purpose |
|---|---|
| `librarian` | Find, download, rename, and strategically summarize papers. |
| `matlab` | Run MATLAB in batch mode from the terminal. |
| `mcp-authoring` | Author and configure MCP servers. |
| `write-skill` | Author or refactor a skill in this directory. |

Document-format skills (`pdf`, `pptx`, `xlsx`, `docx`) are **not** kept here. Use the current harness's
bundled format capabilities when available; local copies can shadow provider updates. Word documents
are read and annotated with the installed `docx-tools` CLI (`read`, `extract`, `inject`, `redline`);
SUNA only exports DOCX.

## Skills owned by their tools

These are not kept here (ARCHITECTURE §3.6): each tool installs a pointer skill to the docs of its
installed version, so the skill cannot drift from the tool.

| Skill | Installed by |
|---|---|
| `idofig` | `idofig skill install` (from the project's or the user's idofig; `--project` for a project's `.claude/skills`) |
| `suna` | the SUNA app (`~/SunaConfig` heal; remove its managed marker to opt out) |
| `suna-presentations` | the SUNA app, beside `suna` |

## External packages

Third-party skill packages are declared in [`../skill-packages.json`](../skill-packages.json) and are
not copied here. `agent/scripts/install-agent-tools.sh` clones each into
`~/.local/share/agent-skills/<name>` or fast-forwards it to upstream's default branch, printing the
incoming commits; `agentctl sync` then links the package's `skills/` directory like any other source,
and `agentctl doctor` reports the revision as floating. Edit a package upstream, never in the clone.

| Package | Skills | Upstream |
|---|---|---|
| `ponytail` | `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help` | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT) |

Only the Markdown skills are used: no plugin, lifecycle hooks, MCP server, or npm package is installed,
so slash-command or plugin claims in Ponytail's help card may not apply in every harness. The user's
instructions and repository policies remain authoritative when a Ponytail suggestion differs from
required scope or verification.

The eight engineering skills live in the local `agentic-rules` clone selected by
`AGENTIC_RULES_DIR` (default `~/00_development/agentic-rules`). They are linked, never copied into
this directory. A missing clone is reported as unchecked by source validation and fails installed
validation, because missing engineering doctrine is not a healthy installed platform.

Provider plugins remain appropriate for provider-specific bundles such as Claude LSP or frontend
tools. Their enablement lives in the harness adapter, and doctor reports enabled floating packages.
A package is a distribution mechanism, not another owner of global policy. Inspect plugin-provided
skill names, MCP servers and hooks for duplicate ownership when adding or upgrading one.

## Validation

Run:

```bash
agent/scripts/sync-agent-config.sh --check
```

This verifies that each skill has a `SKILL.md`, a matching frontmatter `name`,
and a frontmatter `description`.
