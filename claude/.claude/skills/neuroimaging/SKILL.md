---
name: neuroimaging
description: Medical neuroimaging patterns for NIfTI, DICOM, SimpleITK, and nibabel. Use when working with brain imaging data, registration, coordinate transforms, or volume I/O.
user-invocable: false
---

# Neuroimaging Development Patterns

## NIfTI I/O with nibabel

### Loading
```python
import nibabel as nib
import numpy as np

img = nib.load(path)               # Returns proxy — data NOT in memory
data = img.get_fdata()              # Load as float64
data = img.get_fdata(dtype=np.float32)  # Control memory usage
affine = img.affine                 # 4x4 voxel→world (RAS+)
voxel_sizes = img.header.get_zooms()    # e.g., (1.0, 1.0, 1.0) mm
```

### Saving
```python
new_img = nib.Nifti1Image(data_array, affine)
nib.save(new_img, output_path)

# Preserve header from source
new_img = nib.Nifti1Image(data_array, affine, header=img.header)
```

### Coordinate Transforms
```python
from nibabel.affines import apply_affine

# Voxel (i,j,k) → World (x,y,z) mm
world = apply_affine(affine, voxel_coords)

# World → Voxel (inverse)
voxel = apply_affine(np.linalg.inv(affine), world_coords)

# Batch: (N,3) arrays work directly
world_batch = apply_affine(affine, voxel_batch)
```

### Orientation
```python
axcodes = nib.aff2axcodes(affine)      # ('R','A','S') for standard
canonical = nib.as_closest_canonical(img)  # Reorient to RAS
ornt = nib.io_orientation(affine)       # Orientation transform matrix
```

## SimpleITK Registration

### Image I/O
```python
import SimpleITK as sitk

image = sitk.ReadImage(str(path))
sitk.WriteImage(image, str(output_path))

# DICOM series
reader = sitk.ImageSeriesReader()
files = reader.GetGDCMSeriesFileNames(str(dicom_dir))
reader.SetFileNames(files)
image = reader.Execute()

# numpy ↔ SimpleITK — AXIS ORDER IS REVERSED
array = sitk.GetArrayFromImage(image)    # (z, y, x) — NOT (x, y, z)
image = sitk.GetImageFromArray(array)
image.CopyInformation(reference)         # ALWAYS copy spacing/origin/direction
```

### Rigid Registration (CT→MRI)
```python
initial = sitk.CenteredTransformInitializer(
    fixed, moving, sitk.Euler3DTransform(),
    sitk.CenteredTransformInitializerFilter.GEOMETRY,
)

reg = sitk.ImageRegistrationMethod()
reg.SetMetricAsMattesMutualInformation(numberOfHistogramBins=50)
reg.SetMetricSamplingStrategy(reg.RANDOM)
reg.SetMetricSamplingPercentage(0.25)
reg.SetInterpolator(sitk.sitkLinear)
reg.SetOptimizerAsGradientDescentLineSearch(
    learningRate=1.0, numberOfIterations=200,
    convergenceMinimumValue=1e-6, convergenceWindowSize=10,
)
reg.SetShrinkFactorsPerLevel([4, 2, 1])
reg.SetSmoothingSigmasPerLevel([2.0, 1.0, 0.0])
reg.SmoothingSigmasAreSpecifiedInPhysicalUnitsOn()
reg.SetInitialTransform(initial, inPlace=False)
transform = reg.Execute(fixed, moving)
```

### Resampling
```python
resampled = sitk.Resample(
    moving, fixed, transform,
    sitk.sitkLinear, 0.0, moving.GetPixelID(),
)
```

### Transform I/O and Composition
```python
sitk.WriteTransform(transform, str(path))       # .tfm or .h5
transform = sitk.ReadTransform(str(path))

composite = sitk.CompositeTransform(3)
composite.AddTransform(ct_to_t1w)
composite.AddTransform(t1w_to_mni)
composite.FlattenTransform()                      # REQUIRED before save
```

## Critical Conventions

### Axis Order — THE #1 BUG SOURCE
| Library | Array Axes | World Convention |
|---------|-----------|-----------------|
| nibabel | (i, j, k) per NIfTI header | RAS+ |
| SimpleITK | (z, y, x) — REVERSED | LPS+ |

When crossing libraries: transpose arrays AND negate X,Y coordinates.

### Converting SimpleITK → nibabel affine
```python
direction = np.array(image.GetDirection()).reshape(3, 3)
spacing = np.diag(image.GetSpacing())
origin = np.array(image.GetOrigin())
affine = np.eye(4)
affine[:3, :3] = direction @ spacing
affine[:3, 3] = origin
```

### Memory Management
- NIfTI volumes: 256^3 float64 = ~134MB — use float32 when possible
- nibabel loads lazily — `.get_fdata()` materializes
- SimpleITK also lazy — `.Execute()` triggers computation
- Always close matplotlib figures: `plt.close(fig)`

## DICOM Series Selection
```python
series_ids = sitk.ImageSeriesReader.GetGDCMSeriesIDs(str(dicom_dir))
for sid in series_ids:
    files = sitk.ImageSeriesReader.GetGDCMSeriesFileNames(str(dicom_dir), sid)
    reader = sitk.ImageFileReader()
    reader.SetFileName(files[0])
    reader.ReadImageInformation()
    modality = reader.GetMetaData("0008|0060")   # CT, MR, etc.
    desc = reader.GetMetaData("0008|103e")        # Series description
```

For post-implant CT: prefer thin-slice (<=1mm) axial, avoid scout/localizer (few slices).

## BIDS-iEEG Electrode Format
```
name	x	y	z	size	type
LA1	-35.2	-12.1	8.4	1.5	SEEG
```
Tab-separated. Coordinates in T1w or MNI space (specified in sidecar JSON). Size = contact diameter mm.
