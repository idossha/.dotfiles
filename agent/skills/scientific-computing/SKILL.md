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

bone_mask = ct_data > 700
electrode_mask = ct_data > 2500

def window_level(data, window, level):
    low = level - window / 2
    high = level + window / 2
    return np.clip((data - low) / (high - low), 0, 1)

axial = data[:, :, z]
coronal = data[:, y, :]
sagittal = data[x, :, :]
```

### Coordinate Geometry

```python
direction = entry - tip
length = np.linalg.norm(direction)
unit = direction / length

def interpolate_contacts(tip, entry, n_contacts, spacing_mm):
    unit = (entry - tip) / np.linalg.norm(entry - tip)
    return np.array([tip + i * spacing_mm * unit for i in range(n_contacts)])
```

### Anti-Patterns

```python
arr2 = arr1.copy()

if np.isclose(val, 0.0, atol=1e-10):
    ...

result = func(data)
```

- Use copies deliberately.
- Avoid exact float equality.
- Avoid Python loops over voxels or samples when vectorization is clear.

## SciPy for Neuroimaging

```python
from scipy import ndimage, signal

smoothed = ndimage.gaussian_filter(volume, sigma=2.0)
dilated = ndimage.binary_dilation(mask, iterations=2)
labeled, n = ndimage.label(binary_mask)

def bandpass(data, low, high, fs, order=4):
    b, a = signal.butter(order, [low / (fs / 2), high / (fs / 2)], btype="band")
    return signal.filtfilt(b, a, data, axis=-1)
```

- Use `filtfilt` for zero-phase filtering when appropriate.
- State frequency bands and sampling rates.
- Use Welch PSD and Hilbert transforms deliberately; report window sizes and assumptions.

## Matplotlib for Batch QC

```python
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

fig, axes = plt.subplots(1, 3, figsize=(15, 5))
for ax, (name, bg, fg) in zip(axes, planes):
    ax.imshow(bg.T, cmap="gray", origin="lower")
    ax.imshow(fg.T, cmap="hot", alpha=0.4, origin="lower")
    ax.set_title(name)
    ax.axis("off")
plt.tight_layout()
plt.savefig(path, dpi=150, bbox_inches="tight")
plt.close(fig)
```

Always close figures in batch jobs.

## Performance Rules

1. Vectorize array operations.
2. Prefer `float32` for large volumes when precision allows.
3. Use `out=` to avoid temporaries when useful.
4. Memory-map large files when possible.
5. Profile before optimizing.
6. Set the Agg backend before importing pyplot in CLI workflows.
