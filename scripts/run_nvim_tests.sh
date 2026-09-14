#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

NVIM_BIN="${NVIM:-nvim}"

echo "Running whisk.nvim integration tests (real Neovim)..."
echo "================================"
echo "Using: $("$NVIM_BIN" --version | head -n 1)"
echo ""

exit_code=0
"$NVIM_BIN" --headless --clean -u tests/nvim/init.lua || exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "All integration tests passed!"
else
    echo ""
    echo "Some integration tests failed."
fi

exit $exit_code
