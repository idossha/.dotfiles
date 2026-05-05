---
name: neuroimaging
description: Neuroimaging development patterns for NIfTI, DICOM, SimpleITK, nibabel, BIDS, and coordinate transforms. Use when working with brain imaging volumes, registration, affines, orientation, resampling, or multimodal anatomical pipelines.
---

# Neuroimaging

Use this skill for medical/neuroscience image processing tasks.

## Priority libraries and specs

- `nibabel` — NIfTI I/O, affines, orientation
- `SimpleITK` — registration, transforms, resampling, DICOM series
- BIDS / BIDS-iEEG — dataset/file naming and metadata conventions
- `numpy`, `scipy.ndimage`, `matplotlib` — numerical ops and QC figures

## The biggest footgun

### Axis/order conventions differ

| Library | Array convention | World convention |
|---|---|---|
| nibabel | `(i, j, k)` | RAS+ |
| SimpleITK | arrays from `GetArrayFromImage()` are `(z, y, x)` | LPS+ |

When crossing libraries, be explicit about axis order and world-space convention.

## nibabel basics

```python
img = nib.load(path)
data = img.get_fdata(dtype=np.float32)
affine = img.affine
axcodes = nib.aff2axcodes(affine)
```

- `nib.load()` is lazy; `get_fdata()` materializes data.
- Use `float32` when possible for memory.
- Use `apply_affine()` for voxel/world transforms.
- Use `as_closest_canonical()` only when reorientation is intended and safe.

## SimpleITK basics

```python
image = sitk.ReadImage(str(path))
array = sitk.GetArrayFromImage(image)
resampled = sitk.Resample(moving, fixed, transform, sitk.sitkLinear, 0.0, moving.GetPixelID())
```

- After `GetImageFromArray()`, call `CopyInformation(reference)` when appropriate.
- For labels/masks, use nearest-neighbor interpolation, not linear.
- For intensity images, linear is a common default; sometimes BSpline is better.

## Registration rules

- CT↔MRI often needs mutual information.
- Use multi-resolution registration (`shrink`/`smoothing` levels).
- Validate registration visually with overlays/QC snapshots.
- Keep track of transform direction: moving→fixed or fixed→moving.

## DICOM handling

- DICOM dirs may contain multiple series; identify the correct one first.
- Prefer thin-slice axial CT for electrode localization.
- Read metadata before assuming modality/series meaning.

## BIDS reminders

- Entity order matters in filenames.
- Sidecar metadata follows inheritance rules.
- `*_electrodes.tsv`, `*_coordsystem.json`, and `*_channels.tsv` must agree.
- Do not create empty datatype directories.

## Don't

- Don’t assume all arrays are in the same orientation.
- Don’t resample masks with linear interpolation.
- Don’t drop affine/header information when writing derived NIfTIs.
- Don’t mix voxel coordinates and world coordinates silently.
- Don’t trust registration by metric value alone; inspect the result.

## When reporting or editing

Always state:
- image space/orientation
- voxel size / spacing
- transform direction
- interpolation type
- whether coordinates are voxel, scanner, subject, T1w, or MNI

For web lookups, prefer official docs first: SimpleITK, nibabel, BIDS spec, NeuroStars, then broader web search.
