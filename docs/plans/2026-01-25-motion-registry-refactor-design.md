# Motion Registry Refactor Design

## Overview

Refactor nvim-luxmotion's animation system from scattered cursor/scroll modules into a unified, extensible architecture using a Motion Registry pattern with composable traits.

## Goals

1. **Reduce boilerplate** - Collapse ~60 repetitive keymap calls and 7 similar handler functions
2. **Reduce complexity** - Centralize animation coordination logic
3. **Enable extensibility** - Make adding new motion types trivial
4. **Secondary: Performance** - Maintain or improve current performance characteristics

## Architecture

### Directory Structure

```
lua/luxmotion/
├── init.lua                 # Public API and setup
├── config/                  # Configuration (unchanged)
├── registry/
│   ├── traits.lua           # Trait definitions and state
│   ├── motions.lua          # Motion definitions
│   └── keymaps.lua          # Keymap generation from registry
├── engine/
│   ├── orchestrator.lua     # Animation coordination
│   ├── loop.lua             # Frame loop
│   └── pool.lua             # Object pooling
├── context/
│   └── builder.lua          # Builds context object for calculators
├── calculators/
│   ├── init.lua             # Calculator index
│   ├── basic.lua            # h/j/k/l/0/$
│   ├── word.lua             # w/b/e/W/B/E
│   ├── find.lua             # f/F/t/T
│   ├── text_object.lua      # {/}/(/)/%
│   ├── line.lua             # gg/G/|
│   ├── search.lua           # n/N
│   └── scroll.lua           # C-d/C-u/C-f/C-b/zz/zt/zb
└── utils/                   # Shared utilities (slimmed down)
```

### Data Flow

1. Keypress triggers registered motion
2. Context builder gathers current state
3. Calculator computes target from context
4. Orchestrator checks trait states, starts animation
5. Loop applies each trait's `apply()` function per frame
6. On completion, trait states reset

### Directories Eliminated

- `cursor/` - Logic moves to `calculators/` and `registry/traits.lua`
- `scroll/` - Logic moves to `calculators/` and `registry/traits.lua`

## Core Components

### 1. Trait Registry

Traits are animation capabilities registered as first-class entities. Each trait manages its own state and defines how to apply animation progress.

```lua
-- registry/traits.lua
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

return M
```

**Built-in traits:**

- **cursor** - Moves cursor position via `nvim_win_set_cursor`
- **scroll** - Adjusts viewport topline via `restore_view`

### 2. Motion Registry

Holds all motion definitions. Motions declare keys, modes, traits, calculator, and category.

```lua
-- registry/motions.lua
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

return M
```

**Example registrations:**

```lua
M.register({
  id = "word_forward",
  keys = { "w" },
  modes = { "n", "v" },
  traits = { "cursor" },
  category = "cursor",
  calculator = calculators.word,
  description = "word forward",
  input = "count",
})

M.register({
  id = "goto_line",
  keys = { "G" },
  modes = { "n", "v" },
  traits = { "cursor", "scroll" },
  category = "cursor",
  calculator = calculators.line_jump,
  description = "goto line",
  input = "count",
})
```

### 3. Context Builder

Gathers all relevant state into a standardized object for calculators.

```lua
-- context/builder.lua
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

**Calculator result shape:**

```lua
{
  cursor = {
    line = 25,
    col = 10,
  },
  viewport = {
    topline = 15,
  },
}
```

### 4. Calculators

Pure functions with standardized signatures. Take context, return result.

```lua
-- calculators/word.lua
local M = {}

function M.forward(context)
  local original = { context.cursor.line, context.cursor.col }
  vim.cmd("normal! " .. context.input.count .. "w")
  local target = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, original)

  return {
    cursor = { line = target[1], col = target[2] },
  }
end

function M.backward(context)
  -- Same pattern with "b"
end

function M.end_of(context)
  -- Same pattern with "e"
end

return M
```

```lua
-- calculators/line.lua
local M = {}

function M.goto_line(context)
  local target_line
  local count = context.input.count
  local direction = context.input.direction

  if direction == "gg" then
    target_line = count
  elseif direction == "G" then
    target_line = count == 1 and context.buffer.line_count or count
  end

  target_line = math.max(1, math.min(target_line, context.buffer.line_count))

  return {
    cursor = { line = target_line, col = 0 },
    viewport = { topline = M.calculate_topline(target_line, context) },
  }
end

