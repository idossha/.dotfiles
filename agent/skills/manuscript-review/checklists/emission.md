## Pipeline, anchoring, and emission

This is the operational backbone of the skill: how to ingest the manuscript, where findings are recorded, and how proposed revisions are emitted **as Word comments + a triage report** without ever mutating the author's source. Default posture is **propose, never apply**.

### 1. Ingest the manuscript (establish source of truth)

- **Prefer the canonical `paper/spec.json`.** It is the only artifact that preserves `metadata`, `bibliography`, `citation_style`, and `\cite{key}` keys. Read it directly as the source of truth for all prose and citation analysis.
- **Detect staleness before trusting the spec.** Compare mtimes of `paper/spec.json` against the source `.docx`. If the `.docx` is newer (human edited in Word since the last build), the spec is stale.
- **If you must re-read a newer `.docx`, read to a SCRATCH path — never clobber the canonical spec:**
  ```bash
  docx-tools read paper/sleepTI_draft_v0.7.docx -o "$SCRATCH/spec_v0.7_readback.json"
  ```
  - **Round-trip caveat (load-bearing):** `read` DROPS `metadata`/`bibliography`/`citation_style` and rewrites `\cite{key}` to rendered `[n]`. Treat the readback as a **prose-and-rendering view only**, not a rebuildable spec.
  - Diff readback prose against the canonical spec to isolate genuine human edits: `diff <(jq -r '.content[].text // empty' paper/spec.json) <(jq -r '.content[].text // empty' "$SCRATCH/spec_v0.7_readback.json")`. Fold real edits into your mental model; **do not** write the readback over `paper/spec.json`.
- **Build a section→block index.** Walk `content` in order; each `heading` block opens a section; subsequent `body`/`figure`/`references` blocks belong to it. Record for every block: `idx`, `type`, owning section heading, and (for body) the full `text`. Use this index to give findings a stable `location` and to scope literature checks (e.g. citation claims live in Discussion vs Methods).
  ```bash
  jq -r '.content | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.text // .value.heading // "")"' paper/spec.json
  ```
- **Handle main + supplement as SEPARATE documents.** They are distinct `.docx`/spec pairs with independent block indices, independent `comments.json`, independent reviewed outputs, and independent figure/citation numbering. Never anchor a main-document finding into the supplement or vice versa. Cross-document consistency findings (e.g. "main reports field LOSO 0.56–0.66 but supplement still shows stale 0.47–0.56") are recorded once per document with the anchor in each.

### 2. Anchor selection rules (critical for `inject` reliability)

`docx-tools inject` matches each comment's `anchor` as a **verbatim substring of the rendered document text**. Anchors that don't match are **silently dropped**. Every anchor MUST be:

- **A single, contiguous slice of ONE `body` block's `text`** — never spanning two blocks, never a heading.
- **Unique across the whole rendered document.** Before committing an anchor, confirm it occurs **exactly once**:
  ```bash
  grep -F -o 'left insula' paper/spec.json | wc -l   # must be 1 for the rendered surface you target
  ```
  If a phrase repeats, extend it left/right until unique (target length **~15–80 chars**; long enough to be unique, short enough to stay copy-paste-exact).
- **Unicode-exact.** Preserve em-dashes (U+2014 `—`), en-dashes (U+2013), non-breaking spaces (U+00A0), Greek (ρ, μ), and primes. A straight `-` will not match a rendered `—`. Copy the bytes from the block `text`, never retype.
- **Free of rendered-citation and subscript text.** Citations render as `[n]`, so the underlying `\cite{key}` is NOT present in the rendered surface — do not anchor on a key, and avoid straddling a `[n]` boundary. Likewise avoid spans whose subscript (`TI_{max}`, `p_FWE`) renders differently than the spec text; anchor on adjacent plain prose instead.
- **One anchor per finding.** If a finding touches several spots, pick the single most diagnostic span and describe the others in the comment body.
- **Fallback when no clean unique substring exists:** quote the nearest unique plain-prose phrase as the anchor and pin the exact target in the comment body, e.g. `[MAJOR · Soundness] Re: the p=0.0942 between-group cluster three sentences later in this paragraph —`.

### 3. Comment authoring & injection

- **Author EVERY review comment as `"Manuscript Review"`** — never `"Ido Haber"`. This keeps automated findings cleanly separable from the author's own Word comments (which use the author name). Date each comment (today, ISO `YYYY-MM-DD`).
- **Prefix the comment body with a severity + dimension tag:** `[CRITICAL · Consistency]`, `[MAJOR · Soundness]`, `[MINOR · Literature]`, `[QUESTION · Consistency]`. Dimensions are exactly `Soundness` / `Consistency` / `Literature`.
- **Include the concrete suggested rewrite inline**, honoring docx subscript rules: write `TI_{max}`, `TI_normal`, `p_FWE`, `X_sub` — **never italic-wrap the base** (e.g. never `*p*_FWE`, which breaks into a literal underscore).
- **Cross-reference the finding ID** from the triage report so comment ↔ report are joinable.
- **Assemble `comments.json`** as a flat list:
  ```json
  [
    {
      "author": "Manuscript Review",
      "date": "2026-06-29",
      "anchor": "targeting the left mPFC",
      "comment": "[CRITICAL · Consistency] (F-012) Target is the LEFT INSULA per Methods and CLAUDE.md; 'left mPFC' is a stale mislabel. Suggested: replace 'left mPFC' -> 'left insula'."
    }
  ]
  ```
