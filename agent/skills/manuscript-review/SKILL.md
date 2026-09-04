---
name: manuscript-review
description: >-
  Comprehensively review a scientific manuscript (docx-tools spec.json / .docx)
  for internal soundness, internal consistency, and fidelity to its cited
  literature, then flag issues as anchored Word comments + a severity-grouped
  triage report and propose (never auto-apply) revisions. Built for stats-heavy
  human-subjects neuro/EEG papers. Use when asked to review, audit, sanity-check,
  fact-check, or "go through" a paper draft, manuscript, or its supplement.
when_to_use: >-
  User asks to review/audit/critique/proofread a manuscript, check a paper for
  consistency or overclaiming, verify citations against sources, or prepare a
  pre-submission self-review. Operates on paper/spec.json + references.bib +
  the built .docx, and the separate supplement document.
argument-hint: "[paper.docx | spec.json | main | supplement | main+supplement]"
disable-model-invocation: true
allowed-tools: Bash(docx-tools *) Bash(ls *) Bash(rg *) Bash(grep *) Bash(jq *) Bash(python3 *) Bash(diff *) Bash(cp *) Bash(mkdir *) Read Write Edit Glob Grep WebFetch WebSearch Agent
effort: high
---

# Manuscript Review

You are performing a comprehensive, adversarial-but-fair self-review of a scientific manuscript before submission. Your job is to assess **internal soundness**, **internal consistency**, and **fidelity to the cited literature**, then record every defensible finding as (1) an anchored Word comment in a *new* reviewed `.docx` and (2) a severity-grouped triage report — with a concrete suggested revision for each, **proposed, never silently applied**.

This skill has side effects (writes a reviewed `.docx` and a report). It is user-invoked only.

## When to use / not use

- **Use** for reviewing a paper draft, manuscript, or supplement: consistency audit, soundness/over-claim check, citation fact-check, pre-submission sweep, "go through the whole paper."
- **Do not** use to *write* a rebuttal (that is `reviewer-response-docx`), to *manage the literature library* (that is `librarian`), or to drive raw `.docx` build/patch mechanics (that is `docx-tools`). This skill *consumes* those.

## Reference files (read on demand)

The exhaustive per-pass checklists live alongside this file. **Read the relevant one before running that pass** — do not work from memory:

- `checklists/soundness.md` — claim↔evidence traceability, statistics validity for this paper class, methods↔results↔conclusion alignment, figure support, over-claiming, reproducibility.
- `checklists/consistency.md` — the number ledger, terminology/naming, cross-references, section coherence, main↔supplement parity, surface consistency.
- `checklists/literature.md` — citation inventory, bibliography hygiene, source-acquisition ladder, representation fidelity, self/adjacent-work framing, missing-citation sweep, currency, the verification ledger.
- `checklists/emission.md` — ingest/source-of-truth, anchor selection rules, comment authoring & injection, report schema, revision policy, safety exit.
- `checklists/orchestration.md` — severity rubric, multi-agent fan-out, ownership rules, coverage gaps, "done" exit conditions.

## Inputs and target detection

1. Resolve the target from the user's supplied arguments and project records (a harness may expose these as `$ARGUMENTS`):
   - A `.docx` or `.json` path → that document.
   - `main` → the project's documented main manuscript and canonical spec, if one exists.
   - `supplement` → the project's documented supplement and its spec, if one exists.
   - `main+supplement` → both, as **separate** documents (separate indices, comments, reports, figure/citation numbering).
2. Establish the **source of truth** using `checklists/emission.md` §1. Prefer canonical metadata and
   citation keys, but compare actual Word edits before trusting a spec. Read Word back to scratch;
   modification time alone does not prove which prose is authoritative.
3. Load project context from `AGENTS.md`, the project decision log, protocol/SAP, Methods and `literature.md`. Record each expected fact and documented decision with its source. No study facts come from this skill. If target selection is ambiguous, inspect project routing before seeking the missing target.

## The six passes

Run in this order. Cheap structural facts first, interpretive passes last, emission at the end.

1. **Ingest & map** — build three shared inventories ONCE: the section→block index, the whole-document **number ledger**, and the **citation inventory** (`[n]` ↔ `references.bib`). All later passes consume these; never re-parse the whole doc per agent. (`emission.md` §1, `consistency.md` ledger, `literature.md` §0.)
2. **Internal consistency** — reconcile the number ledger, study terminology and cross-references across the manuscript and supplement against project-sourced expectations. (`checklists/consistency.md`.)
3. **Internal soundness** — trace claims to design and evidence; check statistical validity, inference scope, figure support, uncertainty and reproducibility for the methods actually used. (`checklists/soundness.md`.)
4. **Literature verification** — check bibliography integrity and every load-bearing/quantitative citation against primary sources; record fidelity, lineage, missing citations and access gaps in the verification ledger. (`checklists/literature.md`.)
5. **Synthesize** — merge all findings, de-duplicate (one defect → one owner), assign severity + confidence, and attach the competing explanation wherever one exists. (`checklists/orchestration.md`.)
6. **Emit** — anchored Word comments (author `Manuscript Review`) into a new reviewed Word file, with comment identity/content verified; the triage report `reports/review/manuscript_review_<version>.md`; suggested rewrites proposed, never applied. (`checklists/emission.md` §3–6.)

