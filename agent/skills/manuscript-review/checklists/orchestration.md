## Orchestration, severity, and ownership

This section governs *how* the four review passes are run, scored, de-conflicted, and closed. It is the meta-layer: it does not add new checks, it makes the four sets of checks produce one complete, non-duplicated finding list.

Confidence handling lives in SKILL.md ("Confidence, not suppression") and is not restated here: every defensible finding is emitted with severity + confidence and the competing explanation named, and nothing is dropped for being possibly-intentional.

### Severity rubric (assign exactly one to every finding)

Every finding gets a severity AND a confidence. Severity = impact if shipped; confidence = how sure you are it is a real defect. They are orthogonal: a CRITICAL-impact item at Low confidence is still emitted as CRITICAL, worded as the conditional it is, with the confidence stated.

| Severity | One-line test | Paper-class examples |
|---|---|---|
| **CRITICAL** | If it ships, a reader is misled about the headline finding, or a result is invalidated. | Wrong analyzed n in Abstract (`n=42`); residual "left mPFC" target label; a MISREPRESENTED citation on a load-bearing claim; calling a peak vertex/channel "significant (p=…)"; an Abstract sentence implying the active-vs-sham effect was significant; `p = 0.000`; a Discussion causal claim ("TI enhances") resting on the null between-group contrast. |
| **MAJOR** | Materially weakens a claim's validity/reproducibility or contradicts a non-headline number, but the result survives once fixed. | Missing permutation count / cluster-forming threshold / FWE method in Methods; stale supplement LOSO range (`0.47–0.56`) vs refreshed main (`0.56–0.66`); pooled all-significant-vertex r framed as an independent effect magnitude; uncorrected change-score correlation sold as response specificity; Wendt/Kerby estimator attached to the wrong contrast; a per-analysis n drop that is never reconciled to 43. |
| **MINOR** | Cosmetic/clarity/style; correctness unaffected. | Acronym undefined at first use; hyphenation drift (`slow-wave`/`slow wave`); a rounding inconsistency on a number that does NOT cross a threshold; a missing-but-obvious unit. (A rounding/threshold-crossing change such as `0.0942`→`p<0.05` is NOT minor — escalate to MAJOR/CRITICAL.) |
| **QUESTION** | Not provably a defect from the document alone; needs author knowledge. | "Is the STIM-vs-PRE density contrast actually pre-registered as worded?"; "Is the field-modeling subset n intentional or an unstated exclusion?" |

- Escalation rule: a number defect inherits the severity of *where it lives* — the same wrong rho is CRITICAL in the Abstract/primary result, MAJOR in a secondary caption, MINOR in a passing aside.
- Do not invent a fifth level; if torn between two, pick the higher and state the downgrade condition in the note.

### Multi-agent orchestration (fan-out → merge)

Build shared inventories ONCE, up front, then fan out; never let parallel agents each re-parse the whole doc.

- **Pre-pass (single, blocking):** build the three shared artifacts every agent consumes — the section→block index, the number ledger, and the citation inventory. Also load the **documented-decision list** from the project's CLAUDE.md/protocol. These are read-only inputs to all downstream agents.
- **Soundness fan-out — one agent per logical section:** Abstract+Significance, Methods, Results, Discussion+Limitations, Figures+Captions. Each receives only its block slice plus CLAUDE.md and the documented-decision list, and returns findings in the standard triage block schema. This keeps each agent's context small and its judgments local.
- **Consistency — do NOT fan by section.** Run a *single* number-ledger agent over the WHOLE document (and the supplement) because cross-section diffing is the entire point; splitting it guarantees missed contradictions. Pair it with one terminology/cross-reference agent (grep-style, also whole-doc).
- **Literature — coordinator + per-citation workers.** The coordinator builds the inventory and dispatches one worker per load-bearing/quantitative `[n]` (or a small batch), each owning the source-acquisition ladder for its citation; bibliography hygiene is one whole-bib agent. Decorative citations can be batched; budget effort toward load-bearing ones.
- **Supplement** is its own fan-out, not just a parity check: run Soundness and Literature on it too, then hand its numbers to the same whole-doc Consistency ledger.
- **Merge (single, blocking):** collect all agent outputs into one list, then de-duplicate (next bullet), assign owners, sort by severity, and only then author comments. Each agent returns compact findings; the merger holds the only full list, keeping the parent context lean.
- **De-dup/merge key** = (anchor block + normalized issue). When two agents flag the same underlying defect (e.g. "left mPFC" caught by Soundness, Consistency, and Literature), collapse to ONE finding: keep the highest severity, set the owning dimension per the ownership rules, and cross-list the other dimensions in the note rather than emitting three comments on the same anchor.
- **Tooling:** fan out with the Agent tool only when the document is too large to hold and diff in one context, sending each wave's independent agents in a single message. Otherwise run sequentially in cheap-structural-first order — inventories → Consistency ledger → Soundness → Literature — so settled number/label facts are available before interpretive passes; merge last.

