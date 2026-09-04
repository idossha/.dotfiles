---
name: mne-python
description: Use for any MNE-Python EEG, MEG, iEEG, ECoG, fNIRS, eyetracking, source-localization, preprocessing, time-frequency, decoding, statistics, visualization, reporting, file I/O, BIDS-adjacent, or neurophysiology workflow. Trigger when writing, reviewing, debugging, or explaining Python code that imports mne or operates on Raw, Epochs, Evoked, Info, Annotations, ICA, Spectrum, TFR, SourceEstimate, Forward, inverse operators, covariance, montages, events, BEM, source spaces, reports, or MNE-supported formats.
---

# MNE-Python

Use MNE-Python as an object-preserving neurophysiology pipeline. Favor official public APIs, verify exact signatures from the installed version, and keep metadata (`info`, channel names/types, sampling frequency, annotations, events, projections, bads, montage, coordinate frames) synchronized with the data at every step.

## Version Check

Resolve `MNE_SKILL_DIR` to the directory containing this loaded SKILL.md (follow its installed
symlink). This is an explicit task variable, not a required harness-provided environment variable.
Start every nontrivial MNE task by checking the installed version and source location:

```bash
MNE_DONTWRITE_HOME=true MNE_HOME=/tmp/mne-home python "$MNE_SKILL_DIR/scripts/mne_api_lookup.py" --version
```

Use the installed package docstrings/source as the source of truth for signatures. Use the online stable docs only for orientation, because local environments may lag the latest stable release.

## Lookup Workflow

Use the lookup helper before implementing unfamiliar or version-sensitive operations:

```bash
MNE_DONTWRITE_HOME=true MNE_HOME=/tmp/mne-home python "$MNE_SKILL_DIR/scripts/mne_api_lookup.py" mne.io.read_raw_edf
MNE_DONTWRITE_HOME=true MNE_HOME=/tmp/mne-home python "$MNE_SKILL_DIR/scripts/mne_api_lookup.py" mne.io.Raw.filter --source
MNE_DONTWRITE_HOME=true MNE_HOME=/tmp/mne-home python "$MNE_SKILL_DIR/scripts/mne_api_lookup.py" --search raw filter
```

The helper imports MNE with a writable temp config home, prints version/path, resolves functions/classes/methods, and can show signatures, doc summaries, source file locations, and source snippets. Prefer it over guessing.

## Operation Pattern

Follow this order for most pipelines:

1. Read or create data with the correct object type: `Raw` for continuous data, `Epochs` for trials, `Evoked` for averages, `Spectrum`/`TFR` for spectral data, `SourceEstimate` for source data.
2. Inspect `raw.info`, `raw.ch_names`, `raw.annotations`, sampling frequency, channel types, and bad channels before processing.
3. Set channel types, montage, reference, and bad channels before interpolation, filtering decisions, epoching, inverse modeling, or topographic plots.
4. Filter continuous data before epoching when feasible. Resample with care and preserve events using MNE APIs.
5. Detect or derive events from stim channels or annotations, then epoch with explicit `event_id`, `tmin`, `tmax`, `baseline`, `reject`, and `preload` decisions.
6. Apply artifact handling explicitly: annotations/rejection, SSP, regression, ICA, Maxwell filtering, CSD, or interpolation as appropriate for modality and acquisition.
7. Average only after epoch quality control. Compute covariance from a defensible baseline or empty-room/rest segment.
8. For source work, verify trans, BEM/head model, source space, forward solution, noise covariance, rank, reference, and orientation choices before inverse application.
9. Save outputs using MNE writers or domain formats, preserving metadata and documenting irreversible choices.

## API Map

Read `references/api-map.md` for the domain map: imports/readers, Raw/Epochs/Evoked, preprocessing, channels/montages, spectra/TFR, source modeling, inverse/beamforming, statistics, decoding, visualization/reporting, simulation, export, and configuration.

Read `references/gotchas.md` when changing behavior or debugging results. It covers common MNE failure modes: preload, in-place mutation, projections, bads, channel picking, units, event timing, filtering, annotations, baseline, rank, montage/reference, coordinate frames, and plotting backends.

## Implementation Rules

- Import public APIs (`import mne`, `from mne.preprocessing import ICA`) instead of private modules unless patching MNE itself.
- Treat most MNE methods as mutating unless the docs say otherwise. Use `.copy()` before destructive transforms when the original object is still needed.
- Pass named arguments for scientific choices (`l_freq`, `h_freq`, `picks`, `method`, `phase`, `fir_design`, `reject_by_annotation`, `baseline`, `rank`, `n_jobs`).
- Avoid NumPy-only edits of `inst._data` unless no public API exists; if used, update metadata and tests deliberately.
- Prefer MNE pick utilities and `picks=` over manual channel index lists.
- Keep units explicit: MNE stores EEG/MEG data in SI units; many external formats, plots, and sleep tools display microvolts.
- Do not download sample datasets in tests or examples unless the user requested it. Use synthetic `RawArray`/`EpochsArray` for small verification.
- Configure headless plotting in automation (`matplotlib` noninteractive backend; avoid Qt/PyVista windows unless requested).
- For sleep EEG work, preserve annotations, sleep-stage labels, channel names, sampling frequency, and absolute timing through conversions.

## Verification

Use small synthetic data to test code paths:

```python
import numpy as np
import mne

info = mne.create_info(["C3", "C4", "EOG"], sfreq=100.0, ch_types=["eeg", "eeg", "eog"])
raw = mne.io.RawArray(np.random.randn(3, 1000) * 1e-6, info)
raw.set_montage("standard_1020", on_missing="ignore")
events = mne.make_fixed_length_events(raw, id=1, duration=2.0)
epochs = mne.Epochs(raw, events, event_id={"test": 1}, tmin=0, tmax=1.0, baseline=None, preload=True)
evoked = epochs.average()
```

For real-data changes, verify object type, shape, `sfreq`, channel count/order, bads, annotations/events, and any saved file can be read back.
