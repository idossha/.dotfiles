---
name: matlab
description: Run MATLAB scripts from the terminal in batch mode (no GUI, no splash screen). Use when the user wants to execute .m files or MATLAB commands.
user-invocable: false
---

# Running MATLAB Scripts

MATLAB is installed at `/Applications/MATLAB_R2023b.app/bin/matlab`.

## Default Execution — Always Batch Mode

When running MATLAB scripts or commands, ALWAYS use these flags:

```bash
/Applications/MATLAB_R2023b.app/bin/matlab -batch "<command_or_script>"
```

The `-batch` flag:
- Runs without the GUI or splash screen
- Starts MATLAB non-interactively
- Automatically exits when the script finishes
- Returns a nonzero exit code on error
- Suppresses the MATLAB desktop entirely
- Replaces the older `-nosplash -nodisplay -nodesktop -r "...; exit"` pattern

## Running a Script File

```bash
# Run a .m file (omit the .m extension)
/Applications/MATLAB_R2023b.app/bin/matlab -batch "run('/path/to/script.m')"

# Or if already in the script's directory:
/Applications/MATLAB_R2023b.app/bin/matlab -batch "cd('/path/to/dir'); my_script"
```

## Running Inline Commands

```bash
/Applications/MATLAB_R2023b.app/bin/matlab -batch "disp('hello'); x = 1+1; disp(x)"
```

## Running with Arguments

MATLAB `-batch` does not support direct argument passing. Use environment variables or write a wrapper:

```bash
# Via environment variable
export MY_PARAM=42
/Applications/MATLAB_R2023b.app/bin/matlab -batch "param = str2double(getenv('MY_PARAM')); my_script"
```

## Adding to PATH (alternative)

If the user has `/Applications/MATLAB_R2023b.app/bin` on their PATH, use `matlab -batch` directly.

## Important Notes

- NEVER launch MATLAB with the GUI. Always use `-batch`.
- `-batch` is preferred over `-r` because it auto-exits and sets exit codes correctly.
- For long-running scripts, consider using Bash with `timeout` or `run_in_background`.
- MATLAB startup can take 10-30 seconds; set appropriate timeouts.
- If a script uses `figure()` or plotting, add `set(0, 'DefaultFigureVisible', 'off')` at the top or use `-batch` which already suppresses display, then save figures with `saveas()` or `exportgraphics()`.

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
