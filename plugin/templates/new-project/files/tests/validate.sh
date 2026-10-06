#!/usr/bin/env bash
# scaffolded from engineering-workflow--v{{PLUGIN_VERSION}}
# The Test gate: one command, one exit code, one line per check.
set -uo pipefail
cd "$(env -u GIT_DIR -u GIT_WORK_TREE git -C "$(dirname "$0")" rev-parse --show-toplevel)" || exit 2
check_shape() {
  local f; for f in AGENTS.md STATUS.md CONTEXT.md REVIEW.md intent/TEMPLATE.md; do [ -f "$1/$f" ] || { why="$f missing"; return 1; }; done
}
why=""; if check_shape .; then echo "ok: shape"; echo "1 ok, 0 failed"; else echo "FAIL: shape — $why"; echo "0 ok, 1 failed"; exit 1; fi
