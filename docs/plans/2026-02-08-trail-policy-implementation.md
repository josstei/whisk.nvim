# Trail Policy System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a policy abstraction layer that filters trail visibility based on movement distance and motion type, reducing visual noise on trivial cursor movements.

**Architecture:** A policy registry (`lua/luxmotion/trail/policies/`) with three built-in policies (always, never, distance). Each motion declares a `trail_policy` field. The trail trait evaluates the policy once at animation start and caches the decision. Resolution chain: user overrides > motion declaration > category default > "always" fallback.

**Tech Stack:** Lua, custom test runner (`tests/runner.lua`), vim mock layer (`tests/mocks/`)

**Design Document:** `docs/plans/2026-02-08-trail-policy-system-design.md`

---

## Task 1: Always Policy

**Files:**
- Create: `lua/luxmotion/trail/policies/always.lua`
- Test: `tests/unit/trail/policies/always_spec.lua`

**Step 1: Write the failing test**

Create `tests/unit/trail/policies/always_spec.lua`:

```lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/always', function()
  local always

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    always = require('luxmotion.trail.policies.always')
  end)

  it('exports id field', function()
    assert.equals(always.id, 'always')
  end)

  it('exports should_trail function', function()
    assert.is_type(always.should_trail, 'function')
  end)

  it('returns true for any context and result', function()
    local context = { cursor = { line = 1, col = 0 }, motion_id = 'basic_j' }
    local result = { cursor = { line = 2, col = 0 } }
    assert.is_true(always.should_trail(context, result))
  end)

  it('returns true with nil cursor in result', function()
    local context = { cursor = { line = 1, col = 0 }, motion_id = 'position_zz' }
    local result = { viewport = { topline = 5 } }
    assert.is_true(always.should_trail(context, result))
  end)

  it('returns true with empty context and result', function()
    assert.is_true(always.should_trail({}, {}))
  end)
end)
```

**Step 2: Run test to verify it fails**

Run: `./scripts/run_tests.sh`
Expected: FAIL - module 'luxmotion.trail.policies.always' not found

**Step 3: Write minimal implementation**

Create `lua/luxmotion/trail/policies/always.lua`:

```lua
local M = {}

M.id = "always"

function M.should_trail(_context, _result)
  return true
end

return M
```

**Step 4: Run test to verify it passes**

Run: `./scripts/run_tests.sh`
Expected: PASS (all 524 tests)

**Step 5: Commit**

```bash
git add lua/luxmotion/trail/policies/always.lua tests/unit/trail/policies/always_spec.lua
git commit -m "feat(trail): add always trail policy"
```

---

## Task 2: Never Policy

**Files:**
- Create: `lua/luxmotion/trail/policies/never.lua`
- Test: `tests/unit/trail/policies/never_spec.lua`

**Step 1: Write the failing test**

Create `tests/unit/trail/policies/never_spec.lua`:

```lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/never', function()
  local never

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    never = require('luxmotion.trail.policies.never')
  end)

  it('exports id field', function()
    assert.equals(never.id, 'never')
  end)

  it('exports should_trail function', function()
    assert.is_type(never.should_trail, 'function')
  end)

  it('returns false for any context and result', function()
    local context = { cursor = { line = 1, col = 0 }, motion_id = 'basic_j' }
    local result = { cursor = { line = 100, col = 50 } }
    assert.is_false(never.should_trail(context, result))
  end)

  it('returns false with empty context and result', function()
    assert.is_false(never.should_trail({}, {}))
  end)
end)
```

**Step 2: Run test to verify it fails**

Run: `./scripts/run_tests.sh`
Expected: FAIL - module 'luxmotion.trail.policies.never' not found

**Step 3: Write minimal implementation**

Create `lua/luxmotion/trail/policies/never.lua`:

```lua
local M = {}

M.id = "never"

function M.should_trail(_context, _result)
  return false
end

return M
```

**Step 4: Run test to verify it passes**

Run: `./scripts/run_tests.sh`
Expected: PASS (all 528 tests)

**Step 5: Commit**

```bash
git add lua/luxmotion/trail/policies/never.lua tests/unit/trail/policies/never_spec.lua
git commit -m "feat(trail): add never trail policy"
```

---

## Task 3: Distance Policy

**Files:**
- Create: `lua/luxmotion/trail/policies/distance.lua`
- Test: `tests/unit/trail/policies/distance_spec.lua`

**Step 1: Write the failing test**

Create `tests/unit/trail/policies/distance_spec.lua`:

```lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/distance', function()
  local distance

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    distance = require('luxmotion.trail.policies.distance')
  end)

  it('exports id field', function()
    assert.equals(distance.id, 'distance')
  end)

  it('exports create function', function()
    assert.is_type(distance.create, 'function')
  end)

  it('create returns a policy with should_trail', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    assert.is_type(policy.should_trail, 'function')
    assert.equals(policy.id, 'distance')
  end)

  it('returns false when movement is below both thresholds', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 2, col = 3 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns true when line movement meets threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 3, col = 0 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('returns true when column movement meets threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 1, col = 5 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('returns true when both axes meet threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 5, col = 10 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('returns false at exactly one below line threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 2, col = 0 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns false at exactly one below col threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 1, col = 4 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns false when result has no cursor', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { viewport = { topline = 5 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns false for zero movement', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 5, col = 10 } }
    local result = { cursor = { line = 5, col = 10 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('handles backward movement (negative delta)', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 10, col = 20 } }
    local result = { cursor = { line = 7, col = 20 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('respects custom thresholds', function()
    local policy = distance.create({ min_lines = 5, min_cols = 10 })
    local context = { cursor = { line = 1, col = 0 } }
    local result_short = { cursor = { line = 5, col = 0 } }
    local result_long = { cursor = { line = 6, col = 0 } }
    assert.is_false(policy.should_trail(context, result_short))
    assert.is_true(policy.should_trail(context, result_long))
  end)
end)
```

**Step 2: Run test to verify it fails**

Run: `./scripts/run_tests.sh`
Expected: FAIL - module 'luxmotion.trail.policies.distance' not found

**Step 3: Write minimal implementation**

Create `lua/luxmotion/trail/policies/distance.lua`:

```lua
local M = {}

M.id = "distance"

function M.create(thresholds)
  local min_lines = thresholds.min_lines
  local min_cols = thresholds.min_cols

  return {
    id = "distance",
    should_trail = function(context, result)
      if not result.cursor then
        return false
      end
      local delta_line = math.abs(result.cursor.line - context.cursor.line)
      local delta_col = math.abs(result.cursor.col - context.cursor.col)
      return delta_line >= min_lines or delta_col >= min_cols
    end,
  }
end

return M
```

**Step 4: Run test to verify it passes**

Run: `./scripts/run_tests.sh`
Expected: PASS (all 540 tests)

**Step 5: Commit**

```bash
git add lua/luxmotion/trail/policies/distance.lua tests/unit/trail/policies/distance_spec.lua
git commit -m "feat(trail): add distance trail policy with configurable thresholds"
```

---

## Task 4: Policy Registry

**Files:**
- Create: `lua/luxmotion/trail/policies/init.lua`
- Test: `tests/unit/trail/policies/registry_spec.lua`

**Step 1: Write the failing test**

Create `tests/unit/trail/policies/registry_spec.lua`:

```lua
local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/registry', function()
  local policies
  local config

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    policies = require('luxmotion.trail.policies')
    config = require('luxmotion.config')
    policies.clear()
  end)

  it('exports all required functions', function()
    assert.is_type(policies.register, 'function')
    assert.is_type(policies.get, 'function')
    assert.is_type(policies.resolve, 'function')
    assert.is_type(policies.clear, 'function')
  end)

  it('register adds a policy', function()
    policies.register({
      id = 'test_policy',
      should_trail = function() return true end,
    })
    local policy = policies.get('test_policy')
    assert.is_not_nil(policy)
    assert.equals(policy.id, 'test_policy')
  end)

  it('get returns nil for unknown policy', function()
    assert.is_nil(policies.get('nonexistent'))
  end)

  it('register overwrites existing policy', function()
    local fn1 = function() return true end
    local fn2 = function() return false end
    policies.register({ id = 'same', should_trail = fn1 })
    policies.register({ id = 'same', should_trail = fn2 })
    local policy = policies.get('same')
    assert.equals(policy.should_trail, fn2)
  end)

  it('clear removes all policies', function()
    policies.register({ id = 'p1', should_trail = function() return true end })
    policies.clear()
    assert.is_nil(policies.get('p1'))
  end)

  it('resolve returns user override when present', function()
    policies.register({ id = 'always', should_trail = function() return true end })
    policies.register({ id = 'never', should_trail = function() return false end })

    config.update({
      cursor = {
        trail = {
          overrides = { basic_j = 'never' },
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      trail_policy = 'always',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'never')
  end)

  it('resolve returns motion trail_policy when no override', function()
    policies.register({ id = 'always', should_trail = function() return true end })
    policies.register({ id = 'never', should_trail = function() return false end })

    config.update({
      cursor = {
        trail = {
          overrides = {},
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      trail_policy = 'never',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'never')
  end)

  it('resolve returns category default when no override and no motion policy', function()
    policies.register({ id = 'always', should_trail = function() return true end })
    policies.register({ id = 'never', should_trail = function() return false end })

    config.update({
      cursor = {
        trail = {
          policy = 'never',
          overrides = {},
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'never')
  end)

  it('resolve falls back to always when nothing configured', function()
    policies.register({ id = 'always', should_trail = function() return true end })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'always')
  end)

  it('resolve logs warning for unknown override policy ID', function()
    policies.register({ id = 'always', should_trail = function() return true end })

    config.update({
      cursor = {
        trail = {
          overrides = { basic_j = 'nonexistent_policy' },
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      trail_policy = 'always',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'always')

    local notifications = mocks.get_notifications()
    local found_warning = false
    for _, notif in ipairs(notifications) do
      if notif.message:match('nonexistent_policy') then
        found_warning = true
      end
    end
    assert.is_true(found_warning)
  end)

  it('resolve returns always fallback for unknown motion', function()
    policies.register({ id = 'always', should_trail = function() return true end })

    local policy = policies.resolve('nonexistent_motion')
    assert.equals(policy.id, 'always')
  end)
end)
```

