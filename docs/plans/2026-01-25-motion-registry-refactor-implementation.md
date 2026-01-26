# Motion Registry Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor nvim-luxmotion from scattered cursor/scroll modules into a unified Motion Registry pattern with composable traits.

**Architecture:** Two registries (traits and motions) feed into a central orchestrator that coordinates animations. Calculators are pure functions with standardized signatures. Keymaps are auto-generated from motion definitions.

**Tech Stack:** Pure Lua, Neovim 0.7+ APIs, no external dependencies.

---

## Phase 1: Foundation (Registry Infrastructure)

### Task 1: Create Trait Registry

**Files:**
- Create: `lua/luxmotion/registry/traits.lua`

**Step 1: Create the registry directory**

```bash
mkdir -p lua/luxmotion/registry
```

**Step 2: Write the trait registry module**

```lua
-- lua/luxmotion/registry/traits.lua
local M = {}

local traits = {}
local state = {}

function M.register(definition)
  local id = definition.id
  traits[id] = {
    id = id,
    apply = definition.apply,
    on_start = definition.on_start,
    on_complete = definition.on_complete,
  }
  state[id] = false
end

function M.is_animating(trait_id)
  return state[trait_id] == true
end

function M.set_animating(trait_id, value)
  state[trait_id] = value
end

function M.get(trait_id)
  return traits[trait_id]
end

function M.apply_frame(trait_id, context, result, progress)
  local trait = traits[trait_id]
  if trait and trait.apply then
    trait.apply(context, result, progress)
  end
end

function M.all()
  return traits
end

function M.reset()
  for id, _ in pairs(state) do
    state[id] = false
  end
end

function M.clear()
  traits = {}
  state = {}
end

return M
```

**Step 3: Verify module loads without errors**

Open Neovim in the worktree directory and run:
```vim
:lua print(vim.inspect(require("luxmotion.registry.traits")))
```
Expected: Table with register, is_animating, set_animating, get, apply_frame, all, reset, clear functions.

**Step 4: Commit**

```bash
git add lua/luxmotion/registry/traits.lua
git commit -m "feat: add trait registry for animation capabilities"
```

---

### Task 2: Create Motion Registry

**Files:**
- Create: `lua/luxmotion/registry/motions.lua`

**Step 1: Write the motion registry module**

```lua
-- lua/luxmotion/registry/motions.lua
local M = {}

local motions = {}
local categories = {}

function M.register(definition)
  local motion = {
    id = definition.id,
    keys = definition.keys,
    modes = definition.modes or { "n", "v" },
    traits = definition.traits,
    category = definition.category,
    calculator = definition.calculator,
    description = definition.description,
    input = definition.input,
  }

  motions[motion.id] = motion

  categories[motion.category] = categories[motion.category] or {}
  table.insert(categories[motion.category], motion.id)
end

function M.get(motion_id)
  return motions[motion_id]
end

function M.get_by_category(category)
  local ids = categories[category] or {}
  local result = {}
  for _, id in ipairs(ids) do
    table.insert(result, motions[id])
  end
  return result
end

function M.all()
  return motions
end

function M.clear()
  motions = {}
  categories = {}
end

return M
```

**Step 2: Verify module loads without errors**

```vim
:lua print(vim.inspect(require("luxmotion.registry.motions")))
```
Expected: Table with register, get, get_by_category, all, clear functions.

**Step 3: Commit**

```bash
git add lua/luxmotion/registry/motions.lua
git commit -m "feat: add motion registry for motion definitions"
```

---

### Task 3: Create Context Builder

**Files:**
- Create: `lua/luxmotion/context/builder.lua`

**Step 1: Create the context directory**

```bash
mkdir -p lua/luxmotion/context
```

**Step 2: Write the context builder module**

```lua
-- lua/luxmotion/context/builder.lua
local viewport = require("luxmotion.core.viewport")

local M = {}

function M.build(input)
  local cursor_pos = viewport.get_cursor_position()
  local win_height = viewport.get_height()
  local win_width = viewport.get_width()
  local topline = viewport.get_topline()
  local line_count = viewport.get_line_count()

  return {
    cursor = {
      line = cursor_pos[1],
      col = cursor_pos[2],
    },
    viewport = {
      topline = topline,
      height = win_height,
      width = win_width,
    },
    buffer = {
      line_count = line_count,
    },
    input = {
      char = input.char,
      count = input.count or 1,
      direction = input.direction,
    },
  }
end

return M
```

**Step 3: Verify module loads and builds context**

