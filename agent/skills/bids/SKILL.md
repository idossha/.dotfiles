---
name: bids
description: BIDS (Brain Imaging Data Structure) conventions for neuroimaging datasets — directory layout, entity order in filenames, JSON sidecars and inheritance, TSV files, derivatives and validation. Use when creating, reading, validating, or navigating BIDS-compliant trees, filenames, sidecars, or derivatives. Not for volume I/O and coordinate transforms (neuroimaging) or MNE processing (mne-python).
user-invocable: false
---

# BIDS (Brain Imaging Data Structure) Skill

## Core Directory Layout

```
dataset/
├── dataset_description.json          # REQUIRED
├── README[.md|.rst|.txt]            # REQUIRED
├── participants.tsv                  # RECOMMENDED
├── participants.json                 # RECOMMENDED (column descriptions)
├── CHANGES                           # OPTIONAL
├── LICENSE                           # OPTIONAL
├── CITATION.cff                      # OPTIONAL
├── .bidsignore                       # OPTIONAL (like .gitignore for validator)
├── code/                             # Scripts and analysis code
├── stimuli/                          # Stimulus files
├── sourcedata/                       # Pre-conversion source files (DICOM, etc.)
├── phenotype/                        # Participant-level measures (shared, not per-subject)
├── derivatives/                      # Processed outputs
│   └── <pipeline-name>/
│       ├── dataset_description.json  # REQUIRED per derivative
│       └── sub-<label>/...
└── sub-<label>/
    └── [ses-<label>/]
        ├── anat/       # Anatomical MRI
        ├── func/       # Functional MRI
        ├── dwi/        # Diffusion
        ├── fmap/       # Field maps
        ├── perf/       # Perfusion / ASL
        ├── eeg/        # EEG
        ├── meg/        # MEG
        ├── ieeg/       # Intracranial EEG
        ├── beh/        # Behavioral
        ├── pet/        # PET
        └── ...         # Other BIDS datatypes
```

- Empty datatype directories MUST NOT exist.
- If ANY subject has multiple sessions, ALL subjects MUST have session directories.
- Dotfiles (`.`-prefixed) are reserved for system use and excluded from validation.
- `phenotype/` lives at dataset root (not per-subject).

## File Naming Convention

```
sub-<label>[_ses-<label>][_task-<label>][_acq-<label>][_run-<index>][_desc-<label>]_<suffix>.<extension>
```

### Rules
- Entities are key-value pairs separated by hyphens, joined by underscores.
- Entity ORDER is fixed by the spec — always follow the prescribed sequence.
- Each entity appears at most ONCE per filename.
- Labels: alphanumeric (may include `+`). No spaces.
- Indices (e.g., `run-`): non-negative integers, optionally zero-padded (`run-01`).
- Case collision intolerance: `sub-s1` and `sub-S1` CANNOT coexist.
- Filename must not exceed 255 characters.
- Extensions MUST be lowercase.

### Entity Order (most common)

Order is fixed by the spec's entity table. The common subset, in order:

`sub` → `ses` → `task` → `acq` → `ce` → `rec` → `dir` → `run` → `echo` → `part` → `proc` → `space` →
`recording` → `res` → `den` → `label` → `desc`

`space-` precedes `desc-` (`sub-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz`). For any
entity not listed, read the Entities Appendix of the spec version the dataset declares in
`BIDSVersion` rather than guessing.

### Common Suffixes by Datatype

| Datatype | Suffixes |
|----------|---------|
| `anat/` | `T1w`, `T2w`, `FLAIR`, `T1map`, `T2map`, `T2starmap`, `PDw` |
| `func/` | `bold`, `sbref` |
| `dwi/` | `dwi`, `sbref` |
| `fmap/` | `epi`, `magnitude`, `phase`, `phasediff` |
| `eeg/` | `eeg`, `events`, `channels`, `electrodes`, `coordsystem`, `photo` |
| `perf/` | `asl`, `m0scan` |

## Metadata (JSON Sidecars)

Every data file can have a companion `.json` sidecar with the same base name:
```
sub-01_ses-01_task-rest_bold.nii.gz
sub-01_ses-01_task-rest_bold.json   ← metadata sidecar
```