## Severity rubric (assign one per finding; orthogonal to confidence)

| Severity | One-line test |
|---|---|
| **CRITICAL** | A headline claim misleads readers or a result is invalidated, such as the wrong analysis population or unsupported causal inference. |
| **MAJOR** | Materially weakens validity or reproducibility while the result may survive correction, such as an undisclosed analysis choice. |
| **MINOR** | Cosmetic/clarity/style; correctness unaffected. (e.g. undefined acronym; hyphenation drift; a rounding inconsistency that does NOT cross a threshold.) |
| **QUESTION** | Not provably a defect from the document alone; needs author knowledge. (e.g. "is this contrast actually pre-registered as worded?") |

Severity follows the consequence for the claim, not location alone. A formatting difference that changes a threshold crossing or interpretation is substantive; a headline location warrants particular scrutiny.

## Confidence, not suppression

Report coverage-first: every defensible finding is emitted with a severity **and** a confidence, and the author filters downstream. A finding is never deleted because it *might* be intentional — the competing explanation goes into the finding and the confidence goes down.

1. **Consult the documented-decision list** from this project's AGENTS.md, decision log, protocol/SAP and Methods. Distinguish recorded intent from scientific justification; both need supporting evidence. Missing project facts remain unknown.
2. **On a documented decision, report the residual.** Name the decision you checked, then flag what is actually wrong around it — the in-text justification is absent, the cited source doesn't support it, the text over-claims robustness it no longer shows, the null is reframed as positive. If there is no defensible residual, record the check as satisfied in coverage; do not manufacture a finding.
3. **Note the competing explanation** for anything that could be benign: (a) two *different* quantities colliding in the ledger; (b) a rendering artifact (em-dash vs hyphen, `[n]` vs `\cite{}`, subscript reflow); (c) a stated exclusion or per-analysis n; (d) a defensible field convention. These are diagnostics to record in the comment, not a gate that deletes the finding.
4. **Confidence:** assign High/Med/Low to every finding, orthogonal to severity. Nothing is dropped for low confidence. Word a Low-confidence item as the conditional it is ("if the contrast was not pre-registered as worded, then…") while keeping its true severity, so the author sees both the stake and the uncertainty.

## Ownership (one defect, one owner)

**Consistency** = does the document agree with itself. **Soundness** = is each claim earned by the design/evidence. **Literature** = does each claim match the outside world. When two lenses fire on one defect, the dimension in whose lens it actually lives owns it; the others cross-list in the note — do not emit duplicate comments on one anchor. Full resolution table in `checklists/orchestration.md`.

## Multi-agent orchestration

Use the `orchestrator` skill and the active harness's supported delegation mechanism only when the document exceeds what you can hold and diff in one context; a short manuscript or a single-section re-review is faster run inline. When you do fan out, send each wave's independent agents in one message and cap it at what the merge step can actually read. Shape:

- **Pre-pass (single, blocking):** build the three shared inventories + load the documented-decision list. Read-only inputs to all downstream agents.
- **Consistency — do NOT fan by section:** one whole-document number-ledger agent (+ one terminology/cross-ref agent). Cross-section diffing is the whole point.
- **Soundness — one agent per logical section:** Abstract+Significance, Methods, Results, Discussion+Limitations, Figures+Captions; each gets only its block slice + `AGENTS.md` + the documented-decision list.
- **Literature — coordinator + per-citation workers:** one worker per load-bearing `[n]` (batch decorative ones); one whole-bib hygiene agent.
- **Supplement** is its own fan-out (Soundness + Literature), feeding the same whole-doc Consistency ledger.
- **Merge (single, blocking):** collect, de-dup by `(anchor block + normalized issue)`, assign owners + severity, then author comments. The merger holds the only full list.

Running sequentially in the pass order above is always a valid alternative. De-duplication is mandatory either way.

## Emission and reporting

Follow `checklists/emission.md` for input provenance, anchors, comment identity/content verification,
output paths and the triage schema. Use docx-tools for the current CLI and file-format mechanics.
Keep proposed revisions separate from the source; apply them to new versioned outputs when the user
has authorized revision application. Do not request that authorization again if already supplied.

## Exit conditions ("done")

- Every `content[]` block visited; every section has a recorded verdict (no-finding counts).
- Number ledger built, normalized and diffed; every discrepancy has a finding or evidenced disposition.
- Every load-bearing/quantitative citation has a ledger verdict (SUPPORTED/PARTIAL/MISREPRESENTED/UNVERIFIABLE); none silently passed.
- Every finding carries severity + dimension + confidence + a unique verbatim anchor + a concrete `old → new`, and names the documented decision or competing explanation where one applies.
- Duplicates merged to one owner; no anchor carries two comments for one defect.
- Per document: this run's comment IDs, anchors and text reconcile; existing comments are preserved.
- `<name>_reviewed.docx` and the triage report exist on disk; source `.docx`, `spec.json`, `references.bib` byte-identical to before.
- Final report-out prints per-document severity counts, absolute output paths, and the open-items list.
