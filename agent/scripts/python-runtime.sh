#!/usr/bin/env bash
# Shared interpreter selection prevents macOS's older /usr/bin/python3 from skipping validation.
if [ -z "${AGENT_PYTHON:-}" ]; then
  for candidate in "$AGENT_DIR/.venv/bin/python" python3 python3.14 python3.13 python3.12 python3.11; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import tomllib' >/dev/null 2>&1; then
      AGENT_PYTHON="$candidate"
      break
    fi
  done
fi
if [ -z "${AGENT_PYTHON:-}" ] || ! "$AGENT_PYTHON" -c 'import tomllib' >/dev/null 2>&1; then
  printf 'agent: Python 3.11+ is required; set AGENT_PYTHON to its executable.\n' >&2
  exit 4
fi
export AGENT_PYTHON