**Step 2: Run test to verify it fails**

Run: `./scripts/run_tests.sh`
Expected: FAIL - module 'luxmotion.trail.policies' not found (or init.lua missing)

**Step 3: Write minimal implementation**

Create `lua/luxmotion/trail/policies/init.lua`:

```lua
local config = require("luxmotion.config")
local motions = require("luxmotion.registry.motions")

local M = {}

local policies = {}

function M.register(definition)
  policies[definition.id] = {
    id = definition.id,
    should_trail = definition.should_trail,
  }
end

function M.get(policy_id)
  return policies[policy_id]
end

function M.resolve(motion_id)
  local motion = motions.get(motion_id)
  local category = motion and motion.category or "cursor"
  local category_config = config.get(category)
  local trail_config = category_config and category_config.trail

  local override_id = trail_config and trail_config.overrides and trail_config.overrides[motion_id]
  if override_id then
    local override_policy = policies[override_id]
    if override_policy then
      return override_policy
    end
    vim.notify(
      string.format("[luxmotion] Unknown trail policy '%s' in overrides for motion '%s'", override_id, motion_id),
      vim.log.levels.WARN
    )
  end

  if motion and motion.trail_policy then
    local motion_policy = policies[motion.trail_policy]
    if motion_policy then
      return motion_policy
    end
  end

  local default_id = trail_config and trail_config.policy
  if default_id then
    local default_policy = policies[default_id]
    if default_policy then
      return default_policy
    end
  end

  return policies["always"] or { id = "always", should_trail = function() return true end }
end

function M.clear()
  policies = {}
end

return M
```

**Step 4: Run test to verify it passes**

Run: `./scripts/run_tests.sh`
Expected: PASS (all 548 tests)

**Step 5: Commit**

```bash
git add lua/luxmotion/trail/policies/init.lua tests/unit/trail/policies/registry_spec.lua
git commit -m "feat(trail): add policy registry with resolution chain"
```

---

## Task 5: Config Defaults & Validation

**Files:**
- Modify: `lua/luxmotion/config/defaults.lua`
- Modify: `lua/luxmotion/config/validation.lua`
- Modify: `tests/unit/config/defaults_spec.lua` (add policy assertions)
- Modify: `tests/unit/config/validation_spec.lua` (add policy validation tests)

**Step 1: Write failing tests for defaults**

Add to existing `tests/unit/config/defaults_spec.lua` — append these tests inside the existing describe block. First read the file to find the right insertion point.

New tests to add:

```lua
it('cursor trail has policy default', function()
  assert.equals(defaults.config.cursor.trail.policy, 'distance')
end)

it('cursor trail has distance thresholds', function()
  assert.equals(defaults.config.cursor.trail.distance.min_lines, 2)
  assert.equals(defaults.config.cursor.trail.distance.min_cols, 5)
end)

it('cursor trail has empty overrides', function()
  assert.is_type(defaults.config.cursor.trail.overrides, 'table')
end)

it('scroll trail has policy default', function()
  assert.equals(defaults.config.scroll.trail.policy, 'always')
end)

it('scroll trail has distance thresholds', function()
  assert.equals(defaults.config.scroll.trail.distance.min_lines, 2)
  assert.equals(defaults.config.scroll.trail.distance.min_cols, 5)
end)

it('scroll trail has empty overrides', function()
  assert.is_type(defaults.config.scroll.trail.overrides, 'table')
end)
```