### JSON conventions
- UTF-8 encoding
- Keys in CamelCase with uppercase first letter
- Derive from DICOM tags where possible

### Inheritance Principle

Sidecars can live at ANY directory level. Lower levels override higher levels (key by key for JSON, full replacement for TSV):

```
task-rest_bold.json                          ← dataset-wide defaults
sub-01/func/sub-01_task-rest_bold.json       ← subject-specific overrides
```

A sidecar applies to a data file if:
1. It is at the same level or higher in the hierarchy.
2. It has the same suffix.
3. Its filename contains NO entities absent from the data file.

## TSV Files

- Tab-delimited, UTF-8
- MUST start with a header row
- Missing values: `n/a`
- Decimal separator: `.` (dot)
- Column names: `snake_case`, lowercase first letter
- Strings containing tabs: escape with double quotes

### participants.tsv

```tsv
participant_id	age	sex	condition
sub-01	25	M	ACTIVE
sub-02	30	F	SHAM
```

- `participant_id` column is REQUIRED (values like `sub-01`)
- Companion `participants.json` describes columns with `LongName`, `Description`, `Levels`, `Units`

### events.tsv (for func/eeg/meg)

```tsv
onset	duration	trial_type
0.0	0.5	go
2.3	0.5	stop
```

- `onset` (seconds from run start) and `duration` are REQUIRED columns

### channels.tsv (EEG/MEG/iEEG)

Required columns: `name`, `type`, `units`  
Optional: `sampling_frequency`, `reference`, `low_cutoff`, `high_cutoff`, `notch`, `status`, `status_description`

Valid EEG channel types: `EEG`, `EOG`, `ECG`, `EMG`, `VEOG`, `HEOG`, `MISC`, `REF`, `TRIG`, `STIM`

### electrodes.tsv (EEG)

Required columns: `name`, `x`, `y`, `z`  
Optional: `type`, `material`, `impedance`

Requires companion `*_coordsystem.json` with `EEGCoordinateSystem`, `EEGCoordinateUnits`.

## dataset_description.json

### Raw Dataset (REQUIRED fields)

```json
{
  "Name": "My Study",
  "BIDSVersion": "1.9.0"
}
```

### Recommended Fields

```json
{
  "Name": "My Study",
  "BIDSVersion": "1.9.0",
  "DatasetType": "raw",
  "License": "CC0",
  "Authors": ["Last, First", "Last2, First2"],
  "Funding": ["NIH R01-XX-XXXXX"],
  "DatasetDOI": "doi:10.xxxx/xxxxx"
}
```

### Derivative Dataset

```json
{
  "Name": "My Pipeline Output",
  "BIDSVersion": "1.9.0",
  "DatasetType": "derivative",
  "GeneratedBy": [
    {
      "Name": "my-pipeline",
      "Version": "1.0.0",
      "CodeURL": "https://github.com/org/pipeline"
    }
  ],
  "SourceDatasets": [
    {
      "URL": "file:///path/to/raw/dataset"
    }
  ]
}
```

## EEG-Specific Details

### Supported Formats

| Format | Extensions | Notes |
|--------|-----------|-------|
| BrainVision | `.vhdr`, `.vmrk`, `.eeg` | Recommended; triplet required |
| European Data Format | `.edf` | Single file; EDF+ OK |
| EEGLAB | `.set` (+ `.fdt`) | MATLAB format |
| Biosemi | `.bdf` | Single file; BDF+ OK |

### Required EEG Sidecar Fields (`*_eeg.json`)

| Field | Type | Example |
|-------|------|---------|
| `EEGReference` | string | `"FCz"` or `"average"` |
| `SamplingFrequency` | number | `512` |
| `PowerLineFrequency` | number or `"n/a"` | `60` |
| `SoftwareFilters` | object or `"n/a"` | `{"Anti-aliasing": {"half-amplitude cutoff (Hz)": 500}}` |

### Recommended EEG Fields

`TaskName`, `EEGChannelCount`, `EOGChannelCount`, `ECGChannelCount`, `RecordingType` (`"continuous"`, `"epoched"`, `"discontinuous"`), `EpochLength`, `RecordingDuration`, `CapManufacturer`, `EEGGround`, `HardwareFilters`, `Manufacturer`