```vim
:lua print(vim.inspect(require("luxmotion.context.builder").build({ count = 1, direction = "j" })))
```
Expected: Table with cursor, viewport, buffer, input sub-tables populated with current state.

**Step 4: Commit**

```bash
git add lua/luxmotion/context/builder.lua
git commit -m "feat: add context builder for standardized calculator input"
```

---

## Phase 2: Engine (Animation Coordination)

### Task 4: Create Engine Pool Module

**Files:**
- Create: `lua/luxmotion/engine/pool.lua`

**Step 1: Create the engine directory**

```bash
mkdir -p lua/luxmotion/engine
```

**Step 2: Write the pool module (extract from core/animation.lua)**

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

**Step 3: Verify module loads**

```vim
:lua local p = require("luxmotion.engine.pool"); local a = p.acquire(); print(vim.inspect(a)); p.release(a); print(vim.inspect(p.get_stats()))
```
Expected: Animation object acquired and released, stats show pool_size = 1.

**Step 4: Commit**

```bash
git add lua/luxmotion/engine/pool.lua
git commit -m "feat: add animation object pool for memory efficiency"
```

---

### Task 5: Create Engine Loop Module

**Files:**
- Create: `lua/luxmotion/engine/loop.lua`

**Step 1: Write the loop module**

```lua
-- lua/luxmotion/engine/loop.lua
local traits = require("luxmotion.registry.traits")
local pool = require("luxmotion.engine.pool")
local performance = require("luxmotion.performance")

local M = {}

local frame_queue = {}
local is_running = false

local easing_functions = {
  linear = function(t) return t end,
  ["ease-in"] = function(t) return t * t end,
  ["ease-out"] = function(t) return 1 - (1 - t) * (1 - t) end,
  ["ease-in-out"] = function(t)
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

function M.get_active_count()
  return #frame_queue
end

function M.is_running()
  return is_running
end

return M
```

**Step 2: Verify module loads**

```vim
:lua print(vim.inspect(require("luxmotion.engine.loop")))
```
Expected: Table with get_easing, start, stop_all, get_active_count, is_running functions.

**Step 3: Commit**

```bash
git add lua/luxmotion/engine/loop.lua
git commit -m "feat: add animation loop with trait-based frame processing"
```

---

### Task 6: Create Orchestrator Module

**Files:**
- Create: `lua/luxmotion/engine/orchestrator.lua`

**Step 1: Write the orchestrator module**

```lua
-- lua/luxmotion/engine/orchestrator.lua
local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local context_builder = require("luxmotion.context.builder")
local loop = require("luxmotion.engine.loop")
local config = require("luxmotion.config")

local M = {}

local function is_same_position(context, result)
  if not result.cursor then
    return false
  end
  return context.cursor.line == result.cursor.line and context.cursor.col == result.cursor.col
end

function M.execute(motion_id, input)
  local motion = motions.get(motion_id)
  if not motion then
    return
  end

  local category_config = config.get(motion.category)
  if not category_config or not category_config.enabled then
    M.fallback(motion, input)
    return
  end

  for _, trait_id in ipairs(motion.traits) do
    if traits.is_animating(trait_id) then
      return
    end
  end

  local context = context_builder.build(input)
  local result = motion.calculator(context)

  if not result then
    return
  end

  if is_same_position(context, result) then
    return
  end

  for _, trait_id in ipairs(motion.traits) do
    traits.set_animating(trait_id, true)
  end

  loop.start({
    context = context,
    result = result,
    traits = motion.traits,
    duration = category_config.duration,
    easing = category_config.easing,
    on_complete = function()
      for _, trait_id in ipairs(motion.traits) do
        traits.set_animating(trait_id, false)
      end
    end,
  })
end

function M.fallback(motion, input)
  local cmd = ""
  if input.count and input.count > 1 then
    cmd = tostring(input.count)
  end
  cmd = cmd .. (input.direction or motion.keys[1])
  if input.char then
    cmd = cmd .. input.char
  end
  vim.cmd("normal! " .. cmd)
end

return M
```

**Step 2: Verify module loads**

```vim
:lua print(vim.inspect(require("luxmotion.engine.orchestrator")))
```
Expected: Table with execute and fallback functions.

**Step 3: Commit**

```bash
git add lua/luxmotion/engine/orchestrator.lua
git commit -m "feat: add orchestrator for motion coordination"
```

---

## Phase 3: Calculators (Target Position Logic)

### Task 7: Create Calculator Index Module

**Files:**
- Create: `lua/luxmotion/calculators/init.lua`

**Step 1: Create the calculators directory**