**Step 2: Write failing tests for validation**

Add to existing `tests/unit/config/validation_spec.lua` — new tests for trail policy validation:

```lua
it('accepts valid trail policy string', function()
  assert.does_not_throw(function()
    validation.validate_config({
      cursor = { trail = { policy = 'distance' } },
    })
  end)
end)

it('rejects non-string trail policy', function()
  assert.throws(function()
    validation.validate_config({
      cursor = { trail = { policy = 123 } },
    })
  end)
end)

it('accepts valid distance thresholds', function()
  assert.does_not_throw(function()
    validation.validate_config({
      cursor = { trail = { distance = { min_lines = 3, min_cols = 8 } } },
    })
  end)
end)

it('rejects non-number min_lines', function()
  assert.throws(function()
    validation.validate_config({
      cursor = { trail = { distance = { min_lines = 'two' } } },
    })
  end)
end)

it('rejects negative min_lines', function()
  assert.throws(function()
    validation.validate_config({
      cursor = { trail = { distance = { min_lines = -1 } } },
    })
  end)
end)

it('rejects non-number min_cols', function()
  assert.throws(function()
    validation.validate_config({
      cursor = { trail = { distance = { min_cols = true } } },
    })
  end)
end)

it('rejects negative min_cols', function()
  assert.throws(function()
    validation.validate_config({
      cursor = { trail = { distance = { min_cols = -5 } } },
    })
  end)
end)

it('accepts valid overrides table', function()
  assert.does_not_throw(function()
    validation.validate_config({
      cursor = { trail = { overrides = { basic_j = 'always' } } },
    })
  end)
end)

it('rejects non-table overrides', function()
  assert.throws(function()
    validation.validate_config({
      cursor = { trail = { overrides = 'invalid' } },
    })
  end)
end)
```

**Step 3: Run tests to verify they fail**

Run: `./scripts/run_tests.sh`
Expected: FAIL (defaults missing policy/distance/overrides, validation not checking them)

**Step 4: Update defaults**

Modify `lua/luxmotion/config/defaults.lua` — update both cursor.trail and scroll.trail:

```lua
local M = {}

M.config = {
  cursor = {
    duration = 150,
    easing = "ease-out",
    enabled = true,
    trail = {
      enabled = true,
      color = "auto",
      segments = 10,
      policy = "distance",
      distance = {
        min_lines = 2,
        min_cols = 5,
      },
      overrides = {},
    },
  },
  scroll = {
    duration = 200,
    easing = "ease-in-out",
    enabled = true,
    trail = {
      enabled = false,
      color = "auto",
      segments = 10,
      policy = "always",
      distance = {
        min_lines = 2,
        min_cols = 5,
      },
      overrides = {},
    },
  },
  keymaps = {
    cursor = true,
    scroll = true,
  },
  performance = {
    enabled = false,
    disable_syntax_during_scroll = true,
    ignore_events = {'WinScrolled', 'CursorMoved', 'CursorMovedI'},
    reduce_frame_rate = false,
    frame_rate_threshold = 60,
    auto_enable_on_large_files = true,
    large_file_threshold = 5000,
  },
}

return M
```

**Step 5: Update validation**

Modify the `validate_trail` function in `lua/luxmotion/config/validation.lua`. After the existing `trail.segments` check (line 33), add:

```lua
if trail.policy ~= nil then
  if type(trail.policy) ~= "string" then
    error(category_name .. ".trail.policy must be a string")
  end
end

if trail.distance ~= nil then
  if type(trail.distance) ~= "table" then
    error(category_name .. ".trail.distance must be a table")
  end
  if trail.distance.min_lines ~= nil then
    if type(trail.distance.min_lines) ~= "number" or trail.distance.min_lines < 0 then
      error(category_name .. ".trail.distance.min_lines must be a non-negative number")
    end
  end
  if trail.distance.min_cols ~= nil then
    if type(trail.distance.min_cols) ~= "number" or trail.distance.min_cols < 0 then
      error(category_name .. ".trail.distance.min_cols must be a non-negative number")
    end
  end
end

if trail.overrides ~= nil then
  if type(trail.overrides) ~= "table" then
    error(category_name .. ".trail.overrides must be a table")
  end
end
```

