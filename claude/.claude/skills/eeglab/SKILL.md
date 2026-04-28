---
name: eeglab
description: >-
  EEGLAB toolbox reference for EEG/MEG processing in MATLAB. Use when writing
  or modifying EEGLAB scripts, working with the EEG struct, ICA, clean_rawdata,
  ICLabel, pop_* functions, STUDY designs, or BIDS-EEG import. Covers the EEG
  structure, preprocessing pipeline, plugin API, and function lookup.
user-invocable: false
---

# EEGLAB Reference

EEGLAB is an open-source MATLAB toolbox for EEG/MEG signal processing. It provides GUI and command-line functions for continuous and event-related analysis including ICA.

**Repository:** github.com/sccn/eeglab (default branch: `develop`)
**Submodules:** dipfit, clean_rawdata, ICLabel, firfilt, EEG-BIDS, tutorial_scripts
Clone with `--recurse-submodules`; update with `git submodule update --init --recursive --remote`.

**Startup modes:** `eeglab` (GUI), `eeglab nogui` (headless), `eeglab redraw` (refresh), `eeglab rebuild` (close+rebuild).

## The EEG Structure

All processing revolves around the `EEG` struct:

| Field | Type | Description |
|-------|------|-------------|
| `data` | `[chan x pts]` or `[chan x pts x epochs]` | Raw data matrix |
| `nbchan`, `pnts`, `trials` | int | Dimensions (trials=1 for continuous) |
| `srate` | float | Sampling rate in Hz |
| `xmin`, `xmax` | float | Epoch time bounds in seconds |
| `times` | vector | Latency vector in milliseconds |
| `chanlocs` | struct array | Channel names/locations |
| `event` | struct array | Events with `.type`, `.latency`, `.duration` |
| `urevent` | struct array | Original events before any rejection |
| `epoch` | struct array | Epoch metadata (only when epoched) |
| `ref` | string/int | Reference type (`'common'`, `'averef'`, channel index) |
| `icaweights` | matrix | ICA unmixing weights |
| `icasphere` | matrix | ICA sphering matrix |
| `icawinv` | matrix | ICA inverse (mixing) matrix |
| `icaact` | matrix | Component activations (may be empty; recomputed on demand) |
| `dipfit` | struct | Dipole model for ICA components |
| `reject` | struct | Rejection marks (`.gcompreject` = flagged components) |
| `etc` | struct | Miscellaneous (ICLabel results stored here) |
| `history` | cell | Command history for reproducibility |

Always call `eeg_checkset(EEG)` after modifying the structure.

## Three Function Categories

1. **`pop_*`** (`functions/popfunc/`): GUI wrappers — show dialogs, call processing, return `[EEG, LASTCOM]`.
2. **`eeg_*`** (`functions/adminfunc/`, `functions/popfunc/`): Structure manipulation/validation (`eeg_checkset`, `eeg_epoch`, `eeg_store`).
3. **Processing** (`functions/sigprocfunc/`, `functions/timefreqfunc/`): Signal processing (`runica`, `topoplot`, `spectopo`, `eegfilt`).

## Plugin Architecture

Plugins live in `plugins/` and register via `eegplugin_[name].m`.

Install programmatically:
```matlab
% plugin_askinstall(name, function, interactive) — 0=silent, 1=prompt
plugin_askinstall('ICLabel', 'iclabel', 0);
plugin_askinstall('clean_rawdata', 'clean_artifacts', 0);
plugin_askinstall('firfilt', 'pop_eegfiltnew', 0);
plugin_askinstall('picard', 'picard', 0);
plugin_askinstall('dipfit', 'pop_dipfit_settings', 0);
```

## Standard Preprocessing Pipeline

