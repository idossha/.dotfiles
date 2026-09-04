## Internal soundness

Trace scientific claims to evidence in the target manuscript, its protocol/SAP and analysis records.
Apply checks only to methods actually used. Missing evidence stays an explicit gap; expected results
and study-specific decisions never come from this shared skill.

### Claim and design

- Trace each load-bearing claim to a result and the method that produced it. Check effect direction,
  analysis population, contrast, uncertainty and figure support.
- Distinguish association, causation, mechanism and clinical benefit. Assess what the design identifies;
  a measured exposure or model prediction alone does not demonstrate a biological mechanism.
- Compare reported outcome roles and contrasts against the protocol/SAP and dated amendments.
  Flag selective reporting, outcome switching and exploratory work described as confirmatory.
- A nonsignificant test alone establishes neither equivalence nor inadequate power. Check the effect
  estimate, uncertainty, design and any actual equivalence/power analysis before choosing wording.
- Scope generalizations to the sampled population, intervention, acquisition and measured endpoints.

### Statistical checks, when applicable

- Verify test assumptions and pairing, independence, missing-data handling and analysis unit. Check
  that repeated channels, vertices, trials or waves are not mistaken for independent participants.
- For cluster inference, distinguish a cluster-level result from unsupported localization to an
  individual channel, vertex or latency. Verify the null, sidedness, permutation scheme, cluster
  threshold/statistic, multiplicity correction and reported simulation resolution.
- For bootstrap/permutation inference, check that resampling respects the experimental unit and
  dependence structure. Read the stated interval method before judging interval/estimate relations.
- Check effect-size definitions against the contrast and estimator. Selection on significance can
  bias a subsequent effect size, interval or correlation; distinguish descriptive from independent
  estimation and look for held-out or properly adjusted evidence.
- Inventory multiplicity across contrasts, outcomes, maps and model selection. Correction within a
  map does not establish control across an unstated search.
- Investigate change-score/baseline dependence, regression to the mean, confounding and missingness.
  Do not prescribe an adjustment without considering the estimand and design.
- Assess collinearity and the stability of unique-effect claims using this dataset's diagnostics.
  No universal correlation value or expected dose relation is assumed.
- Check directional hypotheses and analysis windows against prespecification or explicit exploratory
  labeling. Do not assume a one-sided window or a particular inverse-model setting is required.
- Check model diagnostics, robustness analyses and parameter justifications that the manuscript
  claims. A trimmed analysis cannot support a remaining claim of demonstrated robustness.

### Figure and reproducibility support

- Figures must show the quantity cited, with units, population/contrast, uncertainty definitions,
  statistic/color-scale meaning and any selection/threshold masking disclosed.
- Verify numeric figure assertions from data or rendered measurements where available. Appearance
  alone does not establish a quantitative result. Route rendering tests to the offscreen testing skill.
- Check software versions, tunable parameters, random-state handling, preprocessing/exclusion logic
  and model transformations needed to reproduce each endpoint.
- Reconstruct the participant/sample flow and analysis-specific exclusions from recorded evidence.
- Confirm data/code availability statements identify actual artifacts and access conditions. A local
  filesystem path is not a public source. Record access gaps without inventing a mandatory policy.
