## Internal consistency

Compare the manuscript with itself and its supplement. Use the resolved document/spec paths from
ingest; no dataset size, anatomical target, result, citation style or analysis parameter is supplied
by this skill. Source each expected fact from the manuscript, protocol/SAP or project records and
record that provenance in the ledger. An unresolved disagreement is a question, not permission to
invent the correct value.

### Number ledger

- Extract numbers once, keyed by quantity, contrast, outcome, group and analysis population. Record
  value, unit, precision, location and source for the expected value.
- Normalize notation and units before comparison. Compare rounded values at their stated precision;
  do not treat ordinary rounding as a different result unless it changes interpretation.
- Separate study-wide invariants from analysis-local values. Reconcile recruited, excluded, analyzed
  and subgroup counts; verify denominators and derived arithmetic independently.
- Diff repeated sample sizes, effects, correlations, p-values, intervals, test statistics, degrees of
  freedom, resample/permutation counts and acquisition/modeling parameters across every section.
- Check coefficient signs against prose, effect-size estimator labels against the contrast, and
  interval levels/methods against Methods. Investigate surprising intervals using the stated method;
  do not assume every valid interval must contain its estimator.
- Check the resolution of reported p-values against the test or simulation procedure. A rounded zero
  needs a justified bound, not a made-up replacement threshold.
- Re-run the ledger after an authorized edit; fixes can introduce new drift.

### Terminology and references

- Derive canonical anatomy, laterality, group/timepoint labels, outcome roles, method names and
  variable definitions from this project's evidence. Flag contradictions; never impose another
  study's terminology or label an anatomical region inherently wrong.
- Apply the document's acronym, spelling, unit and subscript conventions. Definitions must precede
  use where the journal requires them.
- Check every figure, table, panel, equation and section reference in both directions. Numbers and
  labels must identify the intended artifact, with no unexplained gaps, duplicates or orphans.
- Resolve citations using the actual bibliography style and rendered citation map. A supplement may
  have an independent numbering space; verify its convention before comparing.

### Cross-section and supplement parity

- Abstract and significance claims must trace to Results with compatible magnitude and direction.
  Discussion cannot introduce an unreported result or strengthen a qualified result without evidence.
- Verify primary, secondary and exploratory roles against the protocol/SAP, including any documented
  amendments. Report omitted prespecified outcomes and unexplained analysis population changes.
- Reconcile methods and repeated values between main and supplement. An updated main-text number
  does not establish which version is correct; locate the generating analysis or document the gap.
- Every promised sensitivity analysis and availability link must resolve to the claimed content.
- Apply journal/project style requirements only when supplied; generic review must not invent a
  banned-phrase list or require IEEE numbering for another citation style.