**Step 6: Run tests to verify they pass**

Run: `./scripts/run_tests.sh`
Expected: PASS (all tests)

**Step 7: Commit**

```bash
git add lua/luxmotion/config/defaults.lua lua/luxmotion/config/validation.lua tests/unit/config/defaults_spec.lua tests/unit/config/validation_spec.lua
git commit -m "feat(trail): add policy config defaults and validation"
```

---

## Task 6: Motion Registration with trail_policy

**Files:**
- Modify: `lua/luxmotion/registry/motions.lua` (store `trail_policy` field)
- Modify: `lua/luxmotion/registry/builtin.lua` (add `trail_policy` to each motion)
- Modify: `tests/unit/registry/motions_spec.lua` (test trail_policy storage)
- Modify: `tests/unit/registry/builtin_spec.lua` (test trail_policy assignments)

**Step 1: Write failing test for motions registry**

Add to `tests/unit/registry/motions_spec.lua`:

```lua
it('register stores trail_policy', function()
  motions.register({
    id = 'with_policy',
    keys = { 'j' },
    modes = { 'n' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = function() return {} end,
    trail_policy = 'distance',
  })

  local motion = motions.get('with_policy')
  assert.equals(motion.trail_policy, 'distance')
end)

it('register defaults trail_policy to nil', function()
  motions.register({
    id = 'no_policy',
    keys = { 'j' },
    modes = { 'n' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = function() return {} end,
  })

  local motion = motions.get('no_policy')
  assert.is_nil(motion.trail_policy)
end)
```

**Step 2: Write failing tests for builtin trail_policy assignments**

Add to `tests/unit/registry/builtin_spec.lua`:

```lua
it('basic motions have distance trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'basic_h', 'basic_j', 'basic_k', 'basic_l' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'distance', id .. ' should have distance policy')
  end
end)

it('screen motions have distance trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'screen_gj', 'screen_gk' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'distance', id .. ' should have distance policy')
  end
end)

it('word motions have always trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'word_w', 'word_b', 'word_e', 'word_W', 'word_B', 'word_E' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
  end
end)

it('find motions have always trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'find_f', 'find_F', 'find_t', 'find_T' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
  end
end)

it('line position motions have always trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'basic_0', 'basic_$', 'line_gg', 'line_G', 'line_|' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
  end
end)

it('text object motions have always trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'text_object_{', 'text_object_}', 'text_object_(', 'text_object_)', 'text_object_%' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
  end
end)

it('search motions have always trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'search_n', 'search_N' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
  end
end)

it('scroll motions have always trail_policy', function()
  builtin.register_motions()
  for _, id in ipairs({ 'scroll_ctrl_d', 'scroll_ctrl_u', 'scroll_ctrl_f', 'scroll_ctrl_b', 'position_zz', 'position_zt', 'position_zb' }) do
    local motion = motions.get(id)
    assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
  end
end)
```

**Step 3: Run tests to verify they fail**

Run: `./scripts/run_tests.sh`
Expected: FAIL (trail_policy not stored/assigned)

**Step 4: Update motions.lua to store trail_policy**

In `lua/luxmotion/registry/motions.lua`, add `trail_policy` to the motion object in the `register` function (after `input = definition.input` on line 15):

Add: `trail_policy = definition.trail_policy,`

**Step 5: Update builtin.lua to assign trail_policy to each motion**

In `lua/luxmotion/registry/builtin.lua`, update each `motions.register` call:

- **h, j, k, l** (lines 88-99): Add `trail_policy = "distance"`
- **0, $** (lines 101-119): Add `trail_policy = "always"`
- **w, b, e, W, B, E** (lines 121-132): Add `trail_policy = "always"`
- **f, F, t, T** (lines 134-145): Add `trail_policy = "always"`
- **{, }, (, ), %** (lines 154-165): Add `trail_policy = "always"`
- **gg, G** (lines 167-187): Add `trail_policy = "always"`
- **|** (lines 189-198): Add `trail_policy = "always"`
- **n, N** (lines 200-220): Add `trail_policy = "always"`
- **gj, gk** (lines 222-242): Add `trail_policy = "distance"`
- **Ctrl-d/u/f/b** (lines 244-286): Add `trail_policy = "always"`
- **zz, zt, zb** (lines 288-316): Add `trail_policy = "always"`

**Step 6: Run tests to verify they pass**

Run: `./scripts/run_tests.sh`
Expected: PASS (all tests)

