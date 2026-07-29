## Internal consistency

Goal: catch the manuscript contradicting *itself*. These checks need no external literature — only the manuscript and its supplement. Work from `paper/spec.json` (iterate `content[]`, reading every `body.text`, `heading.text`, and `figure` caption) plus the supplement spec. Emit each contradiction as a `comments.json` object anchored on a verbatim substring of the offending block.

### Build a number ledger first (do this before any prose review)
- Extract every numeric token in the manuscript into a ledger keyed by *quantity*, recording value + location (block index, section, Abstract/Results/Discussion/caption/Methods/Supplement). Then diff within each key: any key with >1 distinct value is a flag unless the values legitimately denote different things.
- Normalize before diffing: strip thousands separators, unify `0.05`/`.05`, `p = 0.0942`/`p=.094`, percentages vs proportions (`32/43` vs `74%`), and en/em-dash ranges (`0.56–0.66`) so `0.56-0.66` and `0.56 to 0.66` collide in the same key.
- Tag each number with whether it should be *globally invariant* (n, channel count, permutation count, beat Hz) vs *context-local* (a per-contrast p-value). Invariants that differ anywhere are hard errors; locals only conflict when they share a contrast+outcome+group.
- Re-run the ledger diff after any edit pass — number drift is most often introduced *while fixing something else*.

