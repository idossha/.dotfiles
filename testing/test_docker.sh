#!/usr/bin/env bash
# Container environment/syntax smoke only. The agent platform gate is agent/tests/run.sh.
set -euo pipefail
testing_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
compose=(docker compose --project-directory "$testing_dir" -f "$testing_dir/docker-compose.yml")
case "${1:-}" in
  build) "${compose[@]}" build ;;
  run) "${compose[@]}" run --rm dotfiles-test ;;
  test)
    "${compose[@]}" build
    # shellcheck disable=SC2016 # The container, not the host, expands the smoke script.
    "${compose[@]}" run --rm -T dotfiles-test bash -euo pipefail -c '
      command -v git
      command -v curl
      command -v stow
      test -x install/linux_install.sh
      test -x install/linux_uninstall.sh
      scripts=(install/*.sh)
      test -f "${scripts[0]}"
      for script in "${scripts[@]}"; do bash -n "$script"; done
      echo "Container environment and installer syntax checked; installation was not run."
    '
    ;;
  work-test)
    echo "work-test is retired: the old test swallowed installer failures." >&2
    echo "Use a disposable container for a manual installer trial; no automated install/uninstall gate is claimed." >&2
    exit 2
    ;;
  clean) "${compose[@]}" down --rmi local --volumes --remove-orphans ;;
  *) echo "Usage: $0 build|run|test|work-test|clean" >&2; exit 2 ;;
esac