```bash
mkdir -p lua/luxmotion/calculators
```

**Step 2: Write the calculator index**

```lua
-- lua/luxmotion/calculators/init.lua
local M = {}

M.basic = require("luxmotion.calculators.basic")
M.word = require("luxmotion.calculators.word")
M.find = require("luxmotion.calculators.find")
M.text_object = require("luxmotion.calculators.text_object")
M.line = require("luxmotion.calculators.line")
M.search = require("luxmotion.calculators.search")
M.scroll = require("luxmotion.calculators.scroll")

return M
```

**Step 3: Do not verify yet (dependencies not created)**

Continue to next task.

**Step 4: Commit placeholder**

```bash
git add lua/luxmotion/calculators/init.lua
git commit -m "feat: add calculator index module (dependencies pending)"
```

---

### Task 8: Create Basic Calculator (h/j/k/l/0/$)

**Files:**
- Create: `lua/luxmotion/calculators/basic.lua`

**Step 1: Write the basic calculator**

```lua
-- lua/luxmotion/calculators/basic.lua
local viewport = require("luxmotion.core.viewport")

local M = {}

function M.h(context)
  local target_col = math.max(context.cursor.col - context.input.count, 0)
  return {
    cursor = { line = context.cursor.line, col = target_col },
  }
end

function M.j(context)
  local target_line = math.min(context.cursor.line + context.input.count, context.buffer.line_count)
  return {
    cursor = { line = target_line, col = context.cursor.col },
  }
end

function M.k(context)
  local target_line = math.max(context.cursor.line - context.input.count, 1)
  return {
    cursor = { line = target_line, col = context.cursor.col },
  }
end

function M.l(context)
  local line_length = viewport.get_line_length(context.cursor.line)
  local target_col = math.min(context.cursor.col + context.input.count, math.max(line_length - 1, 0))
  return {
    cursor = { line = context.cursor.line, col = target_col },
  }
end

M["0"] = function(context)
  return {
    cursor = { line = context.cursor.line, col = 0 },
  }
end

M["$"] = function(context)
  local line_length = viewport.get_line_length(context.cursor.line)
  return {
    cursor = { line = context.cursor.line, col = math.max(line_length - 1, 0) },
  }
end

return M
```

**Step 2: Verify basic calculations**

```vim
:lua local b = require("luxmotion.calculators.basic"); local ctx = { cursor = { line = 5, col = 10 }, buffer = { line_count = 100 }, input = { count = 3 } }; print(vim.inspect(b.j(ctx)))
```
Expected: `{ cursor = { col = 10, line = 8 } }`

**Step 3: Commit**

```bash
git add lua/luxmotion/calculators/basic.lua
git commit -m "feat: add basic calculator for h/j/k/l/0/$ motions"
```

---

### Task 9: Create Word Calculator (w/b/e/W/B/E)

**Files:**
- Create: `lua/luxmotion/calculators/word.lua`

**Step 1: Write the word calculator**

```lua
-- lua/luxmotion/calculators/word.lua
local M = {}

local function calculate_via_native(motion_cmd, context)
  local original = { context.cursor.line, context.cursor.col }
  vim.api.nvim_win_set_cursor(0, original)

  local cmd = context.input.count .. motion_cmd
  local success = pcall(vim.cmd, "normal! " .. cmd)

  if not success then
    vim.api.nvim_win_set_cursor(0, original)
    return {
      cursor = { line = context.cursor.line, col = context.cursor.col },
    }
  end

  local target = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, original)

  return {
    cursor = { line = target[1], col = target[2] },
  }
end

function M.w(context)
  return calculate_via_native("w", context)
end

function M.b(context)
  return calculate_via_native("b", context)
end

function M.e(context)
  return calculate_via_native("e", context)
end

function M.W(context)
  return calculate_via_native("W", context)
end

function M.B(context)
  return calculate_via_native("B", context)
end

function M.E(context)
  return calculate_via_native("E", context)
end

return M
```

**Step 2: Verify word calculations**

```vim
:lua local w = require("luxmotion.calculators.word"); local ctx = require("luxmotion.context.builder").build({ count = 1, direction = "w" }); print(vim.inspect(w.w(ctx)))
```
Expected: Target position for next word.

**Step 3: Commit**

```bash
git add lua/luxmotion/calculators/word.lua
git commit -m "feat: add word calculator for w/b/e/W/B/E motions"
```

---

### Task 10: Create Find Calculator (f/F/t/T)

**Files:**
- Create: `lua/luxmotion/calculators/find.lua`

**Step 1: Write the find calculator**

