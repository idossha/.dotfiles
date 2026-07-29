# MNE-Python Gotchas

## Version And Configuration

- Importing MNE may read or write `~/.mne/mne-python.json`. In restricted environments, set `MNE_DONTWRITE_HOME=true` and `MNE_HOME` to a writable temp path before import.
- Stable online docs may be newer than the installed package. Inspect local signatures and docstrings before coding.
- Optional dependencies affect behavior: PyVista/Qt for 3D/browser plotting, EDFlib/pybv/neo-style dependencies for some formats, scikit-learn for decoding.

## Mutability And Preload

- Many MNE instance methods mutate and return `self`. Call `.copy()` when keeping the original object.
- Some operations require `preload=True` or `inst.load_data()`, especially filtering, resampling, ICA, and direct data access.
- Cropping/resampling changes time axes and may affect event alignment; use MNE methods that update metadata.

## Channels And Units

- MNE stores data in SI units. EEG/EOG/ECG arrays are volts, so microvolt data must be multiplied by `1e-6`.
- Channel names must match exactly for montages, adjacency, interpolation, concatenation, and combining runs.
- Set channel types before referencing, ICA, CSD, topomaps, or artifact detection.
- Bad channels in `info["bads"]` are excluded by many operations; be explicit with `exclude` and `picks`.

## Annotations, Events, And Timing

- Annotation `onset` is in seconds and interacts with `raw.first_samp` and measurement date.
- `events` sample indices must remain aligned after resampling/cropping; prefer `Raw.resample(events=events)` when available.
- `reject_by_annotation=True` can silently drop spans/epochs marked bad; inspect `drop_log`.
- Sleep-stage labels are often annotations. Preserve descriptions and absolute timing through format conversions.

## Filtering And Resampling

- Filter continuous data before epoching when possible to reduce edge artifacts.
- Choose FIR/IIR, transition bandwidth, phase, and notch strategy deliberately; do not rely on defaults for publication-grade analysis.
- Avoid filtering already epoched short windows unless edge effects are acceptable and documented.
- Resampling before event extraction can shift stim edges; decide whether events should be detected before or after resampling.

## Baseline, Reference, And Rank

- Baseline correction is not a substitute for high-pass filtering, and high-pass filtering is not a substitute for baseline correction.
- EEG source localization generally requires an average reference or appropriate reference modeling.
- Rank changes after SSP, ICA, Maxwell filtering, interpolation, average reference projections, and channel removal. Pass/inspect `rank` for covariance and inverse workflows.
- Applying projectors at different stages changes rank and data; document when projections are active.

## Source Localization

- Coordinate frames must match: head, MRI, device, and MNI transforms are not interchangeable.
- Verify BEM/source space/trans visually with `mne.viz.plot_alignment` before trusting a forward model.
- Use the same channel set/order and projectors consistently across evoked, covariance, forward, and inverse objects.
- Noise covariance should match the data rank and preprocessing state.

## DataFrames And External Tools

- `to_data_frame` may scale data for readability; check `scalings` and units before feeding results into statistics or ML.
- External sleep/EEG libraries often expect microvolts and simple channel names; convert explicitly at boundaries.
- Export formats may lose annotations, bads, projectors, montage, or coordinate transforms. Round-trip test important exports.

## Testing

- Prefer synthetic `RawArray` and fixed-length events for unit tests.
- Assert metadata as well as numeric shapes: channel order, `sfreq`, `times`, `event_id`, bads, annotations, and object type.
- Avoid network dataset downloads in automated tests unless intentionally marked slow/integration.
