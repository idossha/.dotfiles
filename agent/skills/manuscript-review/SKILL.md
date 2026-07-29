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

1. Resolve the target from `$ARGUMENTS`:
   - A `.docx` or `.json` path → that document.
   - `main` (default) → the latest `paper/*_draft_v*.docx` and its `paper/spec.json`.
   - `supplement` → the latest `paper/*_supplement_v*.docx` and `paper/supplement_spec.json`.
   - `main+supplement` → both, as **separate** documents (separate indices, comments, reports, figure/citation numbering).
2. Establish the **source of truth**: prefer the canonical `spec.json` (it preserves `metadata`/`bibliography`/`citation_style`/`\cite{key}`). If the `.docx` mtime is newer than the spec, the human edited in Word — `docx-tools read <docx> -o $SCRATCH/readback.json` to a **scratch path** and diff prose; never overwrite the canonical spec (see `checklists/emission.md` §1, round-trip caveat).
3. Load project context that defines what is *intentional*: the repo `CLAUDE.md`, any protocol/SAP, and `literature.md`. These supply the documented-decision list (below).

## The six passes

Run in this order. Cheap structural facts first, interpretive passes last, emission at the end.

1. **Ingest & map** — build three shared inventories ONCE: the section→block index, the whole-document **number ledger**, and the **citation inventory** (`[n]` ↔ `references.bib`). All later passes consume these; never re-parse the whole doc per agent. (`emission.md` §1, `consistency.md` ledger, `literature.md` §0.)
2. **Internal consistency** — diff the number ledger (e.g. `43 = 32 active + 11 sham` everywhere; same p/ρ/effect size/CI across abstract/results/discussion/captions; main↔supplement parity), terminology (target = **left insula**, never mPFC), cross-references (every `Figure N`/`Fig S#` resolves; no dangling main↔SI). (`checklists/consistency.md`.)
3. **Internal soundness** — claim↔evidence traceability; statistics validity (cluster-level-only inference, no "peak vertex was significant"; double-dipping in pooled all-significant-vertex effect sizes; null-contrast interpretation of `p=0.0942`; dose-collinearity partials at ρ≈0.97); methods↔results↔conclusion alignment; figure support; over-claiming/mechanism. (`checklists/soundness.md`.)
4. **Literature verification** — bibliography hygiene + representation fidelity for every **load-bearing/quantitative** citation via the source-acquisition ladder (local PDF → `literature.md` → OpenAlex MCP → WebFetch), missing-citation sweep, self/adjacent-work framing (Schaeffer = plain reference only), → the verification ledger. (`checklists/literature.md`.)
5. **Synthesize** — merge all findings, de-duplicate (one defect → one owner), assign severity + confidence, and attach the competing explanation wherever one exists. (`checklists/orchestration.md`.)
6. **Emit** — anchored Word comments (author `Manuscript Review`) into `<name>_reviewed.docx`, verified `injected == extracted`; the triage report `reports/review/manuscript_review_<version>.md`; suggested rewrites proposed, never applied. (`checklists/emission.md` §3–6.)

## Severity rubric (assign one per finding; orthogonal to confidence)

| Severity | One-line test |
|---|---|
| **CRITICAL** | If it ships, a reader is misled about the headline finding, or a result is invalidated. (e.g. wrong analyzed n in the Abstract; a residual "left mPFC" target label; a MISREPRESENTED load-bearing citation; calling a peak vertex/channel "significant"; an Abstract implying the active-vs-sham effect was significant.) |
| **MAJOR** | Materially weakens a claim's validity/reproducibility or contradicts a non-headline number, but the result survives once fixed. (e.g. missing permutation count/threshold/FWE method; stale supplement LOSO range vs refreshed main; pooled all-significant-vertex r framed as an independent effect magnitude.) |
| **MINOR** | Cosmetic/clarity/style; correctness unaffected. (e.g. undefined acronym; hyphenation drift; a rounding inconsistency that does NOT cross a threshold.) |
| **QUESTION** | Not provably a defect from the document alone; needs author knowledge. (e.g. "is this contrast actually pre-registered as worded?") |

A number defect inherits the severity of **where it lives**: the same wrong ρ is CRITICAL in the Abstract, MAJOR in a secondary caption, MINOR in a passing aside. A rounding change that crosses a threshold (`0.0942`→`p<0.05`) is NOT minor — escalate.

## Confidence, not suppression

Report coverage-first: every defensible finding is emitted with a severity **and** a confidence, and the author filters downstream. A finding is never deleted because it *might* be intentional — the competing explanation goes into the finding and the confidence goes down.

