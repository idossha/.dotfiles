## Internal soundness

Judge whether the science holds together on its own terms — before any literature cross-check. Work block-by-block through `spec.json` content; for each claim, trace it to a reported number, a method that produced it, and a figure/table that shows it. Flag every link that is missing, mismatched, or stronger than the evidence supports.

### Claim–evidence traceability

- Extract every declarative claim from Abstract, Significance/Highlights, Results topic sentences, and Discussion; for each, locate the exact reported statistic (test, n, effect size, CI, p, cluster identity) that backs it. A claim with no traceable number is a flag.
- Verify each reported result has a Methods passage describing how it was produced (which test, which contrast, which window, which correction). A number with no method is a flag (e.g. a "pooled all-significant-vertex r = 0.94" with no description of how vertices were selected or pooled).
- Check the direction of every effect matches its claim (increase vs decrease, active vs sham, STIM-vs-PRE vs POST-vs-PRE). Confirm the sign of rank-biserial r and the sign of the field-response Spearman rho agree with the prose.
- Confirm Abstract numbers are identical to body numbers (p-values, n, rho, cluster p). Abstract rounding that changes a threshold crossing (e.g. "p = 0.05" for a body 0.0942) is a flag.
- Ensure no conclusion outruns the contrast that produced it: a within-active STIM-vs-PRE density increase does NOT license "TI increases slow-wave density relative to sham" — that is the secondary between-group claim, which was null.
- Check that hedged Results language ("trend", "directionally consistent") is not silently upgraded to definite language in Discussion/Abstract.
- Verify every quantitative claim in Discussion restates a Results number rather than introducing a new, never-reported statistic.

### Statistical validity for this paper class

- Cluster permutation is cluster-level inference only: confirm the text never calls an individual channel, vertex, or time point "significant." The unit that carries the p-value is the whole cluster. Flag "the peak channel/vertex was significant (p = ...)" — peak location is descriptive, not separately tested.
- Confirm cluster p-values are reported per cluster, with the cluster's spatial/temporal extent described, not a single p applied loosely to a whole map.
- For every cluster test, verify these are stated: number of permutations (5000), one- vs two-sided, the cluster-forming threshold (e.g. p < 0.05, and whether any minimum-extent floor was applied — Fig 5 should state "no minimum-extent floor"), the cluster statistic (mass vs size/extent), and the FWE/max-statistic control (max-cluster-mass). Missing any of these is a flag.
- Confirm the within-test is Wilcoxon signed-rank (paired PRE/STIM/POST) and the between-test is Mann–Whitney U (active vs sham change scores); flag any paired test applied to between-group data or vice versa, or a parametric t-test sneaking in where the Methods promise non-parametric.
- Verify effect-size variant matches the contrast: matched-pairs rank-biserial (Kerby 2014) for within, Wendt 1972 for between. Flag a within-style r reported for a between-group comparison.
- Check bootstrap CIs are subject-level resamples (resampling subjects, not channels/vertices/waves) with the stated 5000 resamples; resampling the wrong unit understates uncertainty and is a flag. Confirm CI and point estimate are consistent (point estimate inside CI; CI not straddling 0 when the effect is called reliable).
- Pseudoreplication / non-independence: confirm channels and vertices are NOT treated as independent observations in any auxiliary computation; the permutation null already handles spatial dependence, but a follow-on correlation or t-test over vertices/channels as if independent is invalid. Source vertices on fsaverage5 are heavily oversampled relative to EEG spatial resolution — flag any per-vertex count used as an n.
- Circular analysis / double-dipping: the "pooled all-significant-vertex" effect size is computed on vertices selected for being significant, so it is upward-biased by construction. Confirm the text frames it as descriptive of the cluster, not as an independent estimate of effect magnitude, and that it is never used to argue the effect is "large." Flag any effect size, CI, or correlation computed on a selection mask derived from the same data's significance.
- Multiplicity across the whole manuscript: tally the number of contrasts × outcomes × figures (sensor density + count, source negative + positive peaks, within + between, STIM-vs-PRE + POST-vs-PRE, field-response, partial-correlation panels). Confirm FWE is controlled within each family and that the paper does not harvest one significant result from a large unstated search. Cluster permutation controls within a map, not across maps — flag if many maps are mined without acknowledgement.
- Regression to the mean / baseline dependence: change scores (STIM−PRE, POST−PRE) are correlated with PRE level. Confirm any field-vs-change or anatomy-vs-change correlation controls for or addresses baseline, and that group differences in change are not artifacts of group differences in PRE. Flag uncorrected change-score correlations presented as response specificity.
- Power and NULL interpretation: the between-group test has n = 11 sham. Confirm p = 0.0942 is reported as "not significant / underpowered," never as evidence of no effect or equivalence. Flag "no difference between active and sham" or "TI did not differ from sham" phrasing — absence of evidence is not evidence of absence, and no equivalence test (e.g. TOST) was run. Confirm the null secondary contrast is reported transparently, not omitted.
- Collinearity in partial correlations: TI_max and TI_normal correlate rho ≈ 0.97. Confirm the partial-correlation claim (TI_normal uniquely predicts response controlling for TI_max, but not vice versa) is presented with the collinearity explicitly disclosed, with subject-level bootstrap CIs, and with appropriate caution that near-collinear predictors make unique-variance attribution unstable. Flag any strong "orientation-specific mechanism" claim that ignores the rho ≈ 0.97 fragility.
- One-sided window and directionality: the origin window is one-sided [−150, 0] ms (rising/leading edge). Confirm this directional choice is justified a priori (Murphy/Massimini traveling-wave rationale) and not a post-hoc pick that maximized the effect. Likewise confirm any one-sided cluster test has a stated directional hypothesis; a one-sided test used opportunistically to cross p < 0.05 is a flag.
- Confirm the inverse/depth choice (sLORETA, depth 0.8) is justified in-text (sLORETA noise-normalized, depth-insensitive per Lin 2006) so a reader cannot read it as an unmotivated knob; if a depth sensitivity analysis was run but trimmed, confirm the remaining text does not over-claim robustness it no longer shows.
- Check exact p-values are reported (not "p < 0.05") for borderline results, and that "p = 0.0942" style precision is consistent across body, abstract, and captions.

