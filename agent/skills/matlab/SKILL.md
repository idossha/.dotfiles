---
name: matlab
description: Run MATLAB code from the terminal in batch mode (no GUI) and write MATLAB that survives it — resolving the installed release, passing arguments, exit codes, headless figures, common indexing pitfalls. Use when executing .m files or MATLAB commands, or editing MATLAB code. Not for EEGLAB-specific APIs (eeglab).
user-invocable: false
---

# Running MATLAB Scripts

Resolve the binary instead of assuming a release; MATLAB upgrades rename the app bundle:

```bash
MATLAB="$(command -v matlab || ls -d /Applications/MATLAB_R*.app/bin/matlab 2>/dev/null | tail -1)"
"$MATLAB" -batch "disp(version)"
```

## Default Execution — Always Batch Mode

```bash
"$MATLAB" -batch "<command_or_script>"
```

`-batch` runs without the desktop or splash screen, exits when the code finishes, and returns a nonzero
exit code on an uncaught error. It replaces the older `-nosplash -nodisplay -nodesktop -r "...; exit"`.

## Running a Script File

```bash
# Run a .m file (omit the .m extension)
"$MATLAB" -batch "run('/path/to/script.m')"

# Or if already in the script's directory:
"$MATLAB" -batch "cd('/path/to/dir'); my_script"
```

## Running Inline Commands

```bash
"$MATLAB" -batch "disp('hello'); x = 1+1; disp(x)"
```

## Running with Arguments

MATLAB `-batch` does not support direct argument passing. Use environment variables or write a wrapper:

```bash
# Via environment variable
export MY_PARAM=42
"$MATLAB" -batch "param = str2double(getenv('MY_PARAM')); my_script"
```

## Important Notes

- NEVER launch MATLAB with the GUI. Always use `-batch`.
- `-batch` is preferred over `-r` because it auto-exits and sets exit codes correctly.
- Startup takes 10-30 seconds; give the command a generous timeout and run long jobs in the background.
- Plotting under `-batch` still creates figures off screen; save them with `exportgraphics()` and `close all`.

## Coding Patterns

- Prefer functions over long monolithic scripts for reusable logic.
- Preallocate arrays for loops.
- Use tables or timetables when column semantics matter.
- Vectorize numeric work when it keeps the code readable.
- Use `fullfile()` for paths.
- Avoid `cd` unless necessary; prefer absolute or constructed paths.
- Preserve the MATLAB style already used in the repo.
- If changing scientific code, state shape assumptions and units.

## Common Pitfalls

- MATLAB indexing starts at 1, not 0.
- `size(A)` returns dimensions; be explicit with `size(A, dim)`.
- `length(A)` is often wrong for matrices; prefer `numel` or `size`.
- Strings and chars are different; use string arrays deliberately.
- `==` on floats is fragile; use tolerances.
- Dynamic array growth inside hot loops is slow.

## Useful Snippets

```matlab
A = zeros(n, m);
idx = ismember(labels, wanted);
out = mean(X, 2, 'omitnan');
T = readtable(path);
writetable(T, outPath);
S = load(matPath);
save(outPath, 'var1', 'var2', '-v7.3');
```
