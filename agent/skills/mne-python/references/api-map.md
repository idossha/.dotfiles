# MNE-Python API Map

This map is orientation, not a replacement for installed docstrings. Check exact signatures with `scripts/mne_api_lookup.py`.

## Documentation Sources Checked

- Official stable homepage: https://mne.tools/stable/index.html
- Official stable API reference: https://mne.tools/stable/api/python_reference.html
- Official documentation overview/tutorial index: https://mne.tools/stable/documentation/index.html
- Official source repository: https://github.com/mne-tools/mne-python
- Local installed package inspected during skill creation: MNE 1.11.0 at `/Users/idohaber/Library/Python/3.14/lib/python/site-packages/mne`

The official stable docs observed on 2026-05-30 were MNE 1.12.1, while this project environment had MNE 1.11.0 installed. Verify version-sensitive APIs locally.

## Core Objects

- `mne.io.Raw` / `mne.io.BaseRaw`: continuous sensor recordings; main operations include cropping, filtering, resampling, channel picking, annotations, event extraction, PSD, plotting, saving, and conversion to DataFrame.
- `mne.Epochs` / `mne.BaseEpochs`: segmented data around events; main operations include rejection, baseline handling, metadata, averaging, time-frequency, equalization, plotting, and export.
- `mne.Evoked`: averaged responses; main operations include combining conditions, baseline, channel operations, whitening, topomaps, joint plots, and inverse/source application.
- `mne.Info`: acquisition metadata; keep it consistent with channel names/types, sampling frequency, bads, projections, dig points, montage, device/head transforms, and measurement date.
- `mne.Annotations`: time spans with descriptions; use for bad segments, sleep stages, breaks, and event derivation.
- `mne.Covariance`, `mne.Forward`, `mne.SourceSpaces`, `mne.SourceEstimate`, `mne.Report`: covariance, forward model, source grid/surface, source time courses, and reproducible reporting.

## Reading Data

Use `mne.io.read_raw(...)` for auto-detected formats when appropriate, or format-specific readers such as:

- EEG/PSG: `read_raw_edf`, `read_raw_bdf`, `read_raw_gdf`, `read_raw_brainvision`, `read_raw_eeglab`, `read_raw_cnt`, `read_raw_egi`, `read_raw_nedf`, `read_raw_persyst`, `read_raw_nicolet`, `read_raw_nihon`
- MEG: `read_raw_fif`, `read_raw_ctf`, `read_raw_kit`, `read_raw_bti`, `read_raw_fil`, `read_raw_artemis123`, `read_raw_eximia`
- fNIRS: `read_raw_nirx`, `read_raw_snirf`, `read_raw_hitachi`, `read_raw_boxy`
- iEEG/ECoG/other: `read_raw_nsx`, `read_raw_neuralynx`, `read_raw_fieldtrip`, `read_raw_curry`, `read_raw_ant`, `read_raw_eyelink`

Check reader-specific options for `preload`, units/scaling, stim channels, eog/misc channel inference, montage, and annotation import.

## Creating Data

- Use `mne.create_info` plus `mne.io.RawArray`, `mne.EpochsArray`, or `mne.EvokedArray` for synthetic data or custom imports.
- Use SI units for data arrays: volts for EEG/EOG/ECG, tesla/tesla-meter for MEG.
- Set `ch_types` accurately at creation time or immediately after reading.

## Events And Annotations

- Use `mne.find_events` for stim channels and `mne.events_from_annotations` for annotation-derived events.
- Use `mne.annotations_from_events` to preserve event timing as annotations when needed.
- Use `mne.make_fixed_length_events` and `mne.make_fixed_length_epochs` for sleep/rest/windowed analyses.
- Preserve `event_id` dictionaries and annotation descriptions as stable labels.

## Channel And Montage Operations

- Use `mne.pick_types`, `mne.pick_channels`, `mne.pick_info`, `inst.pick`, and `picks=` parameters.
- Use `mne.rename_channels`, `mne.set_bipolar_reference`, `mne.set_eeg_reference`, `mne.add_reference_channels`, and `mne.channels.combine_channels`.
- Use `mne.channels.make_standard_montage`, `make_dig_montage`, `read_custom_montage`, and `inst.set_montage`.
- Use `mne.channels.find_ch_adjacency` for cluster statistics and topological operations.

## Preprocessing

