---
name: web-neuroimaging
description: Web research for neuroimaging documentation, SimpleITK, nibabel, napari, BIDS specs, and neuroscience methods. TRIGGER when user asks to look up docs, find API references, or research neuroimaging methods.
user-invocable: false
---

# Web Research for Neuroimaging

## Priority Documentation Sources

| Domain | URL | Use For |
|--------|-----|---------|
| SimpleITK | simpleitk.readthedocs.io | Registration, filters, transforms |
| SimpleITK examples | simpleitk.org/SimpleITK-Notebooks | Jupyter notebooks with full pipelines |
| nibabel | nipy.org/nibabel | NIfTI I/O, affines, orientation |
| napari | napari.org/stable | Viewer API, layers, events |
| BIDS | bids-specification.readthedocs.io | Data format, iEEG extension |
| PySide6/Qt | doc.qt.io/qtforpython-6 | Widget API, signals/slots |
| NumPy | numpy.org/doc/stable | Array operations |
| SciPy | docs.scipy.org/doc/scipy | Signal processing, ndimage |

## Search Strategy

1. **Official docs first** — use WebFetch on the URLs above
2. **GitHub repos** — SimpleITK/SimpleITK, nipy/nibabel, napari/napari
3. **NeuroStars** (neurostars.org) — neuroimaging-specific Q&A forum
4. **PubMed/Scholar** — methodology references, validation studies
5. **Stack Overflow** — general Python/Qt issues

## Common Lookups

### SimpleITK Registration
- Registration method API: simpleitk.readthedocs.io/en/master/link_Registration_docs.html
- Transform types: Euler3D, Affine, BSpline, Displacement
- Metrics: MattesMutualInformation, Correlation, MeanSquares
- Optimizers: GradientDescentLineSearch, LBFGSB, ConjugateGradient

### nibabel
- Affine handling: nipy.org/nibabel/coordinate_systems.html
- Image types: Nifti1Image, Nifti2Image, MGHImage
- Orientation codes: RAS, LAS, LPI, etc.

### BIDS-iEEG Extension
- Electrode files: `*_electrodes.tsv` with x,y,z,size,type columns
- Coordinate systems: `*_coordsystem.json` specifying space (T1w, MNI152NLin2009aSym, etc.)
- Channel files: `*_channels.tsv` with name,type,units,sampling_frequency

### napari
- Layer types: Image, Points, Shapes, Labels, Surface, Tracks, Vectors
- Events: dims.events.current_step, mouse_drag_callbacks, mouse_move_callbacks
- Rendering: mip, attenuated_mip, minip, translucent, iso

## Version-Specific Notes
- SimpleITK v2.x changed API significantly from v1.x — always check version
- napari 0.5→0.6 had breaking changes in viewer embedding
- PySide6 6.5+ required for latest Qt features
- nibabel 5.0 deprecated some older image classes

## When Reporting
- Include direct URLs to relevant doc pages
- Provide minimal code examples
- Note any version-specific behavior
- Flag deprecated APIs
