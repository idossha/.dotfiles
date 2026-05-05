---
name: eeglab
description: EEGLAB toolbox reference for MATLAB EEG/MEG workflows. Use when writing or reviewing EEGLAB scripts, EEG struct manipulations, ICA/ICLabel pipelines, pop_* calls, clean_rawdata, STUDY analyses, or BIDS-EEG import.
---

# EEGLAB

Use this skill for EEGLAB-specific MATLAB work.

## Core model

EEGLAB revolves around the `EEG` struct. Important fields:

- `EEG.data` — `[chan x pts]` or `[chan x pts x epochs]`
- `EEG.srate` — sampling rate
- `EEG.event` / `EEG.urevent` — event metadata
- `EEG.chanlocs` — channel labels/positions
- `EEG.icaweights`, `EEG.icasphere`, `EEG.icawinv` — ICA decomposition
- `EEG.reject` — rejection masks/flags
- `EEG.etc` — plugin outputs like ICLabel / clean_rawdata

After manual edits, run:

```matlab
eeg_checkset(EEG)
```

## Function families

- `pop_*` — GUI-friendly wrappers and high-level entry points
- `eeg_*` — admin/structure helpers
- signal-processing functions — lower-level operations like ICA, plotting, filtering

Prefer `pop_*` unless the task clearly needs lower-level internals.

## Standard pipeline

1. Load data
2. Import/fix channel locations
3. Remove non-EEG channels
4. Filter continuous data
5. Clean bad channels/artifacts (`clean_rawdata` if appropriate)
6. Re-reference
7. Run ICA on continuous data
8. Classify ICs with ICLabel
9. Remove bad ICs
10. Epoch
11. Baseline/remove additional trials if needed
12. Save

## High-value rules

- Run ICA on **continuous**, not epoched, data.
- High-pass before ICA (often ~1 Hz) for decomposition quality.
- Average reference reduces rank by 1; account for this in ICA/PCA choices.
- Do **not** baseline-correct before ICA.
- Interpolate bad channels **after** ICA component removal, not before.
- Event latencies are in sample points, not seconds.

## Common calls

```matlab
EEG = pop_loadset('filename', 'data.set', 'filepath', '/path/');
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', 40);
EEG = pop_reref(EEG, []);
EEG = pop_runica(EEG, 'icatype', 'runica', 'options', {'pca', -1});
EEG = pop_iclabel(EEG, 'default');
EEG = pop_subcomp(EEG, find(EEG.reject.gcompreject), 0);
EEG = pop_epoch(EEG, {'target'}, [-1 2], 'epochinfo', 'yes');
EEG = pop_saveset(EEG, 'filename', 'processed.set', 'filepath', '/path/');
```

## clean_rawdata reminders

- `BurstCriterion`: lower = more aggressive
- `ChannelCriterion`: neighbor-correlation threshold
- `Highpass`: disable if already filtered intentionally
- `BurstRejection 'on'` rejects windows; `'off'` corrects/preserves length

## ICLabel reminders

Results live in:

```matlab
EEG.etc.ic_classification.ICLabel.classifications
```

Class order:
`[Brain, Muscle, Eye, Heart, LineNoise, ChannelNoise, Other]`

## Don't

- Don’t modify `EEG` fields directly without validating with `eeg_checkset`.
- Don’t assume event latencies are seconds.
- Don’t run ICA after aggressive epoching/baselining unless the user explicitly wants that.
- Don’t interpolate channels before ICA unless there is a very specific reason.

## When reporting

Be concrete about:
- dataset stage (continuous vs epoched)
- reference scheme
- filtering choices
- ICA assumptions
- which `pop_*` functions should be used
