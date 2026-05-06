---
name: code-quality
description: Production code quality standards and review checklist. Use when writing or reviewing code.
user-invocable: false
---

# Code Quality Standards

## Security (OWASP Awareness)

- **Injection**: Never string-format SQL queries. Use parameterized queries:
  ```python
  # BAD
  cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
  # GOOD
  cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
  ```
- **XSS**: Sanitize all user input before rendering in HTML. Use templating engines with auto-escaping enabled.
- **Secrets**: Never hardcode secrets, API keys, or passwords. Use environment variables or secret managers. Never commit `.env` files.
- **Subprocess**: Never use `shell=True`. Pass args as a list:
  ```python
  # BAD
  subprocess.run(f"convert {user_file}", shell=True)
  # GOOD
  subprocess.run(["convert", user_file])
  ```
- **Deserialization**: Never `pickle.load()` or `yaml.load()` untrusted data. Use `yaml.safe_load()`.

## Error Handling

- **Validate at system boundaries**: user input, external API responses, file I/O, environment variables.
- **Trust internals**: don't re-validate data that your own code already validated and passed in.
- **Fail fast**: raise exceptions early rather than propagating invalid state.
- **Catch specific exceptions**: never bare `except:` or `except Exception:` without re-raising.

## Complexity Management

- **No over-engineering**: solve the current requirement, not hypothetical future ones.
- **DRY threshold**: tolerate 2 repetitions. Abstract on the 3rd. Three similar lines are better than a premature abstraction that couples unrelated concerns.
- **YAGNI**: don't add features, refactoring, or comments beyond what was asked.
- **Avoid backwards-compatibility shims**: if code paths are unused, delete them. Dead code is a maintenance burden.

## Naming

- **Functions**: verbs (`parse_config`, `validate_input`, `send_notification`)
- **Classes**: nouns (`ConfigParser`, `UserValidator`, `ReportGenerator`)
- **Booleans**: `is_`, `has_`, `can_`, `should_` prefixes (`is_valid`, `has_permission`)
- **Constants**: `UPPER_SNAKE_CASE`
- **Grep-friendly**: avoid generic names like `data`, `info`, `result`, `item` when a specific name exists
- **Consistent**: if the codebase says `user_id`, don't introduce `userId` or `uid`

## Import Hygiene

- No wildcard imports (`from module import *`)
- Explicit re-exports via `__all__` in `__init__.py`
- Group imports: stdlib, third-party, local (separated by blank lines)
- Absolute imports preferred over relative imports

## Documentation

- **Type hints**: required on all public API function signatures
- **Docstrings**: only on non-obvious logic. If the function name and signature tell the whole story, skip the docstring.
- **Comments**: explain *why*, never *what*. If you need a comment to explain *what*, rename the variable or function instead.

## Testing

- **Test behavior, not implementation**: assert on outputs and side effects, not internal method calls.
- **Mock at boundaries**: mock external services, filesystems, network calls. Don't mock internal helper functions.
- **One assertion per logical concept**: a test can have multiple `assert` statements if they verify one behavior.
- **Test names describe the scenario**: `test_parse_config_raises_on_missing_field` not `test_parse_config_3`.
- **Don't test framework code**: don't test that Python's `dict` works or that `dataclass` generates `__init__`.

## Code Review Checklist

- [ ] No secrets, keys, or credentials in code
- [ ] User input validated and sanitized at entry points
- [ ] Error cases handled, not silenced
- [ ] No unnecessary complexity added
- [ ] Names are descriptive and consistent with codebase
- [ ] Public APIs have type hints
- [ ] Tests cover the changed behavior
- [ ] No unrelated changes bundled in
