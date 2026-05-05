---
name: matlab
description: MATLAB execution and coding patterns for Pi. Use when running .m files from the terminal, writing MATLAB scripts/functions, debugging batch jobs, saving figures headlessly, or translating analysis logic into MATLAB.
---

# MATLAB

Use this skill for MATLAB-specific execution and code patterns.

## Default execution

Prefer non-interactive batch mode:

```bash
/Applications/MATLAB_R2023b.app/bin/matlab -batch "run('/path/to/script.m')"
```

or, if `matlab` is on `PATH`:

```bash
matlab -batch "run('/path/to/script.m')"
```

## Rules

- Prefer `-batch` over older `-nodisplay -nosplash -r ...` forms.
- Assume headless execution unless the user explicitly wants GUI interaction.
- For plotting in automation, save figures to disk; do not rely on an interactive window.
- Use longer timeouts for MATLAB startup.

## Headless plotting

At script start when needed:

```matlab
set(0, 'DefaultFigureVisible', 'off');
```

Then save explicitly:

```matlab
exportgraphics(gcf, 'figure.png', 'Resolution', 150)
```

## Coding patterns

- Prefer functions over long monolithic scripts for reusable logic.
- Preallocate arrays for loops.
- Use tables/timetables when column semantics matter.
- Vectorize numeric work when it keeps the code readable.
- Use `fullfile()` for paths.
- Avoid `cd` unless necessary; prefer absolute or constructed paths.

## Common pitfalls

- MATLAB indexing starts at **1**, not 0.
- `size(A)` returns dimensions; be explicit with `size(A, dim)`.
- `length(A)` is often the wrong choice for matrices; prefer `numel` or `size`.
- Strings and chars are different; use string arrays deliberately.
- `==` on floats is fragile; use tolerances.
- Dynamic array growth inside hot loops is slow.

## Useful snippets

```matlab
A = zeros(n, m);              % preallocate
idx = ismember(labels, wanted);
out = mean(X, 2, 'omitnan');
T = readtable(path);
writetable(T, outPath);
S = load(matPath);
save(outPath, 'var1', 'var2', '-v7.3');
```

## Debugging

For batch failures, capture the exact stderr/stdout and check:
- missing toolbox/function on path
- wrong working directory
- file path quoting
- version-specific behavior
- graphics calls in headless mode

## When Pi edits MATLAB

- Preserve MATLAB style already used in the repo.
- Prefer clear matrix dimensions over clever one-liners.
- If changing scientific code, state shape assumptions and units.
- Suggest a minimal `matlab -batch` validation command when possible.