### Ownership rules (resolve cross-section overlaps)

One defect, one owner. Rule of thumb: **Consistency = does the document agree with itself; Soundness = is each claim earned by the design/evidence; Literature = does each claim match the outside world.** When two lenses could fire, the dimension in whose lens the defect actually lives owns it; the others cross-list in the note, they do not re-file.

- **Number appears with two values** → Consistency. **Number is correct / traceable to a method / not overclaimed** → Soundness. **Number matches its external source** → Literature.
- **Caption vs body:** numeric equality (same p/rho/n) → Consistency; "does the figure depict the quantity the sentence claims" → Soundness.
- **Abstract vs body:** value identity → Consistency; direction/over-claim/hedge-upgrade → Soundness.
- **Target label (insula vs mPFC):** string/grep consistency → Consistency; depth/engagement claim licensing → Soundness; cited depth rationale is about insula → Literature.
- **Method parameter (5000 perms, depth 0.8, origin window):** present and justified in-text → Soundness; identical at every mention → Consistency; cited to the right paper and that paper supports it → Literature.
- **Effect-size estimator (Kerby/Wendt):** matches the contrast type → Soundness; label identical across mentions → Consistency; correct primary citation → Literature.
- **Figure/table numbering, dangling main↔SI refs, orphan/phantom citations** → Consistency (sole owner); Soundness only owns "figure shows the wrong quantity."
- **Null framing (`p=0.0942`):** interpretation/equivalence-claim → Soundness; value identity → Consistency; both name the documented design decision in the finding.
- **Pre-registration:** adherence/outcome-switching → Soundness; "pre-specified" label consistency → Consistency; "is it *actually* registered as worded" → QUESTION to author (no agent can confirm from the manuscript alone).

### Coverage gaps to close (not owned by the four sections above)

- **Ethics/registration/reporting-standard surface:** IRB/ethics approval statement, informed consent, trial-registration ID, and a reconstructable recruited→analyzed flow (≈60 → 43). Assign to Soundness/Reproducibility; absence is a MAJOR.
- **Front/back matter:** funding, conflicts of interest, author contributions, data/code availability concreteness (already partly under Soundness — ensure it is actually executed, not assumed).
- **Supplement is reviewed in full, not just for parity** — it must receive its own Soundness and Literature passes (assigned in the fan-out), with its own comments.json and report.
- **QUESTION routing:** items only the author can resolve (true pre-registration status, intentional subset n) are surfaced to the user as an explicit list, not silently parked.

### What "done" looks like (exit conditions for the whole review)

- Every `content[]` block visited; every section has an assigned owner and a recorded verdict (reviewed / no-finding counts as a verdict).
- Number ledger built, normalized, and diffed; zero *unexplained* invariant conflicts remain open (each is a finding or an explicit "different quantity" note).
- Every load-bearing/quantitative citation has a ledger verdict (SUPPORTED/PARTIAL/MISREPRESENTED/UNVERIFIABLE); no load-bearing claim is silently passed.
- Every finding carries severity + dimension + confidence + a unique verbatim anchor + a concrete `old → new` (or precise instruction), with the consulted design-decision or competing explanation named where relevant.
- Duplicates merged to one owner each; no anchor carries two comments for the same defect.
- For each document (main and supplement separately): comments injected, and **injected count == extracted count** verified.
- Reviewed `.docx` and `reports/review/manuscript_review_<version>.md` exist on disk; source `.docx`, `spec.json`, and `references.bib` are byte-identical to before the run.
- Final report-out prints per-document counts (CRITICAL/MAJOR/MINOR/QUESTION) and absolute output paths, plus an explicit **open-items list**: every UNVERIFIABLE citation and every QUESTION the user must resolve — so the human knows exactly what the review could not close.