1. **Consult the documented-decision list** — design choices that look like defects but are intentional and justified in `CLAUDE.md`/protocol/Methods. This list is per-manuscript, not a property of this skill: load the authoritative version from the project's `CLAUDE.md`/protocol at ingest (step 3 above). For the sleepTI draft it currently holds: sLORETA **depth 0.8** (noise-normalized/depth-insensitive, Lin 2006); the between-group null **`p=0.0942`** reported transparently as a secondary/control contrast; **density = primary/co-primary, count = supportive** (pre-specified); the one-sided origin window **`[−150,0] ms`** (documented default); depth/subsampling sensitivity analyses **run but trimmed from v0.7**.
2. **On a documented decision, report the residual.** Name the decision you checked, then flag what is actually wrong around it — the in-text justification is absent, the cited source doesn't support it, the text over-claims robustness it no longer shows, the null is reframed as positive. If there is no residual, emit it as a QUESTION rather than dropping it.
3. **Note the competing explanation** for anything that could be benign: (a) two *different* quantities colliding in the ledger; (b) a rendering artifact (em-dash vs hyphen, `[n]` vs `\cite{}`, subscript reflow); (c) a stated exclusion or per-analysis n; (d) a defensible field convention. These are diagnostics to record in the comment, not a gate that deletes the finding.
4. **Confidence:** assign High/Med/Low to every finding, orthogonal to severity. Nothing is dropped for low confidence. Word a Low-confidence item as the conditional it is ("if the contrast was not pre-registered as worded, then…") while keeping its true severity, so the author sees both the stake and the uncertainty.

## Ownership (one defect, one owner)

**Consistency** = does the document agree with itself. **Soundness** = is each claim earned by the design/evidence. **Literature** = does each claim match the outside world. When two lenses fire on one defect, the dimension in whose lens it actually lives owns it; the others cross-list in the note — do not emit duplicate comments on one anchor. Full resolution table in `checklists/orchestration.md`.

## Multi-agent orchestration

Fan out with the **Agent** tool only when the document exceeds what you can hold and diff in one context; a short manuscript or a single-section re-review is faster run inline. When you do fan out, send each wave's independent agents in one message and cap it at what the merge step can actually read. Shape:

- **Pre-pass (single, blocking):** build the three shared inventories + load the documented-decision list. Read-only inputs to all downstream agents.
- **Consistency — do NOT fan by section:** one whole-document number-ledger agent (+ one terminology/cross-ref agent). Cross-section diffing is the whole point.
- **Soundness — one agent per logical section:** Abstract+Significance, Methods, Results, Discussion+Limitations, Figures+Captions; each gets only its block slice + `CLAUDE.md` + the documented-decision list.
- **Literature — coordinator + per-citation workers:** one worker per load-bearing `[n]` (batch decorative ones); one whole-bib hygiene agent.
- **Supplement** is its own fan-out (Soundness + Literature), feeding the same whole-doc Consistency ledger.
- **Merge (single, blocking):** collect, de-dup by `(anchor block + normalized issue)`, assign owners + severity, then author comments. The merger holds the only full list.

Running sequentially in the pass order above is always a valid alternative. De-duplication is mandatory either way.

## Emission essentials (full detail in `checklists/emission.md`)

- **Anchors** = unique, verbatim, unicode-exact substrings of ONE `body` block's `text` (~15–80 chars); confirm each occurs exactly once before injecting; avoid spans crossing a rendered `[n]` or a subscript. Unmatched anchors are **silently dropped**.
- **Author every comment `"Manuscript Review"`** (never "Ido Haber"), dated ISO, body prefixed `[SEVERITY · Dimension] (F-ID)` and ending with the concrete `old → new` (respect subscript rules: `TI_{max}`, `p_FWE`; never italic-wrap the base).
- `docx-tools inject <source>.docx --comments $SCRATCH/comments.json -o <source>_reviewed.docx`, then **verify**. `extract --json` returns a flat list whose entries use `author`/`text`/`anchor_text` (the source may already hold the author's own comments), so count only yours: `docx-tools extract <reviewed>.docx --json | jq '[.[]|select(.author=="Manuscript Review")]|length'` must equal the injected count. Do not ship on mismatch — fix the offending anchor and re-inject.
- **Revision policy = propose, never apply.** Never mutate `spec.json` body text by default. Only on explicit opt-in: copy to a NEW versioned spec, apply approved `old→new` to the copy, `docx-tools build` a NEW versioned docx (mind: a missing figure image aborts the whole build). Never overwrite source artifacts.

## Triage report

Write `reports/review/manuscript_review_<version>.md` (suffix `_supplement` for the supplement): header (file, version, date, scope, reviewer = this skill) → counts summary (`CRITICAL · MAJOR · MINOR · QUESTION` + per-dimension) → severity-grouped findings, each a block of `ID · Severity · Dimension · Confidence`, Location (section + anchor), Issue, Evidence (quoted text/conflicting value/source), Suggested revision (`old → new`) → appended **literature verification ledger** → an explicit **open-items list** (every UNVERIFIABLE citation + every QUESTION only the author can resolve).

## Exit conditions ("done")

- Every `content[]` block visited; every section has a recorded verdict (no-finding counts).
- Number ledger built, normalized, diffed; zero *unexplained* invariant conflicts open.
- Every load-bearing/quantitative citation has a ledger verdict (SUPPORTED/PARTIAL/MISREPRESENTED/UNVERIFIABLE); none silently passed.
- Every finding carries severity + dimension + confidence + a unique verbatim anchor + a concrete `old → new`, and names the documented decision or competing explanation where one applies.
- Duplicates merged to one owner; no anchor carries two comments for one defect.
- Per document: comments injected and **injected count == extracted count** verified.
- `<name>_reviewed.docx` and the triage report exist on disk; source `.docx`, `spec.json`, `references.bib` byte-identical to before.
- Final report-out prints per-document severity counts, absolute output paths, and the open-items list.
