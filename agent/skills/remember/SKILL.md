---
name: remember
description: Route durable knowledge to the right store via the `remember` CLI — Obsidian Zettelkasten for crystallized insight, project-local Markdown for project facts, SQLite for high-volume events. Use at the end of a task that produced knowledge worth keeping, or when the user says "remember this", "save this", or "note this down".
---

# Remember

`~/.dotfiles/agent/scripts/remember` is the single entry point for memory capture.
It picks the destination, dedupes against existing notes, adds `[[wikilinks]]`, and
refuses text that looks like a secret.

## Routing

Pick the store by what the knowledge *is*, not by where the work happened.

| Knowledge | Store | Command |
|---|---|---|
| Crystallized, reusable insight — a technique, a gotcha, a decision that will outlive the project | Obsidian Zettelkasten | `crystal` |
| A fact true only of one project — its layout, a local convention, why a thing is the way it is | Project Markdown | `project` |
| High-volume machine-readable events — telemetry, run logs, timings | SQLite | `raw` |

```bash
remember crystal --topic "<title>" --message "<the fact>" [--source "<url|path>"]
remember project --topic "<title>" --message "<the fact>" [--file memory/agent-memory.md]
remember raw     --topic "<key>"   --message "<payload>"
```

`crystal` writes to `/Users/idohaber/00_development/vault`; `project` writes to
`memory/agent-memory.md` under the current working directory; `raw` writes to
`~/.local/share/agent-memory/raw.sqlite`. Each accepts an override flag
(`--vault`, `--root`/`--file`, `--db`) — use the defaults unless the user names a
different target.

## When to write

Write when a task produced knowledge that is **durable** and **non-obvious**:
a constraint discovered the hard way, a decision and its reasoning, a correction
the user made to your approach.

Do not write:

- What the repo already records — code structure, git history, an existing README
  or `CLAUDE.md`. If it can be re-derived by reading the project, it is not memory.
- Session-local context: what you just edited, what tests you ran, what is left to do.
- Anything the user has not confirmed, if the fact is ambiguous or sensitive. Ask first.
- Secrets, tokens, or credentials. The script rejects obvious cases, but that is a
  backstop, not a substitute for judgment.

One fact per invocation. A note that tries to hold three unrelated things will not
be found later by any of the three.

## Writing the note

`--topic` becomes the note title and drives dedup and link matching, so make it the
thing you would search for later — `Stow ignores dotfiles listed in .stowrc`, not
`stow notes`. The script matches the topic against existing notes and updates the
best match rather than creating a near-duplicate; a vague topic defeats that.

`--message` should state the fact and, where it matters, why. Convert relative dates
to absolute ones — "last week" is unreadable in six months.

Pass `--source` whenever the fact came from somewhere citable: a URL, a file path,
a paper DOI.

## Reading memory back

The Zettelkasten is plain Markdown — search it directly with `rg` rather than through
this script:

```bash
rg -l "<term>" /Users/idohaber/00_development/vault/Zettelkasten
```

Notes reflect what was true when written. If one names a file, function, or flag,
confirm it still exists before acting on it.