```lua
-- lua/luxmotion/calculators/find.lua
local M = {}

local function calculate_via_native(motion_cmd, context)
  local original = { context.cursor.line, context.cursor.col }
  vim.api.nvim_win_set_cursor(0, original)

  local cmd = context.input.count .. motion_cmd .. context.input.char
  local success = pcall(vim.cmd, "normal! " .. cmd)

  if not success then
    vim.api.nvim_win_set_cursor(0, original)
    return {
      cursor = { line = context.cursor.line, col = context.cursor.col },
    }
  end

  local target = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, original)

  return {
    cursor = { line = target[1], col = target[2] },
  }
end

function M.f(context)
  return calculate_via_native("f", context)
end

function M.F(context)
  return calculate_via_native("F", context)
end

function M.t(context)
  return calculate_via_native("t", context)
end

function M.T(context)
  return calculate_via_native("T", context)
end

return M
```

**Step 2: Commit**

```bash
git add lua/luxmotion/calculators/find.lua
git commit -m "feat: add find calculator for f/F/t/T motions"
```

---

### Task 11: Create Text Object Calculator ({/}/()/%)

**Files:**
- Create: `lua/luxmotion/calculators/text_object.lua`

**Step 1: Write the text object calculator**

```lua
-- lua/luxmotion/calculators/text_object.lua
local M = {}

local function calculate_via_native(motion_cmd, context)
  local original = { context.cursor.line, context.cursor.col }
  vim.api.nvim_win_set_cursor(0, original)

  local cmd = context.input.count .. motion_cmd
  local success = pcall(vim.cmd, "normal! " .. cmd)

  if not success then
    vim.api.nvim_win_set_cursor(0, original)
    return {
      cursor = { line = context.cursor.line, col = context.cursor.col },
    }
  end

  local target = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, original)

  return {
    cursor = { line = target[1], col = target[2] },
  }
end

M["{"] = function(context)
  return calculate_via_native("{", context)
end

M["}"] = function(context)
  return calculate_via_native("}", context)
end

M["("] = function(context)
  return calculate_via_native("(", context)
end

M[")"] = function(context)
  return calculate_via_native(")", context)
end

M["%"] = function(context)
  return calculate_via_native("%", context)
end

return M
```

**Step 2: Commit**

```bash
git add lua/luxmotion/calculators/text_object.lua
git commit -m "feat: add text object calculator for {/}/()/% motions"
```

---

### Task 12: Create Line Calculator (gg/G/|)

**Files:**
- Create: `lua/luxmotion/calculators/line.lua`

**Step 1: Write the line calculator**

```lua
-- lua/luxmotion/calculators/line.lua
local viewport = require("luxmotion.core.viewport")

local M = {}

local function get_first_non_blank(line_num)
  local line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""
  local leading_space = line_content:match("^%s*")
  return leading_space and #leading_space or 0
end

local function calculate_topline(target_line, context)
  local win_height = context.viewport.height
  local topline = target_line - math.floor(win_height / 2)
  return math.max(1, math.min(topline, context.buffer.line_count - win_height + 1))
end

function M.gg(context)
  local target_line = context.input.count
  target_line = math.max(1, math.min(target_line, context.buffer.line_count))
  local target_col = get_first_non_blank(target_line)

  return {
    cursor = { line = target_line, col = target_col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.G(context)
  local target_line
  if vim.v.count == 0 then
    target_line = context.buffer.line_count
  else
    target_line = math.max(1, math.min(context.input.count, context.buffer.line_count))
  end
  local target_col = get_first_non_blank(target_line)

  return {
    cursor = { line = target_line, col = target_col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

M["|"] = function(context)
  local target_col = math.max(context.input.count - 1, 0)
  return {
    cursor = { line = context.cursor.line, col = target_col },
  }
end

return M
```

**Step 2: Commit**

```bash
git add lua/luxmotion/calculators/line.lua
git commit -m "feat: add line calculator for gg/G/| motions"
```

---

### Task 13: Create Search Calculator (n/N)

**Files:**
- Create: `lua/luxmotion/calculators/search.lua`

**Step 1: Write the search calculator**