### Electrode vs Channel

- **Electrode**: physical contact on scalp (appears in `electrodes.tsv`)
- **Channel**: ADC output (appears in `channels.tsv`)
- Reference/ground electrodes may NOT have corresponding channels

## MRI-Specific Details

### Required Sidecar Fields

- **All MRI**: `RepetitionTime` (or `RepetitionTimeExcitation`), `EchoTime`
- **BOLD**: `TaskName`, `RepetitionTime`, `EchoTime`; RECOMMENDED: `SliceTiming`, `PhaseEncodingDirection`
- **DWI**: `EchoTime`, plus `.bval`/`.bvec` files
- **T1w/T2w**: `EchoTime`, `RepetitionTime`, `FlipAngle`
- **Fieldmaps**: `B0FieldIdentifier`/`B0FieldSource` for linking to target scans

### File extensions
- `.nii.gz` (recommended) or `.nii` for imaging data
- Always paired with `.json` sidecar

## Derivatives Convention

```
derivatives/<pipeline-name>/
├── dataset_description.json     # DatasetType: "derivative"
├── descriptions.tsv             # OPTIONAL — documents desc- labels
└── sub-01/
    └── ses-01/
        └── func/
            ├── sub-01_ses-01_task-rest_space-MNI152_desc-preproc_bold.nii.gz
            └── sub-01_ses-01_task-rest_space-MNI152_desc-preproc_bold.json
```

### Key Rules
- `desc-<label>` distinguishes processing variants of the same source.
- `space-<label>` indicates spatial reference (e.g., `MNI152NLin2009cAsym`, `T1w`, `orig`).
- Preprocessed data that keeps the same dimensionality retains original suffix (`bold`, `T1w`, etc.).
- JSON sidecar SHOULD include `Sources` field with BIDS URIs to input files.
- All REQUIRED metadata from source files MUST propagate to derivative sidecars unless invalidated by processing.

### BIDS URIs

```
bids::<relative-path>                    # current dataset
bids:<dataset-name>:<relative-path>      # named dataset (via DatasetLinks)
```

## Requirement Levels (RFC 2119)

- **REQUIRED**: Ambiguity too high without it
- **RECOMMENDED**: Dramatically improves interpretation
- **OPTIONAL**: Useful but not essential
- When a field is unavailable, OMIT it entirely rather than using `n/a` or empty string

## DateTime Format

`YYYY-MM-DDThh:mm:ss[.000000][Z|+hh:mm]`  
Example: `2009-06-15T13:45:30+01:00`

Privacy: shift dates consistently per subject; set shifted year to 1925 or earlier.

## Units Convention

Follow SI; use CMIXF-12 notation for prefixes:
- `uV` (microvolts), `mV` (millivolts), `Hz`, `mm`, `ms`, `oC` (degrees Celsius)
- Time in seconds, frequency in Hertz

## Paths

- Always use forward slash `/` (even on Windows)
- Use relative paths — absolute paths break portability
- In JSON metadata fields, use BIDS URIs where applicable

## Python: Building BIDS Paths

Do not hand-roll entity ordering. Use a library that encodes the spec:

```python
from mne_bids import BIDSPath          # EEG/MEG/iEEG; also handles sidecars when writing

path = BIDSPath(root=root, subject="01", session="pre", task="rest",
                datatype="eeg", suffix="eeg", extension=".edf")
path.fpath                              # ordered, validated path

from bids import BIDSLayout             # pybids: query an existing dataset
layout = BIDSLayout(root, derivatives=True)
layout.get(subject="01", suffix="T1w", extension=".nii.gz", return_type="file")
```

If a project already has a path helper, use it and check its entity order against the appendix.

## Validation

Validate with the schema-based validator (v2):

```bash
deno run -A jsr:@bids/validator /path/to/dataset          # canonical
docker run --rm -v /path/to/dataset:/data:ro bids/validator /data
```

The `bids-validator` Python package checks filenames only (`BIDSValidator().is_bids(relpath)`); it is
not a dataset validation. Report the validator version and any warnings you chose to leave.

Common validation pitfalls:
- Empty datatype directories
- Missing `dataset_description.json`
- Entity order wrong in filenames
- Case collisions in labels
- Missing required sidecar fields