**Step 7: Commit**

```bash
git add lua/luxmotion/registry/motions.lua lua/luxmotion/registry/builtin.lua tests/unit/registry/motions_spec.lua tests/unit/registry/builtin_spec.lua
git commit -m "feat(trail): assign trail_policy to all motion registrations"
```

---

## Task 7: Traits Signature Change (invoke_start passes result)

**Files:**
- Modify: `lua/luxmotion/registry/traits.lua` (update `invoke_start` signature)
- Modify: `lua/luxmotion/engine/orchestrator.lua` (pass result to `invoke_start`, attach `motion_id` to context)
- Modify: `tests/unit/registry/traits_spec.lua` (update invoke_start tests)
- Modify: `tests/unit/engine/orchestrator_spec.lua` (test motion_id on context)

**Step 1: Write failing tests for traits invoke_start with result**

Update existing tests and add new ones in `tests/unit/registry/traits_spec.lua`:

Update test `'invoke_start passes context to on_start'` to also verify result is passed:

```lua
it('invoke_start passes context and result to on_start', function()
  local received_ctx = nil
  local received_result = nil
  traits.register({
    id = 'test_ctx',
    apply = function() end,
    on_start = function(ctx, res) received_ctx = ctx; received_result = res end,
  })

  local context = { cursor = { line = 5 } }
  local result = { cursor = { line = 10 } }
  traits.invoke_start('test_ctx', context, result)
  assert.equals(received_ctx, context)
  assert.equals(received_result, result)
end)
```

Add test for orchestrator `motion_id` on context in `tests/unit/engine/orchestrator_spec.lua`:

```lua
it('execute sets motion_id on context', function()
  local config = require('luxmotion.config')
  config.update({ cursor = { enabled = true } })

  local received_motion_id = nil
  traits.clear()
  traits.register({
    id = 'cursor',
    apply = function(context, result, progress)
      received_motion_id = context.motion_id
      if result.cursor then
        context:set_cursor(result.cursor.line, result.cursor.col)
      end
    end,
  })

  motions.clear()
  motions.register({
    id = 'test_j',
    keys = { 'j' },
    modes = { 'n' },
    traits = { 'cursor' },
    category = 'cursor',
    calculator = function(ctx)
      return { cursor = { line = ctx.cursor.line + 1, col = ctx.cursor.col } }
    end,
  })

  orchestrator.execute('test_j', { count = 1 })
  assert.equals(received_motion_id, 'test_j')
end)
```

**Step 2: Run tests to verify they fail**