```matlab
% 1. Load data
EEG = pop_loadset('filename', 'data.set', 'filepath', '/path/');

% 2. Import channel locations
EEG = pop_chanedit(EEG, 'lookup', 'standard-10-5-cap385.elp');

% 3. Remove non-EEG channels
EEG = pop_select(EEG, 'nochannel', {'EXG1','EXG2','EXG3','ECG','EMG'});

% 4. Average reference
EEG = pop_reref(EEG, []);

% 5. Clean data (clean_rawdata plugin)
EEG = pop_clean_rawdata(EEG, ...
    'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', [0.25 0.75], ...
    'BurstCriterion', 20, 'WindowCriterion', 0.25, ...
    'BurstRejection', 'on', 'Distance', 'Euclidian', ...
    'WindowCriterionTolerances', [-Inf 7]);

% 6. Re-reference after bad channel removal
EEG = pop_reref(EEG, []);

% 7. ICA (pca -1 accounts for rank reduction from avg ref)
EEG = pop_runica(EEG, 'icatype', 'runica', 'options', {'pca', -1});

% 8. ICLabel classification
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag(EEG, [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN]);

% 9. Remove flagged components
EEG = pop_subcomp(EEG, find(EEG.reject.gcompreject), 0);

% 10. Extract epochs
EEG = pop_epoch(EEG, {'target','standard'}, [-1 2], 'epochinfo', 'yes');
EEG = eeg_checkset(EEG);

% 11. Remove baseline
EEG = pop_rmbase(EEG, [-1000 0]);

% 12. Save
EEG = pop_saveset(EEG, 'filename', 'processed.set', 'filepath', '/path/');
```

## clean_rawdata (ASR) Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FlatlineCriterion` | 5 | Max flatline seconds before channel removal |
| `ChannelCriterion` | 0.8 | Min correlation with neighbors (0-1) |
| `LineNoiseCriterion` | 4 | Max line noise in std devs |
| `Highpass` | [0.25 0.75] | Transition band for ~0.5Hz HP. `'off'` if pre-filtered |
| `BurstCriterion` | 20 | ASR threshold (std devs). 5=aggressive, 20=conservative |
| `BurstRejection` | `'on'` | `'on'`=reject, `'off'`=correct via ASR (preserves length) |
| `WindowCriterion` | 0.25 | Max fraction contaminated channels per window |
| `WindowCriterionTolerances` | [-Inf 7] | Power tolerance bounds |
| `Distance` | `'Euclidian'` | `'Euclidian'` or `'Riemannian'` |

Any parameter can be `'off'`. Order: flatlines → highpass → bad channels → ASR → bad windows.
Results: `EEG.etc.clean_channel_mask`, `EEG.etc.clean_sample_mask`.

**Two-pass strategy for noisy data:**
1. Pass 1 (mild): `BurstCriterion=40` — remove bad channels + extreme artifacts
2. Run ICA + ICLabel
3. Pass 2 (aggressive): `BurstCriterion=20`

## ICLabel Reference

```matlab
EEG = pop_iclabel(EEG, 'default');
% Results: EEG.etc.ic_classification.ICLabel.classifications (N x 7)
% Columns: [Brain, Muscle, Eye, Heart, LineNoise, ChannelNoise, Other]
```

Versions: `'default'` (recommended), `'lite'` (faster), `'beta'` (legacy).

`pop_icflag` threshold: 7x2 matrix, each row = `[min max]` probability. `NaN NaN` = skip.
```matlab
% Flag Muscle>90% and Eye>90%
EEG = pop_icflag(EEG, [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN]);
% Flag Brain<20%
EEG = pop_icflag(EEG, [0 0.2; NaN NaN; NaN NaN; NaN NaN; NaN NaN; NaN NaN; NaN NaN]);
% Remove
EEG = pop_subcomp(EEG, find(EEG.reject.gcompreject), 0);
```

## ICA Best Practices

| Algorithm | `'icatype'` | Notes |
|-----------|-------------|-------|
| Infomax | `'runica'` | Default MATLAB |
| Picard | `'picard'` | Faster, same objective. Recommended. Plugin required. |
| Binary Infomax | `'binica'` | Compiled C, faster |
| JADE | `'jader'` | |
| SOBI | `'sobi'` | Second-order blind identification |