- **Inject into a NEW reviewed file (never the source):**
  ```bash
  docx-tools inject paper/sleepTI_draft_v0.7.docx \
    --comments "$SCRATCH/comments_main.json" \
    -o paper/sleepTI_draft_v0.7_reviewed.docx
  ```
- **VERIFY every comment landed** — dropped anchors are silent. `docx-tools extract --json` returns a **flat top-level list** (not `{comments:[...]}`), and each entry uses fields **`author`, `date`, `text`, `anchor_text`, `id`, `reply_to`** (note: `text`/`anchor_text`, NOT the `comment`/`anchor` keys used on the *input* side). The source `.docx` may already carry the author's own comments, so **count only the comments YOU added** by filtering on `author == "Manuscript Review"`:
  ```bash
  # count this skill's injected comments in the reviewed doc
  docx-tools extract paper/sleepTI_draft_v0.7_reviewed.docx --json \
    | jq '[.[] | select(.author=="Manuscript Review")] | length'
  ```
  Compare against `jq length "$SCRATCH/comments_main.json"` (every input comment is authored "Manuscript Review"). For any mismatch, diff the injected anchors against the extracted `anchor_text` set, fix the offending anchor (usually a unicode or uniqueness miss), and re-inject to a fresh output. Do not ship until **injected count == extracted "Manuscript Review" count**. (Verified against docx-tools on v0.7: 2 injected → 2 "Manuscript Review" extracted alongside 4 preserved "Ido Haber" comments.)

### 4. Triage report schema

Write `reports/review/manuscript_review_<version>.md` (e.g. `manuscript_review_v0.7.md`); one report per document (suffix `_supplement` for the supplement). Structure:

- **Header:** manuscript file path, version, review date, scope (main vs supplement; which sections covered), reviewer = `manuscript-review skill`.
- **Counts summary:** a one-line tally `CRITICAL: n · MAJOR: n · MINOR: n · QUESTION: n` plus per-dimension counts.
- **Severity-grouped findings** (CRITICAL → MAJOR → MINOR → QUESTION). Each finding is a stable block:
  - **ID:** stable, e.g. `F-012` (reused verbatim in the Word comment).
  - **Dimension:** `Soundness` | `Consistency` | `Literature`.
  - **Location:** section heading + the exact anchor used.
  - **Issue:** one-sentence statement of the problem.
  - **Evidence:** the quoted manuscript text and/or the conflicting value/source.
  - **Suggested revision:** exact `old -> new` where text-level; otherwise a precise instruction.
  - **Confidence:** `High` | `Med` | `Low`.
  
  ```markdown
  ### F-012 · CRITICAL · Consistency · High
  - Location: Methods → Stimulation; anchor "targeting the left mPFC"
  - Issue: Target mislabeled as left mPFC; canonical target is left insula.
  - Evidence: "...1 Hz beat targeting the left mPFC..." conflicts with Abstract/CLAUDE.md ("left insula").
  - Suggested revision: "left mPFC" -> "left insula"
  ```
- **Literature verification ledger (appendix):** one row per checked citation — `[n]` / cite key / claim-in-text / OpenAlex ID or DOI / venue-quality check / VERDICT (Supports / Misattributed / Overstated / Not-found) / note. This is the audit trail for every `Literature` finding and is appended whether or not a finding resulted.

### 5. Revision policy (default = propose, never auto-edit)

- **Never mutate `paper/spec.json` body `text` by default.** All proposed changes live as `old -> new` strings inside findings + comments. The deliverables are `*_reviewed.docx` + the triage report — not an edited spec.
- **Only on explicit user opt-in to apply fixes:** write a NEW versioned spec and build a NEW versioned docx; never overwrite the source:
  ```bash
  cp paper/spec.json paper/spec_reviewed_v0.7.json
  # apply approved old->new edits to the COPY only, then:
  docx-tools build paper/spec_reviewed_v0.7.json -o paper/sleepTI_draft_v0.7_revised.docx
  ```
- **Build caveat:** `docx-tools build` ABORTS the entire build if any referenced figure image is missing. Before building, confirm every `figure` block's image path resolves; if a figure asset is absent, stage a placeholder or temporarily note the gap rather than letting the whole build fail.
- Preserve the author's `\cite{key}` / `metadata` / `bibliography` in the edited copy — work from the canonical spec, never from a `read` readback.

### 6. Safety / verification exit

- **Never overwrite source artifacts:** the original `.docx`, `paper/spec.json`, and `references.bib` must be byte-identical before and after the run.
- **Confirm every output path exists** before reporting success: `*_reviewed.docx`, `reports/review/manuscript_review_<version>.md`, and (if opt-in) the revised spec + docx.
  ```bash
  for f in paper/sleepTI_draft_v0.7_reviewed.docx reports/review/manuscript_review_v0.7.md; do
    [ -s "$f" ] && echo "OK $f" || echo "MISSING $f"
  done
  ```
- **Re-assert comment fidelity:** injected count == extracted count for each document (main and supplement separately).
- **Final report-out:** print the counts summary (CRITICAL/MAJOR/MINOR/QUESTION per document) and the absolute paths to each reviewed `.docx` and each triage report. Do not claim completion until paths are verified on disk and counts reconcile.