```lua
-- lua/luxmotion/calculators/search.lua
local M = {}

local function calculate_via_native(motion_cmd, context)
  local original = { context.cursor.line, context.cursor.col }
  vim.api.nvim_win_set_cursor(0, original)

  local cmd = context.input.count .. motion_cmd
  local success = pcall(vim.cmd, "normal! " .. cmd)

  if not success then
    vim.api.nvim_win_set_cursor(0, original)
    return {
      cursor = { line = context.cursor.line, col = context.cursor.col },
    }
  end

  local target = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, original)

  return {
    cursor = { line = target[1], col = target[2] },
  }
end

function M.n(context)
  return calculate_via_native("n", context)
end

function M.N(context)
  return calculate_via_native("N", context)
end

function M.gj(context)
  return calculate_via_native("gj", context)
end

function M.gk(context)
  return calculate_via_native("gk", context)
end

return M
```

**Step 2: Commit**

```bash
git add lua/luxmotion/calculators/search.lua
git commit -m "feat: add search calculator for n/N/gj/gk motions"
```

---

### Task 14: Create Scroll Calculator (C-d/C-u/C-f/C-b/zz/zt/zb)

**Files:**
- Create: `lua/luxmotion/calculators/scroll.lua`

**Step 1: Write the scroll calculator**

```lua
-- lua/luxmotion/calculators/scroll.lua
local viewport = require("luxmotion.core.viewport")

local M = {}

local function calculate_topline(target_line, context)
  local win_height = context.viewport.height
  local topline = target_line - math.floor(win_height / 2)
  return math.max(1, math.min(topline, context.buffer.line_count - win_height + 1))
end

function M.ctrl_d(context)
  local scroll_amount = math.floor(context.viewport.height / 2) * context.input.count
  local target_line = math.min(context.cursor.line + scroll_amount, context.buffer.line_count)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.ctrl_u(context)
  local scroll_amount = math.floor(context.viewport.height / 2) * context.input.count
  local target_line = math.max(context.cursor.line - scroll_amount, 1)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.ctrl_f(context)
  local scroll_amount = (context.viewport.height - 2) * context.input.count
  local target_line = math.min(context.cursor.line + scroll_amount, context.buffer.line_count)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.ctrl_b(context)
  local scroll_amount = (context.viewport.height - 2) * context.input.count
  local target_line = math.max(context.cursor.line - scroll_amount, 1)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.zz(context)
  local win_height = context.viewport.height
  local target_topline = context.cursor.line - math.floor(win_height / 2)
  target_topline = math.max(1, math.min(target_topline, context.buffer.line_count - win_height + 1))

  return {
    cursor = { line = context.cursor.line, col = context.cursor.col },
    viewport = { topline = target_topline },
  }
end

function M.zt(context)
  local target_topline = context.cursor.line

  return {
    cursor = { line = context.cursor.line, col = context.cursor.col },
    viewport = { topline = target_topline },
  }
end

function M.zb(context)
  local win_height = context.viewport.height
  local target_topline = context.cursor.line - win_height + 1
  target_topline = math.max(1, target_topline)

  return {
    cursor = { line = context.cursor.line, col = context.cursor.col },
    viewport = { topline = target_topline },
  }
end

return M
```

**Step 2: Commit**

```bash
git add lua/luxmotion/calculators/scroll.lua
git commit -m "feat: add scroll calculator for C-d/C-u/C-f/C-b/zz/zt/zb motions"
```

---

### Task 15: Verify All Calculators Load

**Files:**
- Verify: `lua/luxmotion/calculators/init.lua`

**Step 1: Test calculator index loads all modules**

```vim
:lua local c = require("luxmotion.calculators"); print(vim.inspect(vim.tbl_keys(c)))
```
Expected: `{ "basic", "find", "line", "scroll", "search", "text_object", "word" }`

**Step 2: Commit updated index if needed (no changes expected)**

If all calculators load, no commit needed.

---

## Phase 4: Keymap Generation

### Task 16: Create Keymap Generator Module

**Files:**
- Create: `lua/luxmotion/registry/keymaps.lua`

**Step 1: Write the keymap generator**

```lua
-- lua/luxmotion/registry/keymaps.lua
local motions = require("luxmotion.registry.motions")
local orchestrator = require("luxmotion.engine.orchestrator")
local config = require("luxmotion.config")

local M = {}

function M.create_handler(motion)
  if motion.input == "char" then
    return function()
      local char = vim.fn.getcharstr()
      orchestrator.execute(motion.id, {
        char = char,
        count = vim.v.count1,
        direction = motion.keys[1],
      })
    end
  else
    return function()
      orchestrator.execute(motion.id, {
        count = vim.v.count1,
        direction = motion.keys[1],
      })
    end
  end
end

function M.setup()
  local keymap_config = config.get_keymaps()

  for motion_id, motion in pairs(motions.all()) do
    if keymap_config[motion.category] == false then
      goto continue
    end

    local handler = M.create_handler(motion)

    for _, key in ipairs(motion.keys) do
      for _, mode in ipairs(motion.modes) do
        vim.keymap.set(mode, key, handler, {
          desc = "Smooth " .. motion.description,
          silent = true,
        })
      end
    end

    ::continue::
  end
end

function M.clear()
  for _, motion in pairs(motions.all()) do
    for _, key in ipairs(motion.keys) do
      for _, mode in ipairs(motion.modes) do
        pcall(vim.keymap.del, mode, key)
      end
    end
  end
end

return M
```

