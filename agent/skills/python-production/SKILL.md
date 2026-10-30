---
name: python-production
description: Python production idioms and the bugs they prevent — typing, dataclasses, pathlib, logging, subprocess, exceptions, packaging and tooling for Python 3.11+. Use when writing, reviewing or refactoring Python. Not for NumPy/SciPy numerics (scientific-computing), test design (testing-backend), or security review (security-review).
user-invocable: false
---

# Python Production

Follow the project's own `pyproject.toml`, linter and type-checker settings first. These defaults apply
where the project is silent.

## Project and tooling

- One `pyproject.toml`. Use the project's runner (`uv run`, `hatch`, a venv); do not install into the
  system interpreter.
- `ruff check` and `ruff format` when configured; run the type checker the project uses (`mypy`,
  `pyright`) on changed modules.
- Respect `requires-python`. On 3.10+ write `X | None` and `list[int]`; `Optional`/`List` only where an
  older floor demands them.

## Data and types

- Structured values are `@dataclass` (`frozen=True` when immutable, `slots=True` when many instances),
  not dicts passed around by key.
- Fixed choices are `enum.Enum` (or `StrEnum`), not string constants.
- Annotate public signatures; let the checker infer locals.
- Never a mutable default argument: `def f(items: list[str] | None = None)` then
  `items = [] if items is None else items`.

## Files and processes

- `pathlib.Path` everywhere; `/` to join, `mkdir(parents=True, exist_ok=True)` to create, explicit
  `encoding="utf-8"` on text I/O.
- Resources live in `with` blocks. A lock is created once and shared — `with self._lock:`, never
  `with threading.Lock():`, which locks nothing.
- `subprocess.run([...], check=True, capture_output=True, text=True)` with an argument list. No
  `shell=True` with interpolated input. Set `timeout=` for anything that can hang.
- Write files atomically when a crash mid-write would corrupt state: write a temp file in the same
  directory, then `os.replace`.

## Errors and logging

- One project base exception; specific subclasses for conditions callers handle. Raise with context
  (`raise ConfigError(...) from exc`).
- Catch the narrowest exception you can act on. `except Exception: pass` is a bug.
- `logger = logging.getLogger(__name__)` per module. Configure handlers only at entry points.
- Log with lazy `%s` arguments (`logger.info("loaded %s", path)`); use f-strings everywhere else.
- Never log secrets, tokens, or full config payloads.

## Modules

- Imports grouped stdlib / third-party / local; no wildcard imports; absolute imports.
- `__init__.py` holds re-exports and `__all__`, not logic.
- Executables put work in `main()` under `if __name__ == "__main__":` so imports have no side effects.
- A class with one method and no state is a function. Prefer composition to inheritance for reuse.
- Defer heavy imports only when measured startup cost justifies it.