### Methods ↔ Results ↔ Conclusion alignment and pre-registration adherence

- Confirm the pre-specified co-primary outcome (slow-wave DENSITY, within-active STIM-vs-PRE and POST-vs-PRE) is reported first and framed as primary; count is labeled supportive, not co-equal.
- Confirm the secondary between-group active-vs-sham contrast is reported and NOT promoted to the headline. Flag any Abstract/Significance sentence that leads with a between-group or sham-controlled claim the data did not support.
- Verify all pre-specified contrasts appear in Results — none silently dropped because they were null. A missing pre-specified contrast is a flag even if reported elsewhere only as a number.
- Check for outcome-switching: the Methods' named primary outcome must match the Discussion's emphasized outcome. Flag if a secondary or exploratory result (e.g. frontal HF_max → global density, or SWA spectral analyses) is elevated to a primary conclusion.
- Confirm exploratory analyses are labeled exploratory and not presented with confirmatory language; post-hoc analyses should be flagged as hypothesis-generating.
- Verify the analysis n (43; 32 active, 11 sham) and any per-analysis n (e.g. field modeling subset) are stated where used, and that contrasts use the n the Methods specify. Flag silent n changes between analyses without explanation of exclusions.
- Confirm the target is consistently the LEFT INSULA throughout (deep target); flag any residual "mPFC"/"prefrontal" mislabel from earlier drafts in body, captions, or figure text.

### Figure/data support