**Step 2: Commit**

```bash
git add lua/luxmotion/registry/keymaps.lua
git commit -m "feat: add keymap generator for auto-generating motion keymaps"
```

---

## Phase 5: Integration (Wire Everything Together)

### Task 17: Create Motion Registration Module

**Files:**
- Create: `lua/luxmotion/registry/builtin.lua`

**Step 1: Write the builtin motion registrations**

```lua
-- lua/luxmotion/registry/builtin.lua
local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local calculators = require("luxmotion.calculators")
local viewport = require("luxmotion.core.viewport")

local M = {}

function M.register_traits()
  traits.register({
    id = "cursor",
    apply = function(context, result, progress)
      if result.cursor then
        viewport.set_cursor_position(result.cursor.line, result.cursor.col)
      end
    end,
  })

  traits.register({
    id = "scroll",
    apply = function(context, result, progress)
      if result.viewport and result.viewport.topline then
        viewport.restore_view(result.viewport.topline, result.cursor.line, result.cursor.col)
      end
    end,
  })
end

function M.register_motions()
  -- Basic cursor motions (h/j/k/l/0/$)
  for _, dir in ipairs({ "h", "j", "k", "l" }) do
    motions.register({
      id = "basic_" .. dir,
      keys = { dir },
      modes = { "n", "v" },
      traits = { "cursor" },
      category = "cursor",
      calculator = calculators.basic[dir],
      description = "move " .. dir,
      input = "count",
    })
  end

  motions.register({
    id = "basic_0",
    keys = { "0" },
    modes = { "n", "v" },
    traits = { "cursor" },
    category = "cursor",
    calculator = calculators.basic["0"],
    description = "move to line start",
  })

  motions.register({
    id = "basic_$",
    keys = { "$" },
    modes = { "n", "v" },
    traits = { "cursor" },
    category = "cursor",
    calculator = calculators.basic["$"],
    description = "move to line end",
  })

  -- Word motions (w/b/e/W/B/E)
  for _, dir in ipairs({ "w", "b", "e", "W", "B", "E" }) do
    motions.register({
      id = "word_" .. dir,
      keys = { dir },
      modes = { "n", "v" },
      traits = { "cursor" },
      category = "cursor",
      calculator = calculators.word[dir],
      description = "word " .. dir,
      input = "count",
    })
  end

  -- Find motions (f/F/t/T)
  for _, dir in ipairs({ "f", "F", "t", "T" }) do
    motions.register({
      id = "find_" .. dir,
      keys = { dir },
      modes = { "n", "v" },
      traits = { "cursor" },
      category = "cursor",
      calculator = calculators.find[dir],
      description = "find " .. dir,
      input = "char",
    })
  end

  -- Text object motions ({/}/()/%)
  local text_objects = {
    ["{"] = "paragraph backward",
    ["}"] = "paragraph forward",
    ["("] = "sentence backward",
    [")"] = "sentence forward",
    ["%"] = "matching bracket",
  }
  for key, desc in pairs(text_objects) do
    motions.register({
      id = "text_object_" .. key,
      keys = { key },
      modes = { "n", "v" },
      traits = { "cursor" },
      category = "cursor",
      calculator = calculators.text_object[key],
      description = desc,
      input = "count",
    })
  end

  -- Line motions (gg/G/|)
  motions.register({
    id = "line_gg",
    keys = { "gg" },
    modes = { "n", "v" },
    traits = { "cursor", "scroll" },
    category = "cursor",
    calculator = calculators.line.gg,
    description = "goto first line",
    input = "count",
  })

  motions.register({
    id = "line_G",
    keys = { "G" },
    modes = { "n", "v" },
    traits = { "cursor", "scroll" },
    category = "cursor",
    calculator = calculators.line.G,
    description = "goto last line",
    input = "count",
  })

  motions.register({
    id = "line_|",
    keys = { "|" },
    modes = { "n", "v" },
    traits = { "cursor" },
    category = "cursor",
    calculator = calculators.line["|"],
    description = "goto column",
    input = "count",
  })

  -- Search motions (n/N)
  motions.register({
    id = "search_n",
    keys = { "n" },
    modes = { "n", "v" },
    traits = { "cursor" },
    category = "cursor",
    calculator = calculators.search.n,
    description = "next search result",
    input = "count",
  })

  motions.register({
    id = "search_N",
    keys = { "N" },
    modes = { "n", "v" },
    traits = { "cursor" },
    category = "cursor",
    calculator = calculators.search.N,
    description = "previous search result",
    input = "count",
  })

  -- Screen line motions (gj/gk)
  motions.register({
    id = "screen_gj",
    keys = { "gj" },
    modes = { "n", "v" },
    traits = { "cursor" },
    category = "cursor",
    calculator = calculators.search.gj,
    description = "down screen line",
    input = "count",
  })

  motions.register({
    id = "screen_gk",
    keys = { "gk" },
    modes = { "n", "v" },
    traits = { "cursor" },
    category = "cursor",
    calculator = calculators.search.gk,
    description = "up screen line",
    input = "count",
  })

  -- Scroll motions (C-d/C-u/C-f/C-b)
  motions.register({
    id = "scroll_ctrl_d",
    keys = { "<C-d>" },
    modes = { "n", "v" },
    traits = { "cursor", "scroll" },
    category = "scroll",
    calculator = calculators.scroll.ctrl_d,
    description = "scroll down half-page",
    input = "count",
  })

  motions.register({
    id = "scroll_ctrl_u",
    keys = { "<C-u>" },
    modes = { "n", "v" },
    traits = { "cursor", "scroll" },
    category = "scroll",
    calculator = calculators.scroll.ctrl_u,
    description = "scroll up half-page",
    input = "count",
  })

  motions.register({
    id = "scroll_ctrl_f",
    keys = { "<C-f>" },
    modes = { "n", "v" },
    traits = { "cursor", "scroll" },
    category = "scroll",
    calculator = calculators.scroll.ctrl_f,
    description = "scroll down full-page",
    input = "count",
  })

  motions.register({
    id = "scroll_ctrl_b",
    keys = { "<C-b>" },
    modes = { "n", "v" },
    traits = { "cursor", "scroll" },
    category = "scroll",
    calculator = calculators.scroll.ctrl_b,
    description = "scroll up full-page",
    input = "count",
  })

  -- Position motions (zz/zt/zb)
  motions.register({
    id = "position_zz",
    keys = { "zz" },
    modes = { "n" },
    traits = { "scroll" },
    category = "scroll",
    calculator = calculators.scroll.zz,
    description = "center cursor",
  })

  motions.register({
    id = "position_zt",
    keys = { "zt" },
    modes = { "n" },
    traits = { "scroll" },
    category = "scroll",
    calculator = calculators.scroll.zt,
    description = "cursor to top",
  })

  motions.register({
    id = "position_zb",
    keys = { "zb" },
    modes = { "n" },
    traits = { "scroll" },
    category = "scroll",
    calculator = calculators.scroll.zb,
    description = "cursor to bottom",
  })
end

function M.register_all()
  M.register_traits()
  M.register_motions()
end

return M
```

