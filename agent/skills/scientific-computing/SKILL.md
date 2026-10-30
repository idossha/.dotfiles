---
name: scientific-computing
description: Numerical correctness for NumPy and SciPy in neuroscience and imaging code — dtypes, NaNs, float comparison, filtering, spectra, randomness, units and memory. Use when writing or reviewing numerical, signal-processing or array code. Not for figure layout and publication plots (idofig), volume I/O and coordinate spaces (neuroimaging), or MNE objects (mne-python).
user-invocable: false
---

# Scientific Computing

Numbers that look plausible are the failure mode. Every change states shape, dtype, units and the
assumption that would invalidate the result.

## Arrays

- Write the expected shape next to non-obvious arrays (`# (n_channels, n_samples)`) and assert it at
  function boundaries that receive outside data.
- Know whether an operation returns a view or a copy. Slices are views; fancy indexing copies. Call
  `.copy()` before mutating data a caller still owns.
- Watch integer dtypes: `uint8`/`int16` image data overflows silently in arithmetic. Cast to `float32`
  (large volumes) or `float64` (statistics, accumulation) first.
- Vectorize over voxels and samples; loop over subjects or files. Profile before micro-optimizing.
- Large arrays: `np.load(..., mmap_mode="r")`, `out=` for in-place ufuncs, avoid hidden temporaries.

## Comparisons and missing data

- Never `==` on floats: `np.isclose`/`np.allclose` with a stated `atol`/`rtol`.
- Decide NaN policy explicitly: `np.nanmean` versus propagating NaN versus masking. A silent NaN in one
  channel can poison a grand average.
- Check for `inf` after divisions and logs (`np.log10(power)` on zero power).

## Signals

- Filters: `scipy.signal.butter(..., output="sos")` with `sosfiltfilt` for zero-phase offline work;
  `sosfilt` when causality matters. Normalize by Nyquist or pass `fs=`.
- State band edges, order, sampling rate and padding; filtfilt edge effects contaminate the first and
  last few cycles of the lowest frequency.
- Spectra: `signal.welch` with explicit `nperseg`, `noverlap`, `window`, and the resulting frequency
  resolution. Report whether values are power or amplitude and in which units (V²/Hz, dB).
- Phase and envelope via `signal.hilbert` require a narrowband signal first.

## Reproducibility

- Randomness through `rng = np.random.default_rng(seed)` passed down, never global `np.random.seed`.
- Record library versions and parameters next to outputs that feed a paper.
- Batch plots use the `Agg` backend and `plt.close(fig)`; publication figures belong to idofig.

## Verification

Test numerics on synthetic signals with a known answer: a sine of known frequency and amplitude for a
filter or spectrum, a volume with a known centroid for a geometry routine. The expected value comes from
the math, not from running the code once.
