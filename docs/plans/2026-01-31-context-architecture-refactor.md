# Context Architecture Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the broken global cache and window-0 pattern with a properly scoped Context class that encapsulates all buffer/window operations for animations.

**Architecture:** Context becomes the single abstraction for all buffer/window operations during animation. Each animation owns a Context instance that validates its target and provides fresh data for clamping. A Lifecycle module handles event-driven cancellation when contexts become invalid.

**Tech Stack:** Lua, Neovim API, busted-style test framework (custom runner in tests/)

---

## Overview

### Files to Create
- `lua/luxmotion/context/Context.lua` - Context class with metatable
- `lua/luxmotion/engine/lifecycle.lua` - Autocmd-based cancellation

### Files to Modify
- `lua/luxmotion/context/builder.lua` - Use Context.new()
- `lua/luxmotion/engine/loop.lua` - Validity checks, cancel methods
- `lua/luxmotion/engine/pool.lua` - Pool Context objects
- `lua/luxmotion/registry/builtin.lua` - Traits use context methods
- `lua/luxmotion/registry/traits.lua` - Pass context to apply
- `lua/luxmotion/init.lua` - Wire up lifecycle

### Files to Deprecate
- `lua/luxmotion/core/viewport.lua` - Remove after migration

### Test Files to Create
- `tests/unit/context/Context_spec.lua`
- `tests/unit/engine/lifecycle_spec.lua`

### Test Files to Modify
- `tests/unit/context/builder_spec.lua`
- `tests/unit/engine/loop_spec.lua` (create if not exists)
- `tests/unit/registry/builtin_spec.lua` (create if not exists)

---

## Task 1: Create Context Class - Core Structure

**Files:**
- Create: `lua/luxmotion/context/Context.lua`
- Create: `tests/unit/context/Context_spec.lua`

### Step 1: Write the failing test for Context.new()

```lua
-- tests/unit/context/Context_spec.lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('context/Context', function()
  local Context

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "line 1",
      "line 2",
      "line 3",
      "line 4",
      "line 5",
    })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    Context = require('luxmotion.context.Context')
  end)

  describe('new()', function()
    it('creates a Context with bufnr and winid', function()
      local ctx = Context.new(1, 1000)
      assert.equals(ctx.bufnr, 1)
      assert.equals(ctx.winid, 1000)
    end)

    it('captures starting state', function()
      mocks.set_cursor(3, 5)
      mocks.set_topline(2)
      local ctx = Context.new(1, 1000)
      assert.equals(ctx.start.cursor[1], 3)
      assert.equals(ctx.start.cursor[2], 5)
      assert.equals(ctx.start.topline, 2)
      assert.equals(ctx.start.line_count, 5)
    end)

    it('uses current buffer and window if not provided', function()
      local ctx = Context.new()
      assert.is_type(ctx.bufnr, 'number')
      assert.is_type(ctx.winid, 'number')
    end)
  end)
end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: FAIL with "module 'luxmotion.context.Context' not found"

### Step 3: Write minimal implementation

```lua
-- lua/luxmotion/context/Context.lua
local Context = {}
Context.__index = Context

function Context.new(bufnr, winid)
  local self = setmetatable({}, Context)

  self.bufnr = bufnr or vim.api.nvim_get_current_buf()
  self.winid = winid or vim.api.nvim_get_current_win()

  self.start = {
    cursor = vim.api.nvim_win_get_cursor(self.winid),
    topline = vim.fn.getwininfo(self.winid)[1].topline,
    line_count = vim.api.nvim_buf_line_count(self.bufnr),
  }

  return self
end

return Context
```

### Step 4: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: PASS

### Step 5: Commit

```bash
git add lua/luxmotion/context/Context.lua tests/unit/context/Context_spec.lua
git commit -m "feat(context): add Context class with new() constructor"
```

---

## Task 2: Context Class - Validity Checking

**Files:**
- Modify: `lua/luxmotion/context/Context.lua`
- Modify: `tests/unit/context/Context_spec.lua`

### Step 1: Write the failing test for is_valid()

Add to `tests/unit/context/Context_spec.lua`:

```lua
  describe('is_valid()', function()
    it('returns true for valid context', function()
      local ctx = Context.new(1, 1000)
      local valid, reason = ctx:is_valid()
      assert.is_true(valid)
      assert.is_nil(reason)
    end)

    it('returns false with reason when buffer is deleted', function()
      local ctx = Context.new(1, 1000)
      mocks.delete_buffer(1)
      local valid, reason = ctx:is_valid()
      assert.is_false(valid)
      assert.equals(reason, 'buffer_deleted')
    end)

    it('returns false with reason when window is closed', function()
      local ctx = Context.new(1, 1000)
      mocks.close_window(1000)
      local valid, reason = ctx:is_valid()
      assert.is_false(valid)
      assert.equals(reason, 'window_closed')
    end)

    it('returns false with reason when buffer changed in window', function()
      local ctx = Context.new(1, 1000)
      mocks.set_window_buffer(1000, 2)
      local valid, reason = ctx:is_valid()
      assert.is_false(valid)
      assert.equals(reason, 'buffer_changed')
    end)
  end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: FAIL with "attempt to call method 'is_valid' (a nil value)"

### Step 3: Add mock helpers for buffer/window state

Add to `tests/mocks/vim_api.lua` in the state table and API:

```lua
-- In state table:
deleted_buffers = {},
closed_windows = {},
window_buffers = {},

-- In reset():
state.deleted_buffers = {}
state.closed_windows = {}
state.window_buffers = {}

-- In api table:
nvim_buf_is_valid = function(bufnr)
  return not state.deleted_buffers[bufnr]
end,

nvim_win_is_valid = function(winid)
  return not state.closed_windows[winid]
end,

nvim_win_get_buf = function(winid)
  return state.window_buffers[winid] or 1
end,

-- Add helper functions to mocks module:
function M.delete_buffer(bufnr)
  state.deleted_buffers[bufnr] = true
end

function M.close_window(winid)
  state.closed_windows[winid] = true
end

function M.set_window_buffer(winid, bufnr)
  state.window_buffers[winid] = bufnr
end
```

### Step 4: Implement is_valid()

Add to `lua/luxmotion/context/Context.lua`:

```lua
function Context:is_valid()
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    return false, 'buffer_deleted'
  end

  if not vim.api.nvim_win_is_valid(self.winid) then
    return false, 'window_closed'
  end

  if vim.api.nvim_win_get_buf(self.winid) ~= self.bufnr then
    return false, 'buffer_changed'
  end

  return true, nil
end
```

### Step 5: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: PASS

### Step 6: Commit

```bash
git add lua/luxmotion/context/Context.lua tests/unit/context/Context_spec.lua tests/mocks/vim_api.lua
git commit -m "feat(context): add is_valid() method with buffer/window validation"
```

---

## Task 3: Context Class - Fresh Data Queries

**Files:**
- Modify: `lua/luxmotion/context/Context.lua`
- Modify: `tests/unit/context/Context_spec.lua`

### Step 1: Write the failing tests for get_line_count() and get_line_length()

Add to `tests/unit/context/Context_spec.lua`:

```lua
  describe('get_line_count()', function()
    it('returns current buffer line count', function()
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:get_line_count(), 5)
    end)

    it('returns fresh count after buffer changes', function()
      local ctx = Context.new(1, 1000)
      mocks.set_buffer_content({ "a", "b", "c" })
      assert.equals(ctx:get_line_count(), 3)
    end)
  end)

  describe('get_line_length()', function()
    it('returns length of specified line', function()
      mocks.set_buffer_content({ "abc", "defgh", "ij" })
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:get_line_length(1), 3)
      assert.equals(ctx:get_line_length(2), 5)
      assert.equals(ctx:get_line_length(3), 2)
    end)

    it('returns 0 for empty line', function()
      mocks.set_buffer_content({ "", "abc", "" })
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:get_line_length(1), 0)
      assert.equals(ctx:get_line_length(3), 0)
    end)

    it('returns 0 for non-existent line', function()
      mocks.set_buffer_content({ "abc" })
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:get_line_length(99), 0)
    end)
  end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: FAIL with "attempt to call method 'get_line_count'"

### Step 3: Implement get_line_count() and get_line_length()

Add to `lua/luxmotion/context/Context.lua`:

```lua
function Context:get_line_count()
  return vim.api.nvim_buf_line_count(self.bufnr)
end

function Context:get_line_length(line_num)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, line_num - 1, line_num, false)
  if not lines or not lines[1] then
    return 0
  end
  return #lines[1]