**Step 2: Commit**

```bash
git add lua/luxmotion/registry/builtin.lua
git commit -m "feat: add builtin trait and motion registrations"
```

---

### Task 18: Update init.lua to Use New System

**Files:**
- Modify: `lua/luxmotion/init.lua`

**Step 1: Read current init.lua**

Read the file to understand current structure before modifying.

**Step 2: Replace init.lua with new implementation**

```lua
-- lua/luxmotion/init.lua
local config = require("luxmotion.config")
local builtin = require("luxmotion.registry.builtin")
local keymaps = require("luxmotion.registry.keymaps")
local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local loop = require("luxmotion.engine.loop")

local M = {}

local initialized = false

function M.setup(user_config)
  if initialized then
    M.reset()
  end

  config.setup(user_config)
  builtin.register_all()
  keymaps.setup()

  initialized = true
end

function M.reset()
  keymaps.clear()
  loop.stop_all()
  traits.clear()
  motions.clear()
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

return M
```

**Step 3: Verify new init loads**

```vim
:lua package.loaded["luxmotion"] = nil; package.loaded["luxmotion.init"] = nil; print(vim.inspect(require("luxmotion")))
```
Expected: Table with setup, reset, enable, disable, toggle functions.

**Step 4: Commit**

```bash
git add lua/luxmotion/init.lua
git commit -m "feat: update init.lua to use motion registry system"
```

---