- High-pass at 1-2 Hz before ICA (critical for quality)
- Average ref reduces rank by 1 → use `'pca', -1`
- Run on continuous data, not epoched
- Do NOT baseline-correct before ICA
- Data requirement: ~30*N² samples (N = channels)

## Filtering

```matlab
% FIR (firfilt plugin — preferred)
EEG = pop_eegfiltnew(EEG, 'locutoff', 1);                        % HP
EEG = pop_eegfiltnew(EEG, 'hicutoff', 40);                       % LP
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', 40);       % BP
```

Always filter continuous data before epoching.

## Re-Referencing

```matlab
EEG = pop_reref(EEG, []);        % Average reference
EEG = pop_reref(EEG, [1 2]);     % Channels 1 and 2
EEG = pop_reref(EEG, 'Cz');      % Named channel
```

Average ref reduces rank by 1 (important for ICA). Re-reference BEFORE ICA.

## Channel Interpolation

Do AFTER ICA component removal (interpolating before degrades decomposition).
```matlab
EEG = pop_interp(EEG, EEG.urchanlocs, 'spherical');  % From original montage
EEG = pop_interp(EEG, [12 48], 'spherical');          % Specific channels
```

Pipeline position: clean_rawdata → reref → ICA → ICLabel → remove comps → **interpolate** → reref → epoch.

## Event Manipulation

Event latencies are in sample points (1-indexed). Convert: `latency_sec = EEG.event(i).latency / EEG.srate`.

```matlab
EEG = pop_importevent(EEG, 'event', 'events.txt', 'fields', {'latency','type'});
EEG = eeg_checkset(EEG, 'eventconsistency');
```

## STUDY-Level Analysis

```matlab
% From BIDS
[STUDY, ALLEEG] = pop_importbids(filepath, 'eventtype', 'trial_type', ...
    'bidsevent', 'on', 'bidschanloc', 'on', 'studyName', 'MyStudy');

% Design
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name', 'Design1', ...
    'variable1', 'type', 'values1', {'target','standard'}, ...
    'vartype1', 'categorical', 'subjselect', STUDY.subject);

% Precompute
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {}, 'savetrials', 'on', ...
    'rmicacomps', 'on', 'interp', 'on', 'recompute', 'on', 'erp', 'on');

% Plot
STUDY = pop_erpparams(STUDY, 'topotime', 350);
STUDY = std_erpplot(STUDY, ALLEEG, 'channels', {ALLEEG(1).chanlocs.labels}, 'design', 1);
```

## Code Style (EEGLAB conventions)

- 2-space indentation (spaces, not tabs)
- No space between function name and parenthesis: `eeg_checkset(EEG)`
- One space after commas in argument lists
- `pop_*` return `[EEG, LASTCOM]` where LASTCOM is the command string for history

## Testing

No centralized test suite. Manual validation:
1. `eeglab nogui` loads without errors
2. Load sample data: `EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', 'sample_data/')`
3. Run the modified function
4. Validate with `EEG = eeg_checkset(EEG)`

## Menu-to-Function Reference

See the full mapping in [menu-reference.md](/Users/idohaber/.claude/skills/eeglab/menu-reference.md).

Key functions:
- **Load/Save:** `pop_loadset`, `pop_saveset`, `pop_fileio`, `pop_biosig`
- **BIDS:** `pop_importbids` (EEG-BIDS plugin)
- **Filter:** `pop_eegfiltnew` (firfilt), `pop_eegfilt` (legacy)
- **Reref:** `pop_reref`
- **Clean:** `pop_clean_rawdata`, `pop_rejchan`, `pop_rejcont`
- **ICA:** `pop_runica`, `pop_iclabel`, `pop_icflag`, `pop_subcomp`
- **Epoch:** `pop_epoch`, `pop_rmbase`
- **Select:** `pop_select`, `pop_rmdat`, `pop_selectevent`
- **Plot:** `pop_eegplot`, `pop_spectopo`, `pop_topoplot`, `pop_prop`, `pop_erpimage`, `pop_newtimef`
- **Interpolate:** `pop_interp`
- **Merge:** `pop_mergeset`
