#!/usr/bin/env bash
# One implementation of the Docker environment/syntax smoke check.
set -euo pipefail
testing_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
exec "$testing_dir/test_docker.sh" test
