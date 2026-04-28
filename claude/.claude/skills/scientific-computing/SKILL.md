---
name: scientific-computing
description: Scientific Python patterns for NumPy, SciPy, and matplotlib in medical imaging and neuroscience. Use when writing numerical code, signal processing, or scientific visualizations.
user-invocable: false
---

# Scientific Computing Patterns

## NumPy for Medical Imaging

### Volume Operations
```python
import numpy as np

# CT thresholding
bone_mask = ct_data > 700           # Bone
electrode_mask = ct_data > 2500     # Metal

# HU windowing (display normalization)
def window_level(data, window, level):
    low = level - window / 2
    high = level + window / 2
    return np.clip((data - low) / (high - low), 0, 1)

# Standard windows: brain (80/40), bone (2000/500), electrode (4000/1000)

# Slice extraction
axial = data[:, :, z]
coronal = data[:, y, :]
sagittal = data[x, :, :]
```

### Coordinate Geometry
```python
# Direction vector
direction = entry - tip
length = np.linalg.norm(direction)
unit = direction / length

# Interpolate contacts along shaft
def interpolate_contacts(tip, entry, n_contacts, spacing_mm):
    unit = (entry - tip) / np.linalg.norm(entry - tip)
    return np.array([tip + i * spacing_mm * unit for i in range(n_contacts)])

# Pairwise distances
from scipy.spatial.distance import cdist
dists = cdist(points_a, points_b)   # (N, M) matrix
```

### Critical Anti-Patterns
```python
# WRONG: view, not copy
arr2 = arr1              # Modifying arr2 modifies arr1!
arr2 = arr1.copy()       # CORRECT

# WRONG: float equality
if val == 0.0: ...
if np.isclose(val, 0.0, atol=1e-10): ...   # CORRECT

# WRONG: Python loop over voxels
for i in range(s[0]):
    for j in range(s[1]):
        result[i,j] = func(data[i,j])

# CORRECT: vectorized
result = func(data)      # 100-1000x faster
```

## SciPy for Neuroimaging

### Image Processing (ndimage)
```python
from scipy import ndimage

smoothed = ndimage.gaussian_filter(volume, sigma=2.0)     # sigma = FWHM/2.355
dilated = ndimage.binary_dilation(mask, iterations=2)
labeled, n = ndimage.label(binary_mask)                    # Connected components
centroids = ndimage.center_of_mass(mask, labeled, range(1, n+1))
```

### Signal Processing (iEEG)
```python
from scipy import signal

# Bandpass filter — ALWAYS use filtfilt for zero-phase
def bandpass(data, low, high, fs, order=4):
    b, a = signal.butter(order, [low/(fs/2), high/(fs/2)], btype='band')
    return signal.filtfilt(b, a, data, axis=-1)

# Frequency bands: delta(1-4), theta(4-8), alpha(8-13),
#   beta(13-30), gamma(30-100), high-gamma(70-150) Hz

# PSD — Welch's method
freqs, psd = signal.welch(eeg, fs=sampling_rate, nperseg=1024)

# Hilbert (instantaneous amplitude/phase)
analytic = signal.hilbert(filtered)
amplitude = np.abs(analytic)
phase = np.angle(analytic)
```

### Interpolation
```python
from scipy.interpolate import RegularGridInterpolator

interp = RegularGridInterpolator(
    (x, y, z), data,
    method='linear', bounds_error=False, fill_value=0,
)
resampled = interp(new_coords)   # (N, 3) → (N,)
```

## Matplotlib for Medical Imaging

### Multi-Slice QC Overlay
```python
import matplotlib
matplotlib.use('Agg')              # NON-INTERACTIVE — before pyplot import
import matplotlib.pyplot as plt

fig, axes = plt.subplots(1, 3, figsize=(15, 5))
for ax, (name, bg, fg) in zip(axes, planes):
    ax.imshow(bg.T, cmap='gray', origin='lower')
    ax.imshow(fg.T, cmap='hot', alpha=0.4, origin='lower')
    ax.set_title(name)
    ax.axis('off')
plt.tight_layout()
plt.savefig(path, dpi=150, bbox_inches='tight')
plt.close(fig)                     # ALWAYS close — memory leak otherwise
```

### Electrode Visualization
```python
fig, ax = plt.subplots(figsize=(8, 8))
ax.imshow(t1w_slice.T, cmap='gray', origin='lower')
for e in electrodes:
    coords = np.array([c.position_ct[:2] for c in e.contacts])
    ax.scatter(coords[:,0], coords[:,1], c=[e.color], s=20, label=e.label)
ax.legend(fontsize=8)
plt.close(fig)
```

## Performance Rules

1. **Vectorize everything** — numpy array ops, never Python loops over elements
2. **float32 > float64** for volumes — half the memory, sufficient precision
3. **Use `out=` parameter** to avoid temporaries: `np.add(a, b, out=result)`
4. **Memory-map large files**: `np.memmap()` or nibabel proxy images
5. **Profile first**: `%timeit` or `cProfile` — never guess bottlenecks
6. **Agg backend** for CLI/batch matplotlib — `matplotlib.use('Agg')` before import