end
```

### Step 4: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: PASS

### Step 5: Commit

```bash
git add lua/luxmotion/context/Context.lua tests/unit/context/Context_spec.lua
git commit -m "feat(context): add get_line_count() and get_line_length() methods"
```

---

## Task 4: Context Class - Clamping Methods

**Files:**
- Modify: `lua/luxmotion/context/Context.lua`
- Modify: `tests/unit/context/Context_spec.lua`

### Step 1: Write the failing tests for clamping

Add to `tests/unit/context/Context_spec.lua`:

```lua
  describe('clamp_line()', function()
    it('returns line within valid range', function()
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:clamp_line(1), 1)
      assert.equals(ctx:clamp_line(3), 3)
      assert.equals(ctx:clamp_line(5), 5)
    end)

    it('clamps line below minimum to 1', function()
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:clamp_line(0), 1)
      assert.equals(ctx:clamp_line(-5), 1)
    end)

    it('clamps line above maximum to line count', function()
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:clamp_line(10), 5)
      assert.equals(ctx:clamp_line(100), 5)
    end)

    it('uses fresh line count', function()
      local ctx = Context.new(1, 1000)
      mocks.set_buffer_content({ "a", "b", "c" })
      assert.equals(ctx:clamp_line(5), 3)
    end)
  end)

  describe('clamp_column()', function()
    it('returns column within valid range', function()
      mocks.set_buffer_content({ "abcdef" })
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:clamp_column(0, 1), 0)
      assert.equals(ctx:clamp_column(3, 1), 3)
      assert.equals(ctx:clamp_column(5, 1), 5)
    end)

    it('clamps column below minimum to 0', function()
      mocks.set_buffer_content({ "abcdef" })
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:clamp_column(-1, 1), 0)
      assert.equals(ctx:clamp_column(-10, 1), 0)
    end)

    it('clamps column above maximum to line_length - 1', function()
      mocks.set_buffer_content({ "abcdef" })
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:clamp_column(10, 1), 5)
      assert.equals(ctx:clamp_column(100, 1), 5)
    end)

    it('handles empty line', function()
      mocks.set_buffer_content({ "" })
      local ctx = Context.new(1, 1000)
      assert.equals(ctx:clamp_column(0, 1), 0)
      assert.equals(ctx:clamp_column(5, 1), 0)
    end)
  end)

  describe('clamp_position()', function()
    it('clamps both line and column', function()
      mocks.set_buffer_content({ "abc", "defgh", "ij" })
      local ctx = Context.new(1, 1000)
      local line, col = ctx:clamp_position(2, 3)
      assert.equals(line, 2)
      assert.equals(col, 3)
    end)

    it('clamps line first then column for that line', function()
      mocks.set_buffer_content({ "abc", "defgh", "ij" })
      local ctx = Context.new(1, 1000)
      local line, col = ctx:clamp_position(10, 10)
      assert.equals(line, 3)
      assert.equals(col, 1)
    end)
  end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: FAIL with "attempt to call method 'clamp_line'"

### Step 3: Implement clamping methods

Add to `lua/luxmotion/context/Context.lua`:

```lua
function Context:clamp_line(line)
  local line_count = self:get_line_count()
  return math.max(1, math.min(line, line_count))
end

function Context:clamp_column(col, line)
  local line_length = self:get_line_length(line)
  local max_col = math.max(line_length - 1, 0)
  return math.max(0, math.min(col, max_col))
end

function Context:clamp_position(line, col)
  local clamped_line = self:clamp_line(line)
  local clamped_col = self:clamp_column(col, clamped_line)
  return clamped_line, clamped_col
end
```

### Step 4: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: PASS

### Step 5: Commit

```bash
git add lua/luxmotion/context/Context.lua tests/unit/context/Context_spec.lua
git commit -m "feat(context): add clamp_line(), clamp_column(), clamp_position() methods"
```

---

## Task 5: Context Class - Mutation Methods

**Files:**
- Modify: `lua/luxmotion/context/Context.lua`
- Modify: `tests/unit/context/Context_spec.lua`

### Step 1: Write the failing tests for set_cursor() and restore_view()

Add to `tests/unit/context/Context_spec.lua`:

```lua
  describe('set_cursor()', function()
    it('sets cursor position in context window', function()
      local ctx = Context.new(1, 1000)
      local success = ctx:set_cursor(3, 2)
      assert.is_true(success)
      local cursor = mocks.get_cursor()
      assert.equals(cursor[1], 3)
      assert.equals(cursor[2], 2)
    end)

    it('clamps position before setting', function()
      local ctx = Context.new(1, 1000)
      ctx:set_cursor(100, 100)
      local cursor = mocks.get_cursor()
      assert.equals(cursor[1], 5)
    end)

    it('returns false with reason if context invalid', function()
      local ctx = Context.new(1, 1000)
      mocks.delete_buffer(1)
      local success, reason = ctx:set_cursor(3, 2)
      assert.is_false(success)
      assert.equals(reason, 'buffer_deleted')
    end)

    it('does not modify cursor if context invalid', function()
      mocks.set_cursor(1, 0)
      local ctx = Context.new(1, 1000)
      mocks.delete_buffer(1)
      ctx:set_cursor(5, 5)
      local cursor = mocks.get_cursor()
      assert.equals(cursor[1], 1)
      assert.equals(cursor[2], 0)
    end)
  end)

  describe('restore_view()', function()
    it('restores topline and cursor position', function()
      local ctx = Context.new(1, 1000)
      local success = ctx:restore_view(5, 10, 3)
      assert.is_true(success)
    end)

    it('returns false with reason if context invalid', function()
      local ctx = Context.new(1, 1000)
      mocks.close_window(1000)
      local success, reason = ctx:restore_view(5, 10, 3)
      assert.is_false(success)
      assert.equals(reason, 'window_closed')
    end)
  end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: FAIL with "attempt to call method 'set_cursor'"

### Step 3: Update mocks to support winid-specific cursor

Add to `tests/mocks/vim_api.lua`:

```lua
-- In api table, update nvim_win_set_cursor:
nvim_win_set_cursor = function(winid, pos)
  if winid == 0 or winid == 1000 then
    state.cursor = pos
  end
end,

-- Add nvim_win_call mock:
nvim_win_call = function(winid, func)
  return func()
end,
```

### Step 4: Implement set_cursor() and restore_view()

Add to `lua/luxmotion/context/Context.lua`:

```lua
function Context:set_cursor(line, col)
  local valid, reason = self:is_valid()
  if not valid then
    return false, reason
  end

  local clamped_line, clamped_col = self:clamp_position(line, col)
  vim.api.nvim_win_set_cursor(self.winid, {clamped_line, clamped_col})
  return true
end

function Context:restore_view(topline, line, col)
  local valid, reason = self:is_valid()
  if not valid then
    return false, reason
  end

  local clamped_line, clamped_col = self:clamp_position(line, col)
  local clamped_topline = self:clamp_line(topline)

  vim.api.nvim_win_call(self.winid, function()
    vim.fn.winrestview({
      topline = clamped_topline,
      lnum = clamped_line,
      col = clamped_col,
      leftcol = 0
    })
  end)
  return true
end
```

### Step 5: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/context/Context_spec.lua`
Expected: PASS

### Step 6: Commit

```bash
git add lua/luxmotion/context/Context.lua tests/unit/context/Context_spec.lua tests/mocks/vim_api.lua
git commit -m "feat(context): add set_cursor() and restore_view() mutation methods"
```

---

## Task 6: Create Lifecycle Module

**Files:**
- Create: `lua/luxmotion/engine/lifecycle.lua`
- Create: `tests/unit/engine/lifecycle_spec.lua`

### Step 1: Write the failing test for lifecycle.setup()

```lua
-- tests/unit/engine/lifecycle_spec.lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each, after_each = runner.describe, runner.it, runner.before_each, runner.after_each

describe('engine/lifecycle', function()
  local lifecycle

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    lifecycle = require('luxmotion.engine.lifecycle')
  end)

  after_each(function()
    lifecycle.teardown()
  end)

  describe('setup()', function()
    it('creates autocmd group', function()
      lifecycle.setup()
      local state = mocks.get_api_state()
      assert.greater_than(#state.autocmds, 0)
    end)

    it('registers BufDelete autocmd', function()
      lifecycle.setup()
      local state = mocks.get_api_state()
      local found = false
      for _, autocmd in ipairs(state.autocmds) do
        if vim.tbl_contains(autocmd.events, 'BufDelete') then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it('registers WinClosed autocmd', function()
      lifecycle.setup()
      local state = mocks.get_api_state()
      local found = false
      for _, autocmd in ipairs(state.autocmds) do
        if vim.tbl_contains(autocmd.events, 'WinClosed') then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it('registers BufLeave autocmd', function()
      lifecycle.setup()
      local state = mocks.get_api_state()
      local found = false
      for _, autocmd in ipairs(state.autocmds) do
        if vim.tbl_contains(autocmd.events, 'BufLeave') then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)
  end)

  describe('teardown()', function()
    it('removes autocmd group', function()
      lifecycle.setup()
      lifecycle.teardown()
      local state = mocks.get_api_state()
      assert.equals(#state.autocmds, 0)
    end)
  end)
end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/engine/lifecycle_spec.lua`
Expected: FAIL with "module 'luxmotion.engine.lifecycle' not found"

### Step 3: Update mocks for augroup support

Add to `tests/mocks/vim_api.lua`:

```lua
-- In state table:
augroups = {},
augroup_id = 0,

-- In reset():
state.augroups = {}
state.augroup_id = 0

-- In api table:
nvim_create_augroup = function(name, opts)
  state.augroup_id = state.augroup_id + 1
  state.augroups[state.augroup_id] = { name = name, opts = opts }
  if opts and opts.clear then
    -- Remove autocmds for this group
    for i = #state.autocmds, 1, -1 do
      if state.autocmds[i].group == state.augroup_id then
        table.remove(state.autocmds, i)
      end
    end
  end
  return state.augroup_id
end,

nvim_del_augroup_by_id = function(id)
  state.augroups[id] = nil
  for i = #state.autocmds, 1, -1 do
    if state.autocmds[i].group == id then
      table.remove(state.autocmds, i)
    end
  end
end,

-- Update nvim_create_autocmd to handle events as table:
nvim_create_autocmd = function(events, opts)
  if type(events) == 'string' then
    events = { events }
  end
  state.autocmd_id = state.autocmd_id + 1
  table.insert(state.autocmds, {
    id = state.autocmd_id,
    events = events,
    opts = opts,
    group = opts.group,
  })
  return state.autocmd_id
end,
```

Add to `tests/mocks/init.lua`:

```lua
function M.get_api_state()
  return require('tests.mocks.vim_api').get_state()
end
```

### Step 4: Implement lifecycle module

```lua
-- lua/luxmotion/engine/lifecycle.lua
local M = {}

local autocmd_group = nil

function M.setup()
  local loop = require('luxmotion.engine.loop')

  autocmd_group = vim.api.nvim_create_augroup('LuxmotionLifecycle', { clear = true })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = autocmd_group,
    callback = function(args)
      loop.cancel_for_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = autocmd_group,
    callback = function(args)
      local winid = tonumber(args.match)
      if winid then
        loop.cancel_for_window(winid)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    group = autocmd_group,
    callback = function(args)
      loop.cancel_for_buffer(args.buf)
    end,
  })
end

function M.teardown()
  if autocmd_group then
    vim.api.nvim_del_augroup_by_id(autocmd_group)
    autocmd_group = nil
  end
end

function M.is_active()
  return autocmd_group ~= nil
end

return M
```

### Step 5: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/engine/lifecycle_spec.lua`
Expected: PASS (or may need loop stub - see Step 6)

### Step 6: Create loop stub if needed

The lifecycle module requires loop.cancel_for_buffer/cancel_for_window which don't exist yet. Add stubs to loop.lua temporarily:

```lua
-- Add to lua/luxmotion/engine/loop.lua temporarily:
function M.cancel_for_buffer(bufnr)
  -- TODO: implement in Task 8
end

function M.cancel_for_window(winid)
  -- TODO: implement in Task 8
end
```

### Step 7: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/engine/lifecycle_spec.lua`
Expected: PASS

### Step 8: Commit

```bash
git add lua/luxmotion/engine/lifecycle.lua lua/luxmotion/engine/loop.lua tests/unit/engine/lifecycle_spec.lua tests/mocks/vim_api.lua tests/mocks/init.lua
git commit -m "feat(lifecycle): add lifecycle module with autocmd-based context invalidation"
```

---

## Task 7: Update Context Builder

**Files:**
- Modify: `lua/luxmotion/context/builder.lua`
- Modify: `tests/unit/context/builder_spec.lua`

### Step 1: Write the failing test for Context integration

Update `tests/unit/context/builder_spec.lua`:

```lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('context/builder', function()
  local builder
  local Context

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "line 1",
      "line 2",
      "line 3",
    })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    builder = require('luxmotion.context.builder')
    Context = require('luxmotion.context.Context')
  end)

  describe('build()', function()
    it('returns a Context instance', function()
      local ctx = builder.build({})
      assert.is_table(ctx)
      assert.is_function(ctx.is_valid)
      assert.is_function(ctx.set_cursor)
    end)

    it('Context has correct bufnr and winid', function()
      local ctx = builder.build({})
      assert.is_type(ctx.bufnr, 'number')
      assert.is_type(ctx.winid, 'number')
    end)

    it('Context captures starting state', function()
      mocks.set_cursor(2, 3)
      mocks.set_topline(1)
      local ctx = builder.build({})
      assert.equals(ctx.start.cursor[1], 2)
      assert.equals(ctx.start.cursor[2], 3)
      assert.equals(ctx.start.line_count, 3)
    end)

    it('attaches input to context', function()
      local ctx = builder.build({ char = 'x', count = 5 })
      assert.equals(ctx.input.char, 'x')
      assert.equals(ctx.input.count, 5)
    end)

    it('defaults count to 1', function()
      local ctx = builder.build({})
      assert.equals(ctx.input.count, 1)
    end)
  end)
end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/context/builder_spec.lua`
Expected: FAIL (current builder returns plain table, not Context instance)

### Step 3: Implement new builder

```lua
-- lua/luxmotion/context/builder.lua
local Context = require('luxmotion.context.Context')

local M = {}

function M.build(input)
  local ctx = Context.new()

  ctx.input = {
    char = input.char,
    count = input.count or 1,
    direction = input.direction,
  }

  ctx.cursor = {
    line = ctx.start.cursor[1],
    col = ctx.start.cursor[2],
  }

  ctx.viewport = {
    topline = ctx.start.topline,
    height = vim.api.nvim_win_get_height(ctx.winid),
    width = vim.api.nvim_win_get_width(ctx.winid),
  }

  ctx.buffer = {
    line_count = ctx.start.line_count,
  }

  return ctx
end

return M
```

### Step 4: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/context/builder_spec.lua`
Expected: PASS

### Step 5: Commit

```bash
git add lua/luxmotion/context/builder.lua tests/unit/context/builder_spec.lua
git commit -m "refactor(builder): return Context instance instead of plain table"
```

---

## Task 8: Update Loop with Validity Checks and Cancel Methods

**Files:**
- Modify: `lua/luxmotion/engine/loop.lua`
- Create: `tests/unit/engine/loop_spec.lua`

### Step 1: Write the failing tests for cancel methods and validity

```lua
-- tests/unit/engine/loop_spec.lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('engine/loop', function()
  local loop
  local Context

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({ "line 1", "line 2", "line 3" })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    loop = require('luxmotion.engine.loop')
    Context = require('luxmotion.context.Context')
    loop.stop_all()
  end)

  describe('cancel_for_buffer()', function()
    it('removes animations for specified buffer', function()
      local ctx1 = Context.new(1, 1000)
      local ctx2 = Context.new(2, 1001)

      loop.start({
        context = ctx1,
        result = { cursor = { line = 3, col = 0 } },
        traits = { 'cursor' },
        duration = 100,
        easing = 'linear',
      })

      loop.start({
        context = ctx2,
        result = { cursor = { line = 3, col = 0 } },
        traits = { 'cursor' },
        duration = 100,
        easing = 'linear',
      })

      assert.equals(loop.get_active_count(), 2)
      loop.cancel_for_buffer(1)
      assert.equals(loop.get_active_count(), 1)
    end)
  end)

  describe('cancel_for_window()', function()
    it('removes animations for specified window', function()
      local ctx1 = Context.new(1, 1000)
      local ctx2 = Context.new(1, 1001)

      loop.start({
        context = ctx1,
        result = { cursor = { line = 3, col = 0 } },
        traits = { 'cursor' },
        duration = 100,
        easing = 'linear',
      })

      loop.start({
        context = ctx2,
        result = { cursor = { line = 3, col = 0 } },
        traits = { 'cursor' },
        duration = 100,
        easing = 'linear',
      })

      assert.equals(loop.get_active_count(), 2)
      loop.cancel_for_window(1000)
      assert.equals(loop.get_active_count(), 1)
    end)
  end)

  describe('process_frame validity check', function()
    it('cancels animation when context becomes invalid', function()
      local ctx = Context.new(1, 1000)
      local cancelled = false

      loop.start({
        context = ctx,
        result = { cursor = { line = 3, col = 0 } },
        traits = { 'cursor' },
        duration = 100,
        easing = 'linear',
        on_cancel = function(reason)
          cancelled = true
        end,
      })

      assert.equals(loop.get_active_count(), 1)
      mocks.delete_buffer(1)

      -- Trigger frame processing
      loop.force_process_frame()

      assert.equals(loop.get_active_count(), 0)
      assert.is_true(cancelled)
    end)
  end)
end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/engine/loop_spec.lua`
Expected: FAIL

### Step 3: Implement cancel methods and validity checks

Replace `lua/luxmotion/engine/loop.lua`:

```lua
local traits = require('luxmotion.registry.traits')
local pool = require('luxmotion.engine.pool')
local performance = require('luxmotion.performance')

local M = {}

local frame_queue = {}
local is_running = false

local easing_functions = {
  linear = function(t) return t end,
  ['ease-in'] = function(t) return t * t end,
  ['ease-out'] = function(t) return 1 - (1 - t) * (1 - t) end,
  ['ease-in-out'] = function(t)
    if t < 0.5 then
      return 2 * t * t
    else
      return 1 - 2 * (1 - t) * (1 - t)
    end
  end,
}

local function lerp(start_val, end_val, progress)
  return start_val + (end_val - start_val) * progress
end

local function interpolate_result(context, result, progress)
  local interpolated = { cursor = {}, viewport = {} }

  if result.cursor then
    interpolated.cursor.line = math.floor(lerp(context.cursor.line, result.cursor.line, progress) + 0.5)
    interpolated.cursor.col = math.floor(lerp(context.cursor.col, result.cursor.col, progress) + 0.5)
  end

  if result.viewport and result.viewport.topline then
    interpolated.viewport.topline = math.floor(lerp(context.viewport.topline, result.viewport.topline, progress) + 0.5)
  end

  return interpolated
end

local function process_frame()
  local current_time = vim.loop.hrtime()
  performance.record_frame_time()

  for i = #frame_queue, 1, -1 do
    local anim = frame_queue[i]

    local valid, reason = anim.context:is_valid()
    if not valid then
      if anim.on_cancel then
        anim.on_cancel(reason)
      end
      table.remove(frame_queue, i)
      pool.release(anim)
      goto continue
    end

    local elapsed = current_time - anim.start_time
    local progress = math.min(elapsed / anim.duration_ns, 1.0)
    local eased = anim.easing_fn(progress)

    local interpolated = interpolate_result(anim.context, anim.result, eased)

    for _, trait_id in ipairs(anim.traits) do
      traits.apply_frame(trait_id, anim.context, interpolated, eased)
    end

    if progress >= 1.0 then
      if anim.on_complete then
        anim.on_complete()
      end
      table.remove(frame_queue, i)
      pool.release(anim)
    end

    ::continue::
  end

  if #frame_queue > 0 then
    vim.defer_fn(process_frame, performance.get_frame_interval())
  else
    is_running = false
  end
end

function M.get_easing(easing_type)
  return easing_functions[easing_type] or easing_functions.linear
end

function M.start(options)
  local anim = pool.acquire()
  anim.start_time = vim.loop.hrtime()
  anim.duration_ns = options.duration * 1000000
  anim.easing_fn = M.get_easing(options.easing)
  anim.context = options.context
  anim.result = options.result
  anim.traits = options.traits
  anim.on_complete = options.on_complete
  anim.on_cancel = options.on_cancel

  table.insert(frame_queue, anim)

  if not is_running then
    is_running = true
    vim.defer_fn(process_frame, performance.get_frame_interval())
  end
end

function M.stop_all()
  for _, anim in ipairs(frame_queue) do
    pool.release(anim)
  end
  frame_queue = {}
  is_running = false
end

function M.cancel_for_buffer(bufnr)
  for i = #frame_queue, 1, -1 do
    local anim = frame_queue[i]
    if anim.context.bufnr == bufnr then
      if anim.on_cancel then
        anim.on_cancel('buffer_invalidated')
      end
      pool.release(anim)
      table.remove(frame_queue, i)
    end
  end

  if #frame_queue == 0 then
    is_running = false
  end
end

function M.cancel_for_window(winid)
  for i = #frame_queue, 1, -1 do
    local anim = frame_queue[i]
    if anim.context.winid == winid then
      if anim.on_cancel then
        anim.on_cancel('window_invalidated')
      end
      pool.release(anim)
      table.remove(frame_queue, i)
    end
  end

  if #frame_queue == 0 then
    is_running = false
  end
end

function M.get_active_count()
  return #frame_queue
end

function M.is_running()
  return is_running
end

function M.force_process_frame()
  if #frame_queue > 0 then
    process_frame()
  end
end

return M
```

### Step 4: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/engine/loop_spec.lua`
Expected: PASS

### Step 5: Commit

```bash
git add lua/luxmotion/engine/loop.lua tests/unit/engine/loop_spec.lua
git commit -m "feat(loop): add cancel_for_buffer/window and validity checks per frame"
```

---

## Task 9: Update Traits to Use Context Methods

**Files:**
- Modify: `lua/luxmotion/registry/builtin.lua`
- Create: `tests/unit/registry/builtin_spec.lua`

### Step 1: Write the failing test for context-aware traits

```lua
-- tests/unit/registry/builtin_spec.lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('registry/builtin', function()
  local builtin
  local traits
  local Context

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({ "line 1", "line 2", "line 3" })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)

    traits = require('luxmotion.registry.traits')
    traits.clear()
    builtin = require('luxmotion.registry.builtin')
    Context = require('luxmotion.context.Context')
    builtin.register_traits()
  end)

  describe('cursor trait', function()
    it('uses context set_cursor method', function()
      local ctx = Context.new(1, 1000)
      local result = { cursor = { line = 2, col = 5 } }

      traits.apply_frame('cursor', ctx, result, 1.0)

      local cursor = mocks.get_cursor()
      assert.equals(cursor[1], 2)
      assert.equals(cursor[2], 5)
    end)

    it('does not set cursor when context is invalid', function()
      local ctx = Context.new(1, 1000)
      mocks.set_cursor(1, 0)
      mocks.delete_buffer(1)

      local result = { cursor = { line = 2, col = 5 } }
      traits.apply_frame('cursor', ctx, result, 1.0)

      local cursor = mocks.get_cursor()
      assert.equals(cursor[1], 1)
      assert.equals(cursor[2], 0)
    end)
  end)

  describe('scroll trait', function()
    it('uses context restore_view method', function()
      local ctx = Context.new(1, 1000)
      local result = {
        cursor = { line = 5, col = 0 },
        viewport = { topline = 3 },
      }

      traits.apply_frame('scroll', ctx, result, 1.0)
      -- If no error, it passed (restore_view was called on valid context)
    end)
  end)
end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/registry/builtin_spec.lua`
Expected: FAIL (current traits use viewport module, not context methods)

### Step 3: Update builtin.lua to use context methods

```lua
-- lua/luxmotion/registry/builtin.lua
local traits = require('luxmotion.registry.traits')
local motions = require('luxmotion.registry.motions')
local calculators = require('luxmotion.calculators')

local M = {}

function M.register_traits()
  traits.register({
    id = 'cursor',
    apply = function(context, result, progress)
      if result.cursor then
        context:set_cursor(result.cursor.line, result.cursor.col)
      end
    end,
  })

  traits.register({
    id = 'scroll',
    apply = function(context, result, progress)
      if result.viewport and result.viewport.topline then
        context:restore_view(result.viewport.topline, result.cursor.line, result.cursor.col)
      end
    end,
  })
end

function M.register_motions()
  for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
    motions.register({
      id = 'basic_' .. dir,
      keys = { dir },
      modes = { 'n', 'v' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = calculators.basic[dir],
      description = 'move ' .. dir,
      input = 'count',
    })
  end

  motions.register({
    id = 'basic_0',
    keys = { '0' },
    modes = { 'n', 'v' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = calculators.basic['0'],
    description = 'move to line start',
  })

  motions.register({
    id = 'basic_$',
    keys = { '$' },
    modes = { 'n', 'v' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = calculators.basic['$'],
    description = 'move to line end',
  })

  for _, dir in ipairs({ 'w', 'b', 'e', 'W', 'B', 'E' }) do
    motions.register({
      id = 'word_' .. dir,
      keys = { dir },
      modes = { 'n', 'v' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = calculators.word[dir],
      description = 'word ' .. dir,
      input = 'count',
    })
  end

  for _, dir in ipairs({ 'f', 'F', 't', 'T' }) do
    motions.register({
      id = 'find_' .. dir,
      keys = { dir },
      modes = { 'n', 'v' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = calculators.find[dir],
      description = 'find ' .. dir,
      input = 'char',
    })
  end

  local text_objects = {
    ['{'] = 'paragraph backward',
    ['}'] = 'paragraph forward',
    ['('] = 'sentence backward',
    [')'] = 'sentence forward',
    ['%'] = 'matching bracket',
  }
  for key, desc in pairs(text_objects) do
    motions.register({
      id = 'text_object_' .. key,
      keys = { key },
      modes = { 'n', 'v' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = calculators.text_object[key],
      description = desc,
      input = 'count',
    })
  end

  motions.register({
    id = 'line_gg',
    keys = { 'gg' },
    modes = { 'n', 'v' },
    traits = { 'cursor', 'scroll' },
    category = 'cursor',
    calculator = calculators.line.gg,
    description = 'goto first line',
    input = 'count',
  })

  motions.register({
    id = 'line_G',
    keys = { 'G' },
    modes = { 'n', 'v' },
    traits = { 'cursor', 'scroll' },
    category = 'cursor',
    calculator = calculators.line.G,
    description = 'goto last line',
    input = 'count',
  })

  motions.register({
    id = 'line_|',
    keys = { '|' },
    modes = { 'n', 'v' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = calculators.line['|'],
    description = 'goto column',
    input = 'count',
  })

  motions.register({
    id = 'search_n',
    keys = { 'n' },
    modes = { 'n', 'v' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = calculators.search.n,
    description = 'next search result',
    input = 'count',
  })

  motions.register({
    id = 'search_N',
    keys = { 'N' },
    modes = { 'n', 'v' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = calculators.search.N,
    description = 'previous search result',
    input = 'count',
  })

  motions.register({
    id = 'screen_gj',
    keys = { 'gj' },
    modes = { 'n', 'v' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = calculators.search.gj,
    description = 'down screen line',
    input = 'count',
  })

  motions.register({
    id = 'screen_gk',
    keys = { 'gk' },
    modes = { 'n', 'v' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = calculators.search.gk,
    description = 'up screen line',
    input = 'count',
  })

  motions.register({
    id = 'scroll_ctrl_d',
    keys = { '<C-d>' },
    modes = { 'n', 'v' },
    traits = { 'cursor', 'scroll' },
    category = 'scroll',
    calculator = calculators.scroll.ctrl_d,
    description = 'scroll down half-page',
    input = 'count',
  })

  motions.register({
    id = 'scroll_ctrl_u',
    keys = { '<C-u>' },
    modes = { 'n', 'v' },
    traits = { 'cursor', 'scroll' },
    category = 'scroll',
    calculator = calculators.scroll.ctrl_u,
    description = 'scroll up half-page',
    input = 'count',
  })

  motions.register({
    id = 'scroll_ctrl_f',
    keys = { '<C-f>' },
    modes = { 'n', 'v' },
    traits = { 'cursor', 'scroll' },
    category = 'scroll',
    calculator = calculators.scroll.ctrl_f,
    description = 'scroll down full-page',
    input = 'count',
  })

  motions.register({
    id = 'scroll_ctrl_b',
    keys = { '<C-b>' },
    modes = { 'n', 'v' },
    traits = { 'cursor', 'scroll' },
    category = 'scroll',
    calculator = calculators.scroll.ctrl_b,
    description = 'scroll up full-page',
    input = 'count',
  })

  motions.register({
    id = 'position_zz',
    keys = { 'zz' },
    modes = { 'n' },
    traits = { 'scroll' },
    category = 'scroll',
    calculator = calculators.scroll.zz,
    description = 'center cursor',
  })

  motions.register({
    id = 'position_zt',
    keys = { 'zt' },
    modes = { 'n' },
    traits = { 'scroll' },
    category = 'scroll',
    calculator = calculators.scroll.zt,
    description = 'cursor to top',
  })

  motions.register({
    id = 'position_zb',
    keys = { 'zb' },
    modes = { 'n' },
    traits = { 'scroll' },
    category = 'scroll',
    calculator = calculators.scroll.zb,
    description = 'cursor to bottom',
  })
end

function M.register_all()
  M.register_traits()
  M.register_motions()
end

return M
```

### Step 4: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/registry/builtin_spec.lua`
Expected: PASS

### Step 5: Commit

```bash
git add lua/luxmotion/registry/builtin.lua tests/unit/registry/builtin_spec.lua
git commit -m "refactor(traits): use context methods instead of viewport module"
```

---

## Task 10: Wire Up Lifecycle in Init

**Files:**
- Modify: `lua/luxmotion/init.lua`
- Modify: `tests/unit/init_spec.lua`

### Step 1: Write the failing test for lifecycle integration

Update `tests/unit/init_spec.lua` to include:

```lua
  it('setup initializes lifecycle', function()
    local lifecycle = require('luxmotion.engine.lifecycle')
    luxmotion.setup({})
    assert.is_true(lifecycle.is_active())
  end)

  it('reset tears down lifecycle', function()
    local lifecycle = require('luxmotion.engine.lifecycle')
    luxmotion.setup({})
    luxmotion.reset()
    assert.is_false(lifecycle.is_active())
  end)
```

### Step 2: Run test to verify it fails

Run: `./scripts/run_tests.sh tests/unit/init_spec.lua`
Expected: FAIL

### Step 3: Update init.lua

```lua
-- lua/luxmotion/init.lua
local config = require('luxmotion.config')
local builtin = require('luxmotion.registry.builtin')
local keymaps = require('luxmotion.registry.keymaps')
local traits = require('luxmotion.registry.traits')
local motions = require('luxmotion.registry.motions')
local loop = require('luxmotion.engine.loop')
local lifecycle = require('luxmotion.engine.lifecycle')

local M = {}

local initialized = false

function M.setup(user_config)
  if initialized then
    M.reset()
  end

  config.validate(user_config)
  config.update(user_config)

  local performance = require('luxmotion.performance')
  performance.setup()

  builtin.register_all()
  keymaps.setup()
  lifecycle.setup()

  initialized = true
end

function M.reset()
  keymaps.clear()
  loop.stop_all()
  traits.clear()
  motions.clear()
  lifecycle.teardown()
  initialized = false
end

function M.enable()
  local cfg = config.get()
  cfg.cursor.enabled = true
  cfg.scroll.enabled = true
end

function M.disable()
  local cfg = config.get()
  cfg.cursor.enabled = false
  cfg.scroll.enabled = false
end

function M.toggle()
  local cfg = config.get()
  if cfg.cursor.enabled or cfg.scroll.enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.enable_cursor()
  config.get().cursor.enabled = true
end

function M.disable_cursor()
  config.get().cursor.enabled = false
end

function M.enable_scroll()
  config.get().scroll.enabled = true
end

function M.disable_scroll()
  config.get().scroll.enabled = false
end

function M.toggle_performance()
  local performance = require('luxmotion.performance')
  if performance.is_active() then
    performance.disable()
  else
    performance.enable()
  end
end

return M
```

### Step 4: Run test to verify it passes

Run: `./scripts/run_tests.sh tests/unit/init_spec.lua`
Expected: PASS

### Step 5: Commit

```bash
git add lua/luxmotion/init.lua tests/unit/init_spec.lua
git commit -m "feat(init): wire up lifecycle module in setup/reset"
```

---

## Task 11: Deprecate viewport.lua

**Files:**
- Delete: `lua/luxmotion/core/viewport.lua`
- Delete: `tests/unit/core/viewport_spec.lua`
- Update: Any remaining references

### Step 1: Search for remaining viewport references

Run: `grep -r "require.*viewport" lua/`
Expected: Should find no references after previous tasks

### Step 2: Delete viewport module and tests

```bash
rm lua/luxmotion/core/viewport.lua
rm tests/unit/core/viewport_spec.lua
rmdir lua/luxmotion/core 2>/dev/null || true
rmdir tests/unit/core 2>/dev/null || true
```

### Step 3: Run full test suite

Run: `./scripts/run_tests.sh`
Expected: All tests PASS

### Step 4: Commit

```bash
git add -A
git commit -m "chore: remove deprecated viewport module (replaced by Context class)"
```

---

## Task 12: Update Pool for Context-Aware Animations

**Files:**
- Modify: `lua/luxmotion/engine/pool.lua`

### Step 1: Update pool to include on_cancel field

```lua
-- lua/luxmotion/engine/pool.lua
local M = {}

local animation_pool = {}
local pool_size = 0
local MAX_POOL_SIZE = 10

function M.acquire()
  if pool_size > 0 then
    pool_size = pool_size - 1
    return table.remove(animation_pool)
  else
    return {
      start_time = 0,
      duration_ns = 0,
      easing_fn = nil,
      context = nil,
      result = nil,
      traits = nil,
      on_complete = nil,
      on_cancel = nil,
    }
  end
end

function M.release(animation)
  if pool_size < MAX_POOL_SIZE then
    animation.start_time = 0
    animation.duration_ns = 0
    animation.easing_fn = nil
    animation.context = nil
    animation.result = nil
    animation.traits = nil
    animation.on_complete = nil
    animation.on_cancel = nil
    pool_size = pool_size + 1
    table.insert(animation_pool, animation)
  end
end

function M.get_stats()
  return {
    pool_size = pool_size,
    max_pool_size = MAX_POOL_SIZE,
  }
end

function M.clear()
  animation_pool = {}
  pool_size = 0
end

return M
```

### Step 2: Commit

```bash
git add lua/luxmotion/engine/pool.lua
git commit -m "chore(pool): add on_cancel field to animation pool objects"
```

---

## Task 13: Integration Test - Full Animation Cycle

**Files:**
- Create: `tests/integration/context_lifecycle_spec.lua`

### Step 1: Write integration test

```lua
-- tests/integration/context_lifecycle_spec.lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('Integration: Context + Lifecycle', function()
  local luxmotion
  local loop
  local Context

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "line 1", "line 2", "line 3", "line 4", "line 5",
      "line 6", "line 7", "line 8", "line 9", "line 10",
    })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)

    luxmotion = require('luxmotion')
    loop = require('luxmotion.engine.loop')
    Context = require('luxmotion.context.Context')

    luxmotion.setup({})
  end)

  it('animation completes successfully with valid context', function()
    local ctx = Context.new(1, 1000)
    local completed = false

    loop.start({
      context = ctx,
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      duration = 10,
      easing = 'linear',
      on_complete = function()
        completed = true
      end,
    })

    -- Simulate time passing and frame processing
    for _ = 1, 10 do
      loop.force_process_frame()
    end

    assert.is_true(completed)
  end)

  it('animation cancels when buffer is deleted mid-animation', function()
    local ctx = Context.new(1, 1000)
    local cancelled = false
    local cancel_reason = nil

    loop.start({
      context = ctx,
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      duration = 100,
      easing = 'linear',
      on_cancel = function(reason)
        cancelled = true
        cancel_reason = reason
      end,
    })

    assert.equals(loop.get_active_count(), 1)

    mocks.delete_buffer(1)
    loop.force_process_frame()

    assert.is_true(cancelled)
    assert.equals(cancel_reason, 'buffer_deleted')
    assert.equals(loop.get_active_count(), 0)
  end)

  it('cursor is clamped when buffer shrinks during animation', function()
    local ctx = Context.new(1, 1000)

    loop.start({
      context = ctx,
      result = { cursor = { line = 10, col = 0 } },
      traits = { 'cursor' },
      duration = 10,
      easing = 'linear',
    })

    -- Shrink buffer mid-animation
    mocks.set_buffer_content({ "line 1", "line 2", "line 3" })

    -- Process frames
    for _ = 1, 10 do
      loop.force_process_frame()
    end

    local cursor = mocks.get_cursor()
    assert.equals(cursor[1], 3) -- Clamped to new max
  end)
end)
```

### Step 2: Run integration tests

Run: `./scripts/run_tests.sh tests/integration/`
Expected: All PASS

### Step 3: Commit

```bash
git add tests/integration/context_lifecycle_spec.lua
git commit -m "test: add integration tests for context lifecycle"
```

---

## Task 14: Run Full Test Suite and Final Verification

### Step 1: Run all tests

Run: `./scripts/run_tests.sh`
Expected: All tests PASS

### Step 2: Manual smoke test in Neovim

```
1. Open a file with 100+ lines
2. Navigate using j/k/gg/G with animations
3. While animating, delete lines with dd
4. Verify no "Cursor position outside buffer" errors
5. Switch buffers during animation
6. Verify animation cancels gracefully
```

### Step 3: Final commit

```bash
git add -A
git commit -m "feat: complete context architecture refactor

- Add Context class with buffer/window scoping
- Add Lifecycle module for event-driven cancellation
- Update loop with validity checks and cancel methods
- Update traits to use context methods
- Remove deprecated viewport module with global cache

Fixes cursor position outside buffer error caused by stale cache."
```

---

## Summary

| Task | Description | Files Changed |
|------|-------------|---------------|
| 1 | Context class - core structure | +2 |
| 2 | Context - validity checking | ~2 |
| 3 | Context - fresh data queries | ~2 |
| 4 | Context - clamping methods | ~2 |
| 5 | Context - mutation methods | ~2 |
| 6 | Lifecycle module | +2 |
| 7 | Update context builder | ~2 |
| 8 | Update loop with validity/cancel | ~2 |
| 9 | Update traits to use context | ~2 |
| 10 | Wire up lifecycle in init | ~2 |
| 11 | Remove deprecated viewport | -2 |
| 12 | Update pool for on_cancel | ~1 |
| 13 | Integration tests | +1 |
| 14 | Final verification | - |

**Total: 14 tasks, ~20 files touched**