### Quantitative reconciliation
- **Sample size and its decomposition** must read identically everywhere: `n = 43` total, `32 active + 11 sham`. Verify 32 + 11 = 43 wherever the split appears; flag any stray `n = 42`, `n = 60` (recruited ≠ analyzed — make sure recruited/excluded counts are labeled as such and not conflated with the analyzed n), or a figure caption that says "n = 30 active."
- Confirm per-analysis n is internally consistent: if a sub-analysis drops subjects (e.g. field modeling on fewer subjects, or active-only n = 32 for within-active contrasts), every mention of that sub-n agrees and the drop is reconciled against 43.
- **p-values**: the same contrast must carry the same p in Abstract, Results, caption, and Supplement. The secondary between-group density p must be `0.0942` everywhere (not `0.09`, `0.094`, `~0.1`, or silently "ns" in one place and a number in another). Flag any p reported as `0` or `p = 0.000` (use `< 0.001`), and any `p < 0.05` in text where a caption gives an exact p that is actually `> 0.05`.
- **Effect sizes**: rank-biserial r (Kerby within / Wendt between) for a given contrast must match across text and captions; check the *labeled* estimator is consistent (don't let a Wendt between-group r get reported next to a "matched-pairs" descriptor). Watch the documented trap where the main-text pooled source r (e.g. 0.91–0.95) differs from a group-level r (e.g. 0.86) — confirm the manuscript uses one consistently and never swaps them between sentences.
- **Correlations**: Spearman rho values (field-vs-response), the dose-collinearity `rho ≈ 0.97` (TI_max vs TI_normal), and any partial-correlation coefficients match across Methods/Results/caption. Verify the sign of every rho/r is consistent with the prose ("positive association" must not sit next to a negative coefficient).
- **Confidence intervals**: each bootstrap 95% CI matches its point estimate everywhere it appears, the CI brackets the point estimate, and resample count (`5000`) is stated identically; flag a CI in the caption that differs from the same CI in Results.
- **Permutation count** (`5000`) and **cluster thresholds** (cluster-forming `p < 0.05`, max-cluster-mass FWE `< 0.05`) are quoted identically in Methods, Results, and captions — no stray `1000`/`10000`.
- **Counts of things**: channel count (`182`), electrode montage numbers, vertex/source counts (fsaverage5), cluster sizes/extents, and number-of-significant-clusters must agree between Methods, captions, and any Supplement table.
- **Acquisition/stimulation parameters**: beat frequency (`1 Hz`), carrier frequencies, current amplitude (mA), epoch/window timings (e.g. origin window `[-150, 0] ms`), sampling rate, filter bands — each value identical at every mention; flag a Methods value that a caption or Discussion contradicts.
- **Degrees of freedom / test statistics**: where df or U/W statistics appear, they are consistent with the stated n and identical across mentions.
- Verify derived arithmetic the paper states: percentages recomputed from their stated numerator/denominator (e.g. a "74%" must equal its `32/43`), means consistent with reported ranges, and any "increase of X%" consistent with the before/after values given elsewhere.

### Terminology and naming
- **Anatomical target**: must be the **left insula** everywhere. Grep every block for `mPFC`, `medial prefrontal`, `prefrontal target` — any survivor is a stale mislabel and a hard flag. Also flag vague drift ("the deep target," "the cortical site") that contradicts the named insula.
- **Contrast labels** are verbatim-stable: `STIM-vs-PRE` and `POST-vs-PRE` (not `stim/pre`, `during-vs-baseline`, `STIM–PRE` in one place and `STIM vs. PRE` in another). Pick the manuscript's canonical form and flag deviations.
- **Outcome roles** are consistent: slow-wave **density = primary / co-primary**, **count = supportive/supporting** — never let count be called "primary" or density demoted anywhere. Confirm the "co-primary" pair is always the two within-active time contrasts, and the between-group active-vs-sham is always labeled **secondary/control**, never "primary."
- **Variable names** stable with correct subscript formatting: `TI_max`, `TI_normal`, `HF_max` (or their rendered subscript forms) — same casing and same subscript everywhere; flag `TImax`/`TI-max`/`TI normal`/`HFmax` variants and any base-italic-breaks-the-subscript rendering issue.
- **Acronyms** defined exactly once at first textual use, then reused (TI, SWA, SW, LOSO, FWE, sLORETA, YASA, ICA, fsaverage5). Flag: used-before-defined, redefined later, defined twice, or expanded again after definition.
- **Method names** consistent: sLORETA depth weighting `0.8` described the same way; "cluster-based permutation" / "Maris & Oostenveld" framing identical; "wave-weighted density (W = D × N)" formula and naming identical at every mention.
- **Group labels** (`active`/`sham`) and **epoch labels** (`PRE`/`STIM`/`POST`) use one casing/spelling convention throughout, including figure captions and axis-label descriptions.

### Cross-references
- Every `Figure N` / `Table N` / `Eq. N` / `Section` pointer in body text resolves to an artifact that exists, and points to the *correct* one (a sentence describing a source map must not reference the sensor figure).
- Each `figure` block's stated/implicit number matches the number used to cite it in text; with docx auto-numbering, verify no figure block is missing an explicit number (which silently mis-advances the counter and renders the wrong "Figure N.").
- Figure/table numbering is gap-free and monotonic in document order (no skipped "Figure 5" then "Figure 7," no two "Figure 4"s).
- **Supplement refs S1…S7**: every main→`Figure S#` pointer exists in the supplement and vice versa; after any renumber, confirm no **dangling main→SI** or **SI→main** reference and no off-by-one (text says "Fig S3" but the panel moved to S4).
- Every figure and table is **cited at least once** in text, and every in-text figure/table citation has a corresponding artifact — both directions. List orphan figures (exist, never cited) and phantom citations (cited, missing).
- Panel-letter references resolve: if text cites "Fig 5C," the figure has a panel C and it shows what the text claims.
- In-text citation numbers `[n]` fall within the bibliography range and resolve to the intended entry; flag any `[n]` exceeding the reference-list length.

### Section coherence
- **Abstract ↔ Results**: every quantitative claim and direction in the Abstract appears in Results with matching numbers; the Abstract introduces no result absent from the body, and omits no headline result the body calls primary.
- **Significance/Impact statement ↔ Abstract**: the significance statement's claims are a consistent (not stronger) restatement of the Abstract — no causal/clinical overclaim the Abstract doesn't support.
- **Discussion ↔ Results**: every Discussion claim traces to a reported result; flag *new* quantitative results introduced only in the Discussion (numbers that never appear in Results). Interpretations must not invert the sign/direction of the result they cite.
- **Limitations ↔ actual nulls**: the secondary between-group null (density active-vs-sham `p = 0.0942`) and any other reported null (e.g. SWA between-group, origin diffuseness) are acknowledged in Limitations/Discussion and not silently dropped or reframed as positive. Flag an Abstract/Conclusion that implies the between-group effect was significant.
- **Conclusion ↔ body**: the closing claims match what Results actually showed at the stated effect sizes; no escalation from "within-active increase" to "TI causes" beyond what the design supports.
- Confirm the pre-specification framing is consistent: where the text invokes the protocol's pre-specified co-primary contrasts, the same outcomes/contrasts are called pre-specified everywhere (no post-hoc analysis relabeled as pre-specified in one section).

### Main ↔ Supplement parity
- For every value that exists in both documents (LOSO ranges, effect-size ranges, per-contrast p-values, n, field-correlation ranges), diff main vs supplement and flag mismatches. **Classic trap to check explicitly**: a LOSO/effect range refreshed in the main text (e.g. field LOSO updated to `0.56–0.66`) but left **stale** in the supplement (still `0.47–0.56`). Treat any main↔SI numeric divergence as stale-supplement until proven otherwise.
- Shared methods are described *compatibly* across documents: permutation count, sLORETA depth, origin window, cluster thresholds, adjacency definition, outlier rule (modified z, cutoff 3.5) — the supplement must not state a different parameter than Methods.
- Any sensitivity/robustness analysis the main text says was run (e.g. depth 0.8-vs-3.0, sample-size-matched subsampling) is actually present and consistent in the supplement if the main text points there; flag a main-text "see Supplement" whose target content is missing.
- Supplement tables that re-list main-text clusters use the same cluster IDs, p-values, and extents as the main figures.

### Surface consistency
- **Units** uniform and correct per quantity: ms vs s, Hz, mA vs µA, mm; flag a value given in mixed units across mentions of the same quantity.
- **Rounding / significant figures** consistent for a quantity class: don't report `p = 0.0942` once and `p = 0.09` elsewhere, or rho to 2 decimals here and 3 there; pick the document's convention and flag outliers.
- **Sign conventions** consistent: negative/positive peak terminology for slow waves, and the sign of field/response correlations, used the same way throughout.
- **Tense**: Methods/Results in consistent past tense; flag tense drift mid-section.
- **Hyphenation/spelling** stable: `slow-wave` vs `slow wave`, `source-space` vs `source space`, `between-group`, US/UK spelling — one convention; also enforce the banned phrasing rules (e.g. no "membrane-relevant," no "parent study"/"re-analysis" for the prior TES-TI sleep paper).
- **Reference list ordering** matches the numeric IEEE style: entries numbered in order of first in-text appearance, the list is contiguously numbered, and no duplicate bibliography entries for the same work (which would split citations across two numbers).
- Watch rendering artifacts when anchoring comments: citations render as `[n]`, em-dashes and non-breaking spaces are literal characters in `body.text` — copy anchors verbatim from the spec, not from a reflowed reading.
