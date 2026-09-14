#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

NVIM_BIN="${NVIM:-nvim}"
TIMEOUT_SECONDS="${WHISK_NVIM_TEST_TIMEOUT:-300}"

echo "Running whisk.nvim integration tests (real Neovim)..."
echo "================================"
echo "Using: $("$NVIM_BIN" --version | head -n 1)"
echo ""

"$NVIM_BIN" --headless --clean -u tests/nvim/init.lua &
nvim_pid=$!

(
  sleep "$TIMEOUT_SECONDS" &
  sleep_pid=$!
  trap 'kill "$sleep_pid" 2>/dev/null; exit 0' TERM
  wait "$sleep_pid"
  if kill -0 "$nvim_pid" 2>/dev/null; then
    echo ""
    echo "Integration run did not finish within ${TIMEOUT_SECONDS}s; killing Neovim."
    kill -9 "$nvim_pid" 2>/dev/null
  fi
) &
watchdog_pid=$!

exit_code=0
wait "$nvim_pid" || exit_code=$?
kill "$watchdog_pid" 2>/dev/null || true
wait "$watchdog_pid" 2>/dev/null || true

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "All integration tests passed!"
else
    echo ""
    echo "Some integration tests failed."
fi

exit $exit_code