- For each figure, confirm it actually displays the quantity the citing sentence claims (e.g. Fig 3 shows channel-wise density cluster maps for the named contrasts; Fig 5 shows vertexwise field-vs-response plus the partial-correlation panel). A sentence citing a figure that shows something else is a flag.
- Verify every figure/panel states: axis labels with units, what the error bars/shaded bands represent (SD vs SEM vs bootstrap CI), the n, and the contrast. Undefined error bars are a flag.
- Confirm caption statistics equal body statistics for the same result (cluster p, rho, r, n). Mismatched p between caption and text is a flag.
- Confirm color-scale meaning and thresholds are disclosed: what the colormap encodes (t-stat? rank-biserial? field magnitude?), the cluster-forming threshold used for the displayed mask, and whether non-significant vertices/channels are masked or shown. Flag maps where the displayed extent could be mistaken for the significant cluster without a stated threshold.
- Confirm significant clusters are visually distinguished from the full statistic map, so readers do not read the whole colored region as significant.
- Check that any "peak" marker (peak channel, peak vertex, peak latency) in a figure is captioned as descriptive/illustrative, consistent with the cluster-level-only inference rule above.
- Verify figure counts and cross-references resolve (every "Fig N"/"Fig SN" in text points to an existing figure; no dangling main→SI references; supplement figure numbering is internally consistent across the separate supplement docx).
- Confirm numbers shared between main text and supplement match (e.g. LOSO field rho ranges) — a stale supplement value contradicting a refreshed main-text value is a flag.

### Overclaiming and mechanism

- Confirm causal language is licensed by design: within-subject PRE→STIM→POST change without a significant sham contrast supports "associated with"/"during stimulation," not "TI causes/drives/enhances." Flag causal verbs attached to the null between-group result.
- Flag banned/unsupported mechanistic phrasing — e.g. "membrane-relevant," cellular/ionic-mechanism claims, "entrainment"/"phase-locking" (ISPC is not in this paper), or direct-neural-modulation claims — unless an in-paper measurement supports them. The field models exposure, not a measured neural mechanism.
- Confirm "depth advantage"/"reaches deep insula" claims are framed as modeled field exposure, not demonstrated focal neural engagement; the correlation is exposure-vs-response, not proof of insular origin of the effect.
- Check that orientation-specificity ("surface-normal field component drives response") is hedged given rho ≈ 0.97 collinearity and is not stated as an established mechanism.
- Verify generalizability is bounded: claims are limited to this montage, this 1 Hz beat, this left-insula target, this sleep stage, and this sample (predominantly the recruited cohort). Flag sweeping "TI modulates deep brain activity" generalizations from one montage/target.
- Confirm the slow-wave-density finding is not silently equated with a spectral SWA / delta-power claim (different outcome; Schaeffer-style spectral analyses are exploratory here).
- Check Significance/impact statements do not assert clinical or functional benefit (memory, cognition, sleep quality) that was not measured.
- Confirm Schaeffer et al. is cited as a plain reference, never "parent study"/"re-analysis," and that the relationship of datasets is not overstated.

### Reproducibility surface

- Verify the manuscript states software and versions for each endpoint: YASA (detection params: amplitude/duration/frequency criteria), MNE-Python (inverse = sLORETA, depth 0.8, fsaverage5), SimNIBS 4 / CHARM, and the cluster-permutation implementation. Missing versions are a flag.
- Confirm all thresholds and tunable parameters are in-text or supplement: 5000 permutations, cluster-forming p, FWE method, origin window [−150,0] ms, depth weighting, adjacency definition (sensor neighbors; fsaverage5 source adjacency), outlier cutoff (modified z 3.5).
- Check that random-seed handling is specified or that the permutation/bootstrap results are stated as stable (5000 perms/resamples) — irreproducible seeds for borderline p-values (0.0942) are a flag.
- Confirm slow-wave detection and same-wave dedup rules are described concretely enough to reproduce (e.g. most-negative reference-channel dedup; window-based clustering), not just cited.
- Verify the inverse modeling chain is reproducible: forward model source (individual SimNIBS vs template), coregistration, noise covariance estimation, and how subject source estimates were morphed to fsaverage5.
- Confirm data and code availability statements are concrete: a repository/DOI, what is shared (derived metrics vs raw EEG), and access conditions. "Available on request" without specifics is a flag; note BIDS data location is internal (`/Volumes/...`) and not a public link.
- Check unit and definition consistency for derived metrics across Methods/Results (density = waves per unit time on stated basis; W = D × N defined once and used consistently; TI_max vs TI_normal defined before first use).
- Confirm exclusions and the path from ~60 recruited to n = 43 analyzed are documented (counts, reasons), so the analyzed sample is reconstructable.
