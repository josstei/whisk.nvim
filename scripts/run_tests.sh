#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Running nvim-luxmotion tests..."
echo "================================"
echo ""

if command -v lua &> /dev/null; then
    LUA_CMD="lua"
elif command -v lua5.4 &> /dev/null; then
    LUA_CMD="lua5.4"
elif command -v lua5.3 &> /dev/null; then
    LUA_CMD="lua5.3"
elif command -v lua5.1 &> /dev/null; then
    LUA_CMD="lua5.1"
elif command -v luajit &> /dev/null; then
    LUA_CMD="luajit"
else
    echo "Error: No Lua interpreter found."
    echo "Please install Lua (5.1+) or LuaJIT."
    exit 1
fi

echo "Using Lua interpreter: $LUA_CMD"
echo ""

$LUA_CMD tests/init.lua

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "All tests passed!"
else
    echo ""
    echo "Some tests failed."
fi

exit $exit_code