## Phase 6: Cleanup (Remove Old Code)

### Task 19: Delete Old cursor/ Directory

**Files:**
- Delete: `lua/luxmotion/cursor/` (entire directory)

**Step 1: Remove the cursor directory**

```bash
rm -rf lua/luxmotion/cursor
```

**Step 2: Commit**

```bash
git add -A
git commit -m "refactor: remove old cursor/ directory (replaced by registry)"
```

---

### Task 20: Delete Old scroll/ Directory

**Files:**
- Delete: `lua/luxmotion/scroll/` (entire directory)

**Step 1: Remove the scroll directory**

```bash
rm -rf lua/luxmotion/scroll
```

**Step 2: Commit**

```bash
git add -A
git commit -m "refactor: remove old scroll/ directory (replaced by registry)"
```

---

### Task 21: Clean Up Unused Files in core/

**Files:**
- Delete: `lua/luxmotion/core/animation.lua`
- Delete: `lua/luxmotion/core/state.lua`
- Delete: `lua/luxmotion/core/pool.lua`
- Keep: `lua/luxmotion/core/viewport.lua`

**Step 1: Remove redundant core files**

```bash
rm lua/luxmotion/core/animation.lua
rm lua/luxmotion/core/state.lua
rm lua/luxmotion/core/pool.lua
```

**Step 2: Commit**

```bash
git add -A
git commit -m "refactor: remove redundant core/ files (replaced by engine/)"
```

---

### Task 22: Clean Up Unused utils/ Files

**Files:**
- Delete: `lua/luxmotion/utils/animation.lua`
- Delete: `lua/luxmotion/utils/math.lua`
- Delete: `lua/luxmotion/utils/window.lua`
- Delete: `lua/luxmotion/utils/buffer.lua`
- Keep: `lua/luxmotion/utils/visual.lua`

**Step 1: Remove redundant utils files**

```bash
rm lua/luxmotion/utils/animation.lua 2>/dev/null || true
rm lua/luxmotion/utils/math.lua 2>/dev/null || true
rm lua/luxmotion/utils/window.lua 2>/dev/null || true
rm lua/luxmotion/utils/buffer.lua 2>/dev/null || true
```

**Step 2: Commit**

```bash
git add -A
git commit -m "refactor: remove redundant utils/ files"
```

---

## Phase 7: Testing and Verification

### Task 23: Manual Integration Test

**Files:**
- None (manual testing)

**Step 1: Start fresh Neovim and load plugin**

```bash
cd /Users/josstei/Development/lux-workspace/LuxVim/debug/nvim-luxmotion/.worktrees/motion-registry-refactor
nvim --clean -u NONE
```

Then in Neovim:
```vim
:set runtimepath+=.
:lua require("luxmotion").setup()
```

**Step 2: Test basic cursor motions**

- Press `j` - cursor should animate down
- Press `k` - cursor should animate up
- Press `5j` - cursor should animate down 5 lines
- Press `w` - cursor should animate to next word
- Press `b` - cursor should animate to previous word

**Step 3: Test scroll motions**

- Press `<C-d>` - should scroll down half page with animation
- Press `<C-u>` - should scroll up half page with animation
- Press `G` - should animate to end of file
- Press `gg` - should animate to start of file

**Step 4: Test find motions**

- Press `fa` - should animate to next 'a' character
- Press `Fa` - should animate to previous 'a' character

**Step 5: Document any issues found**

If issues found, create follow-up tasks.

---

### Task 24: Final Commit and Summary

**Files:**
- None

**Step 1: Verify clean git status**

```bash
git status
```
Expected: Clean working tree.

**Step 2: Create summary commit if any final tweaks were made**

If changes were made during testing:
```bash
git add -A
git commit -m "fix: address issues found during integration testing"
```

**Step 3: Log final state**

```bash
git log --oneline -20
```

---

## Summary

**Total Tasks:** 24

**Phase Breakdown:**
- Phase 1 (Foundation): 3 tasks
- Phase 2 (Engine): 3 tasks
- Phase 3 (Calculators): 9 tasks
- Phase 4 (Keymaps): 1 task
- Phase 5 (Integration): 2 tasks
- Phase 6 (Cleanup): 4 tasks
- Phase 7 (Testing): 2 tasks

**Files Created:** 14
**Files Modified:** 1
**Files Deleted:** ~12

**Key Architectural Changes:**
- Scattered cursor/scroll modules → Unified registry system
- ~60 manual keymaps → Auto-generated from registry
- 7 similar handlers → 1 handler factory
- Hardcoded traits → Registered, composable traits