- Filtering/resampling: `Raw.filter`, `Raw.notch_filter`, `Raw.resample`, `mne.filter.create_filter`, `mne.filter.construct_iir_filter`.
- Bad spans/channels: `raw.annotations`, `raw.info["bads"]`, `interpolate_bads`, `mne.preprocessing.annotate_amplitude`, `annotate_break`, `annotate_muscle_zscore`, `annotate_nan`.
- Ocular/cardiac artifacts: `create_eog_epochs`, `create_ecg_epochs`, `find_eog_events`, `find_ecg_events`, `EOGRegression`, ICA helpers.
- ICA: `mne.preprocessing.ICA`, `read_ica`, `ICA.fit`, `ICA.find_bads_eog`, `ICA.find_bads_ecg`, `ICA.apply`.
- Projections/SSP: `compute_proj_raw`, `compute_proj_epochs`, `compute_proj_evoked`, `read_proj`, `write_proj`.
- MEG-specific: `maxwell_filter`, movement/head-position utilities, empty-room covariance workflows.
- fNIRS: `mne.preprocessing.nirs.optical_density`, `beer_lambert_law`, `scalp_coupling_index`, short-channel functions.
- iEEG/eyetracking: use `mne.preprocessing.ieeg` and `mne.preprocessing.eyetracking` subpackages.

## Epochs And Evoked

- Construct epochs with explicit `events`, `event_id`, `tmin`, `tmax`, `baseline`, `reject`, `flat`, `picks`, `preload`, and `reject_by_annotation`.
- Inspect `epochs.drop_log`, `epochs.selection`, and event counts before averaging.
- Use `mne.concatenate_epochs`, `mne.equalize_epoch_counts`, `mne.combine_evoked`, and `mne.grand_average` for multi-run or multi-subject summaries.

## Spectral And Time-Frequency Analysis

- Prefer object methods such as `raw.compute_psd`, `epochs.compute_psd`, and `evoked.compute_psd` where available.
- Use `mne.time_frequency` for `Spectrum`, `EpochsSpectrum`, `AverageTFR`, `EpochsTFR`, Morlet/multitaper transforms, CSD, PSD arrays, and TFR simulation/IO.
- Keep frequency ranges, decimation, baseline modes, and output units explicit.

## Forward, Source, And Inverse

- Source spaces/head models: `setup_source_space`, `setup_volume_source_space`, `make_bem_model`, `make_bem_solution`, `make_sphere_model`, `make_forward_solution`.
- Coordinate transforms: `read_trans`, `write_trans`, `mne.coreg`, `mne.gui.coregistration`, `head_to_mri`, `head_to_mni`.
- Minimum norm: `mne.minimum_norm.make_inverse_operator`, `apply_inverse`, `apply_inverse_raw`, `apply_inverse_epochs`, `compute_source_psd`, morphing utilities.
- Beamforming: `mne.beamformer.make_lcmv`, `apply_lcmv`, DICS functions, vector orientation handling.
- Sparse/dipole: `mne.fit_dipole`, `mne.inverse_sparse`.
- Verify EEG average reference, rank, noise covariance, loose/fixed orientation, depth weighting, `lambda2`, and method (`MNE`, `dSPM`, `sLORETA`, `eLORETA`) before interpreting source estimates.

## Statistics And Decoding

- `mne.stats`: permutation tests, cluster tests, spatio-temporal adjacency, FDR/Bonferroni helpers, linear regression.
- `mne.decoding`: `CSP`, `SPoC`, `SSD`, `Scaler`, `Vectorizer`, `SlidingEstimator`, `GeneralizingEstimator`, `LinearModel`, `cross_val_multiscore`.
- Use scikit-learn pipelines for leakage control; fit preprocessing only inside cross-validation when preprocessing learns from data.

## Visualization And Reports

- Use object plot methods for quick checks and `mne.viz` for specialized plots.
- In headless automation, set a noninteractive Matplotlib backend and avoid interactive browser/3D backends unless requested.
- Use `mne.Report` to collect figures, raw/epochs/evoked summaries, ICA diagnostics, covariance, and source outputs.

## Export And Persistence

- Prefer MNE FIF writers/readers for lossless round trips.
- Use `mne.export.export_raw`, `export_epochs`, and `export_evokeds` for external formats when needed; verify metadata loss risks.
- Read saved outputs back during tests if file compatibility matters.

## Configuration

- Use `mne.set_log_level`, `mne.use_log_level`, `mne.set_config`, `mne.get_config`, `mne.set_cache_dir`, and `mne.sys_info`.
- In sandboxed automation, set `MNE_DONTWRITE_HOME=true` and `MNE_HOME` to a writable temp directory before importing MNE.