return M
```

### 5. Orchestrator

Central coordinator. Motion-agnostic - just coordinates registered traits and motions.

```lua
-- engine/orchestrator.lua
local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local context_builder = require("luxmotion.context.builder")
local loop = require("luxmotion.engine.loop")
local config = require("luxmotion.config")

local M = {}

function M.execute(motion_id, input)
  local motion = motions.get(motion_id)
  if not motion then return end

  local category_config = config.get(motion.category)
  if not category_config.enabled then
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

  if not result then return end
  if M.is_same_position(context, result) then return end

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
  local cmd = input.count > 1 and tostring(input.count) or ""
  cmd = cmd .. (input.direction or motion.keys[1])
  if input.char then cmd = cmd .. input.char end
  vim.cmd("normal! " .. cmd)
end

return M
```

### 6. Keymap Generation

Auto-generates keymaps from the motion registry at setup time.

```lua
-- registry/keymaps.lua
local motions = require("luxmotion.registry.motions")
local orchestrator = require("luxmotion.engine.orchestrator")
local config = require("luxmotion.config")

local M = {}

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
        })
      end
    end

    ::continue::
  end
end

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

return M
```

### 7. Animation Loop

Frame-by-frame execution that applies traits. Knows nothing about cursor or scroll.

```lua
-- engine/loop.lua
local traits = require("luxmotion.registry.traits")
local pool = require("luxmotion.engine.pool")
local performance = require("luxmotion.performance")

local M = {}

local frame_queue = {}
local is_running = false

local function lerp(start_val, end_val, progress)
  return start_val + (end_val - start_val) * progress
end

local function interpolate_result(context, result, progress)
  local interpolated = { cursor = {}, viewport = {} }

  if result.cursor then
    interpolated.cursor.line = math.floor(lerp(context.cursor.line, result.cursor.line, progress) + 0.5)
    interpolated.cursor.col = math.floor(lerp(context.cursor.col, result.cursor.col, progress) + 0.5)
  end

  if result.viewport then
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
      anim.on_complete()
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

return M
```

### 8. Setup and Initialization

```lua
-- init.lua
local config = require("luxmotion.config")
local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local keymaps = require("luxmotion.registry.keymaps")
local calculators = require("luxmotion.calculators")
local viewport = require("luxmotion.core.viewport")

local M = {}

local function register_builtin_traits()
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
      if result.viewport then
        viewport.restore_view(result.viewport.topline, result.cursor.line, result.cursor.col)
      end
    end,
  })
end

local function register_builtin_motions()
  for _, dir in ipairs({ "h", "j", "k", "l", "0", "$" }) do
    motions.register({
      id = "basic_" .. dir,
      keys = { dir },
      traits = { "cursor" },
      category = "cursor",
      calculator = calculators.basic[dir],
      description = "move " .. dir,
    })
  end

  -- Word motions, find motions, scroll motions, etc.
end

function M.setup(user_config)
  config.setup(user_config)
  register_builtin_traits()
  register_builtin_motions()
  keymaps.setup()
end

return M
```

## Benefits Summary

| Goal | Before | After |
|------|--------|-------|
| Boilerplate | ~60 keymap calls, 7 similar handlers | 1 loop, 1 handler factory |
| Extensibility | Edit multiple files | Add one `motions.register()` call |
| Complexity | Logic scattered across cursor/, scroll/ | Centralized in orchestrator |
| Traits | Hardcoded cursor vs scroll | Composable, registered traits |

## User-Facing Config

No changes to user-facing configuration:

```lua
require("luxmotion").setup({
  cursor = { duration = 250, easing = "ease-out", enabled = true },
  scroll = { duration = 400, easing = "ease-out", enabled = true },
  keymaps = {
    cursor = true,
    scroll = true,
  },
  performance = {
    enabled = false,
    auto_enable_on_large_files = true,
    large_file_threshold = 5000,
  },
})
```

## Migration Strategy

1. Create new directory structure alongside existing
2. Implement registry, orchestrator, and loop
3. Port calculators from existing movement modules
4. Register all existing motions
5. Switch keymaps to use new system
6. Delete old cursor/ and scroll/ directories
7. Update tests

## Future Extensibility

Adding a new motion type (e.g., mark navigation):

```lua
motions.register({
  id = "goto_mark",
  keys = { "'" },
  modes = { "n" },
  traits = { "cursor", "scroll" },
  category = "cursor",
  calculator = calculators.mark,
  description = "goto mark",
  input = "char",
})
```

Adding a new trait (e.g., fold handling):

```lua
traits.register({
  id = "fold",
  apply = function(context, result, progress)
    -- Open folds as cursor passes through
  end,
})
```
