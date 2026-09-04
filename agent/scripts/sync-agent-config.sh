#!/usr/bin/env bash
# Stable operator entry; parsing/rendering is tested in agent_config.py (architecture §3).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=python-runtime.sh
source "$SCRIPT_DIR/python-runtime.sh"
exec "$AGENT_PYTHON" "$SCRIPT_DIR/agent_config.py" "$@"