Run: `./scripts/run_tests.sh`
Expected: FAIL (invoke_start doesn't pass result, context missing motion_id)

**Step 3: Update traits.lua invoke_start**

In `lua/luxmotion/registry/traits.lua`, change `invoke_start` (line 36-41):

```lua
function M.invoke_start(trait_id, context, result)
  local trait = traits[trait_id]
  if trait and trait.on_start then
    trait.on_start(context, result)
  end
end
```

**Step 4: Update orchestrator.lua**

In `lua/luxmotion/engine/orchestrator.lua`:

After line 41 (`context.category = motion.category`), add:
```lua
context.motion_id = motion.id
```

Update the `invoke_start` call (line 57) to pass result:
```lua
traits.invoke_start(trait_id, context, result)
```

**Step 5: Run tests to verify they pass**

Run: `./scripts/run_tests.sh`
Expected: PASS (all tests)

**Step 6: Commit**

```bash
git add lua/luxmotion/registry/traits.lua lua/luxmotion/engine/orchestrator.lua tests/unit/registry/traits_spec.lua tests/unit/engine/orchestrator_spec.lua
git commit -m "feat(trail): pass result to invoke_start, attach motion_id to context"
```

---

## Task 8: Trail Trait Policy Integration

**Files:**
- Modify: `lua/luxmotion/registry/builtin.lua` (update trail trait to be policy-aware, register policies)
- Modify: `tests/unit/registry/builtin_spec.lua` (test policy-aware trail trait)
- Modify: `tests/integration/trail_spec.lua` (integration test for policy filtering)

**Step 1: Write failing tests**

Add to `tests/unit/registry/builtin_spec.lua`:

```lua
it('register_traits registers built-in policies', function()
  local config = require('luxmotion.config')
  config.update({ cursor = { trail = { enabled = true } } })

  traits.clear()
  builtin.register_traits()

  local policies = require('luxmotion.trail.policies')
  assert.is_not_nil(policies.get('always'))
  assert.is_not_nil(policies.get('never'))
  assert.is_not_nil(policies.get('distance'))
end)
```

Add to `tests/integration/trail_spec.lua`:

```lua
it('trail trait suppresses trail when distance policy rejects', function()
  luxmotion.setup({
    cursor = {
      trail = {
        enabled = true,
        policy = 'distance',
        distance = { min_lines = 3, min_cols = 5 },
      },
    },
  })

  local traits = require('luxmotion.registry.traits')
  local trail_trait = traits.get('trail')
  assert.is_not_nil(trail_trait)

  local context = {
    cursor = { line = 1, col = 0 },
    motion_id = 'basic_j',
    category = 'cursor',
    bufnr = 1,
  }
  local result = { cursor = { line = 2, col = 0 } }

  trail_trait.on_start(context, result)
  assert.is_false(context.trail_active)
end)

it('trail trait activates trail when distance policy accepts', function()
  luxmotion.setup({
    cursor = {
      trail = {
        enabled = true,
        policy = 'distance',
        distance = { min_lines = 2, min_cols = 5 },
      },
    },
  })

  local traits = require('luxmotion.registry.traits')
  local trail_trait = traits.get('trail')

  local context = {
    cursor = { line = 1, col = 0 },
    motion_id = 'basic_j',
    category = 'cursor',
    bufnr = 1,
  }
  local result = { cursor = { line = 5, col = 0 } }

  trail_trait.on_start(context, result)
  assert.is_true(context.trail_active)
end)

it('trail trait always activates for always-policy motion', function()
  luxmotion.setup({
    cursor = {
      trail = {
        enabled = true,
        policy = 'distance',
        distance = { min_lines = 10, min_cols = 10 },
      },
    },
  })

  local traits = require('luxmotion.registry.traits')
  local motions = require('luxmotion.registry.motions')
  local trail_trait = traits.get('trail')

  local word_w = motions.get('word_w')
  assert.equals(word_w.trail_policy, 'always')

  local context = {
    cursor = { line = 1, col = 0 },
    motion_id = 'word_w',
    category = 'cursor',
    bufnr = 1,
  }
  local result = { cursor = { line = 1, col = 3 } }

  trail_trait.on_start(context, result)
  assert.is_true(context.trail_active)
end)

it('trail trait respects user override', function()
  luxmotion.setup({
    cursor = {
      trail = {
        enabled = true,
        overrides = { word_w = 'never' },
      },
    },
  })

  local traits = require('luxmotion.registry.traits')
  local trail_trait = traits.get('trail')

  local context = {
    cursor = { line = 1, col = 0 },
    motion_id = 'word_w',
    category = 'cursor',
    bufnr = 1,
  }
  local result = { cursor = { line = 1, col = 20 } }

  trail_trait.on_start(context, result)
  assert.is_false(context.trail_active)
end)
```

**Step 2: Run tests to verify they fail**

Run: `./scripts/run_tests.sh`
Expected: FAIL (trail trait not policy-aware, policies not registered during setup)

**Step 3: Update builtin.lua trail trait registration**

Replace the trail trait registration block in `lua/luxmotion/registry/builtin.lua` (current lines 36-59). The new `register_traits` function should:

1. Register cursor and scroll traits (unchanged)
2. Register built-in policies (always, never, distance)
3. Register the policy-aware trail trait

```lua
function M.register_traits()
  traits.register({
    id = "cursor",
    apply = function(context, result, progress)
      if result.cursor and context.set_cursor then
        context:set_cursor(result.cursor.line, result.cursor.col)
      end
    end,
  })

  traits.register({
    id = "scroll",
    apply = function(context, result, progress)
      if result.viewport and result.viewport.topline and context.restore_view then
        context:restore_view(result.viewport.topline, result.cursor.line, result.cursor.col)
      end
    end,
  })

  local cursor_config = config.get("cursor")
  local scroll_config = config.get("scroll")
  local cursor_trail = cursor_config and cursor_config.trail
  local scroll_trail = scroll_config and scroll_config.trail

  local trail_enabled = (cursor_trail and cursor_trail.enabled) or (scroll_trail and scroll_trail.enabled)

  if trail_enabled then
    local policies = require("luxmotion.trail.policies")
    local always_policy = require("luxmotion.trail.policies.always")
    local never_policy = require("luxmotion.trail.policies.never")
    local distance_policy = require("luxmotion.trail.policies.distance")

    policies.clear()
    policies.register(always_policy)
    policies.register(never_policy)

    local distance_config = (cursor_trail and cursor_trail.distance) or { min_lines = 2, min_cols = 5 }
    policies.register(distance_policy.create(distance_config))

    traits.register({
      id = "trail",
      apply = function(context, result, progress)
        if not context.trail_active then
          return
        end
        local category_config = config.get(context.category or "cursor")
        local trail = category_config and category_config.trail
        if not trail then
          return
        end
        renderer.push_position(context.bufnr, result, trail.segments)
        renderer.render(context.bufnr, trail.segments)
      end,
      on_start = function(context, result)
        local policies = require("luxmotion.trail.policies")
        local policy = policies.resolve(context.motion_id)
        context.trail_active = policy.should_trail(context, result)
        if context.trail_active then
          renderer.reset()
        end
      end,
      on_complete = function(context)
        if not context.trail_active then
          return
        end
        if context and context.bufnr then
          renderer.clear(context.bufnr)
        else
          renderer.reset()
        end
      end,
    })
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `./scripts/run_tests.sh`
Expected: PASS (all tests)

**Step 5: Commit**

```bash
git add lua/luxmotion/registry/builtin.lua tests/unit/registry/builtin_spec.lua tests/integration/trail_spec.lua
git commit -m "feat(trail): integrate policy system into trail trait"
```

---

## Task 9: Register Test Files in Test Runner

**Files:**
- Modify: `tests/init.lua` (add new test spec requires)

**Step 1: Add new test file requires**

In `tests/init.lua`, add the new policy test files. Insert after the trail specs (after line 42 `require('tests.unit.trail.renderer_spec')`):

```lua
require('tests.unit.trail.policies.always_spec')
require('tests.unit.trail.policies.never_spec')
require('tests.unit.trail.policies.distance_spec')
require('tests.unit.trail.policies.registry_spec')
```

**NOTE:** This task should actually be done FIRST before Task 1, or the new test files won't be picked up by the runner. However, since the tests are required by the runner at init time and the files won't exist yet, the runner will fail. **The correct approach is to add each require as part of the task that creates the corresponding test file.**

**Revised approach:** Add the require statements incrementally:
- Task 1 step 1: add `require('tests.unit.trail.policies.always_spec')` to `tests/init.lua`
- Task 2 step 1: add `require('tests.unit.trail.policies.never_spec')` to `tests/init.lua`
- Task 3 step 1: add `require('tests.unit.trail.policies.distance_spec')` to `tests/init.lua`
- Task 4 step 1: add `require('tests.unit.trail.policies.registry_spec')` to `tests/init.lua`

Each task's "write failing test" step must include adding the require to `tests/init.lua`.

**Step 1: Verify all tests pass with all requires added**

Run: `./scripts/run_tests.sh`
Expected: PASS (all tests including all new policy tests)

**Step 2: Commit** (if not already committed as part of prior tasks)

```bash
git add tests/init.lua
git commit -m "test(trail): register policy test files in test runner"
```

---

## Task 10: Final Verification & Cleanup

**Step 1: Run full test suite**

Run: `./scripts/run_tests.sh`
Expected: ALL PASS

**Step 2: Verify backwards compatibility**

The test `'trail trait always activates for always-policy motion'` with `word_w` proves that motions with `trail_policy = "always"` still trail regardless of distance config. The existing integration tests in `trail_spec.lua` should still pass unchanged, confirming zero regression.

**Step 3: Commit any final fixes**

Only if needed.

---

## Execution Order & Dependencies

```
Task 1 (always policy)     ─┐
Task 2 (never policy)      ─┤─ Independent, can run in parallel
Task 3 (distance policy)   ─┘
         │
Task 4 (registry) ──────────── Depends on Tasks 1-3 (imports them)
         │
Task 5 (config) ─────────────── Independent of Tasks 1-4
         │
Task 6 (motion registration) ── Independent of Tasks 1-4, depends on Task 5 for defaults
         │
Task 7 (traits signature) ───── Independent of Tasks 1-6
         │
Task 8 (integration) ────────── Depends on ALL prior tasks
         │
Task 9 (test runner) ────────── Woven into Tasks 1-4 (each task adds its own require)
         │
Task 10 (verification) ──────── Final, depends on ALL
```

**Parallel batches:**
- **Batch 1:** Tasks 1, 2, 3 (independent policy files)
- **Batch 2:** Tasks 4, 5, 6, 7 (registry, config, motions, traits — mostly independent)
- **Batch 3:** Task 8 (integration — depends on everything)
- **Batch 4:** Task 10 (verification)
