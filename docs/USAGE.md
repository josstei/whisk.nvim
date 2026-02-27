# Usage Guide

whisk.nvim wraps standard Vim motion commands with animated cursor and scroll transitions while preserving native behavior.

---

## Installation

Use your preferred plugin manager. The plugin auto-calls `require("whisk").setup()` on startup unless disabled.

### lazy.nvim

```lua
{
  "josstei/whisk.nvim",
  event = "VeryLazy",
  opts = {},
}
```

### vim-plug

```vim
Plug 'josstei/whisk.nvim'
```

```lua
require("whisk").setup()
```

### Disable auto-setup

The VimScript entrypoint calls setup automatically unless you opt out:

```vim
let g:whisk_auto_setup = 0
```

Then call `require("whisk").setup()` yourself after loading the plugin.

---

## Configuration

All options with their defaults:

```lua
require("whisk").setup({
  cursor = {
    duration = 150,
    easing = "ease-out",
    enabled = true,
  },
  scroll = {
    duration = 200,
    easing = "ease-in-out",
    enabled = true,
  },
  keymaps = {
    cursor = true,
    scroll = true,
  },
  performance = {
    enabled = false,
    disable_syntax_during_scroll = true,
    ignore_events = { "WinScrolled", "CursorMoved", "CursorMovedI" },
    reduce_frame_rate = false,
    frame_rate_threshold = 60,
    auto_enable_on_large_files = true,
    large_file_threshold = 5000,
  },
})
```

### Cursor options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `duration` | number | `150` | Animation duration in ms |
| `easing` | string | `"ease-out"` | Easing function |
| `enabled` | boolean | `true` | Enable cursor animations |

### Scroll options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `duration` | number | `200` | Animation duration in ms |
| `easing` | string | `"ease-in-out"` | Easing function |
| `enabled` | boolean | `true` | Enable scroll animations |

### Keymap options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cursor` | boolean | `true` | Install default cursor motion keymaps |
| `scroll` | boolean | `true` | Install default scroll motion keymaps |

### Performance options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Start in performance mode |
| `disable_syntax_during_scroll` | boolean | `true` | Disable syntax highlighting when performance mode is enabled (restored on disable) |
| `ignore_events` | table | `{"WinScrolled", "CursorMoved", "CursorMovedI"}` | Events to flag as ignorable via `should_ignore_event()` while performance mode is active |
| `reduce_frame_rate` | boolean | `false` | Switch from 60fps to 30fps during animations when performance mode is active |
| `frame_rate_threshold` | number | `60` | Target FPS threshold for auto-switching to reduced frame rate (not currently read by any code path) |
| `auto_enable_on_large_files` | boolean | `true` | Auto-enable for large buffers |
| `large_file_threshold` | number | `5000` | Line count threshold for auto-enable |

**Easing options:** `linear`, `ease-in`, `ease-out`, `ease-in-out`

---

## Commands

| Command | Description |
|---------|-------------|
| `:WhiskEnable` | Enable all animations |
| `:WhiskDisable` | Disable all animations |
| `:WhiskToggle` | Toggle all animations |
| `:WhiskEnableCursor` | Enable cursor animations |
| `:WhiskDisableCursor` | Disable cursor animations |
| `:WhiskEnableScroll` | Enable scroll animations |
| `:WhiskDisableScroll` | Disable scroll animations |
| `:WhiskPerformanceEnable` | Enable performance mode |
| `:WhiskPerformanceDisable` | Disable performance mode |
| `:WhiskPerformanceToggle` | Toggle performance mode |

---

## Lua API

```lua
local whisk = require("whisk")

whisk.setup({})

whisk.enable()
whisk.disable()
whisk.toggle()

whisk.enable_cursor()
whisk.disable_cursor()

whisk.enable_scroll()
whisk.disable_scroll()

whisk.toggle_performance()

whisk.reset()              -- tear down keymaps, stop animations, clear all registries (including custom), remove lifecycle autocmds
```

### Performance module

```lua
local performance = require("whisk.performance")

performance.enable()
performance.disable()
performance.is_active()
performance.get_current_fps()
performance.get_frame_interval()
performance.should_ignore_event(event)
performance.should_auto_enable()     -- check if current buffer exceeds large_file_threshold
performance.auto_toggle()            -- enable/disable based on config and buffer size
performance.record_frame_time()      -- record a frame timestamp for FPS calculation
```

---

## Manual motions

For custom mappings or manual motion execution, use the orchestrator:

```lua
local orchestrator = require("whisk.engine.orchestrator")

orchestrator.execute("basic_j", { count = 5, direction = "j" })
orchestrator.execute("word_w", { count = 2, direction = "w" })
orchestrator.execute("find_f", { char = "x", count = 1, direction = "f" })
orchestrator.execute("scroll_ctrl_d", { count = 1, direction = "<C-d>" })
```

### Motion IDs

| Category | IDs |
|----------|-----|
| Basic | `basic_h`, `basic_j`, `basic_k`, `basic_l`, `basic_0`, `basic_$` |
| Word | `word_w`, `word_b`, `word_e`, `word_W`, `word_B`, `word_E` |
| Find | `find_f`, `find_F`, `find_t`, `find_T` |
| Text Object | `text_object_{`, `text_object_}`, `text_object_(`, `text_object_)`, `text_object_%` |
| Line | `line_gg`, `line_G`, `line_\|` |
| Search | `search_n`, `search_N` |
| Screen | `screen_gj`, `screen_gk` |
| Scroll | `scroll_ctrl_d`, `scroll_ctrl_u`, `scroll_ctrl_f`, `scroll_ctrl_b`, `position_zz`\*, `position_zt`\*, `position_zb`\* |

\* Normal mode only.

---

## Custom keymaps

Disable default mappings and provide your own:

```lua
require("whisk").setup({
  keymaps = { cursor = false, scroll = false },
})

local orchestrator = require("whisk.engine.orchestrator")

vim.keymap.set("n", "j", function()
  orchestrator.execute("basic_j", { count = vim.v.count1, direction = "j" })
end, { silent = true })
```

---

## Registry API

Register custom motions and traits, or selectively load built-ins:

```lua
local motions = require("whisk.registry.motions")
local traits = require("whisk.registry.traits")
local builtin = require("whisk.registry.builtin")
local keymaps = require("whisk.registry.keymaps")

motions.register({ id = "...", keys = {...}, modes = {...}, traits = {...}, category = "...", calculator = fn })
traits.register({ id = "...", apply = fn, on_start = fn, on_complete = fn })

builtin.register_all()       -- register all built-in traits and motions
builtin.register_traits()    -- register only built-in traits
builtin.register_motions()   -- register only built-in motions

keymaps.create_handler(motion)  -- generate a keymap handler for a registered motion
```

Note: `whisk.reset()` clears all registered motions and traits, including custom ones. Re-register after calling `reset()` or `setup()`.

---

## Behavior notes

- If a motion category is disabled, whisk falls back to native `normal!` motion behavior.
- When a new motion starts while any of its traits are already animating, **all** active animations (not just the conflicting ones) complete instantly at their final positions before the new animation begins (domination).
- Word, find, search, and text object calculators delegate to native `normal!` motions for accuracy, then restore the cursor before animating. Screen-line motions (`gj`/`gk`) also use native delegation and are colocated in the search calculator module.
- Visual mode is supported for all motions except `position_zz`, `position_zt`, and `position_zb` which are Normal mode only.
- Animations are automatically cancelled when the buffer is deleted (`BufDelete`), the window is closed (`WinClosed`), or the buffer is left (`BufLeave`).
- The animation engine uses an object pool (up to 10 reusable animation objects) to reduce garbage collection pressure during rapid motion sequences.

---

## Migrating from nvim-luxmotion

whisk.nvim was previously published as nvim-luxmotion. A deprecation shim is included:

- `require("luxmotion")` forwards to `require("whisk")` with a warning.
- All `:LuxMotion*` commands forward to their `:Whisk*` equivalents.
- `g:luxmotion_auto_setup` forwards to `g:whisk_auto_setup`.

The deprecated `whisk.cursor.keymaps` and `whisk.scroll.keymaps` modules also forward to the orchestrator with a deprecation warning. If your config references these modules, switch to `require("whisk.engine.orchestrator")` directly.

Deprecated cursor functions: `smooth_move`, `smooth_word_move`, `smooth_find_move`, `smooth_text_object_move`, `smooth_line_move`, `smooth_search_move`, `smooth_screen_line_move`, `setup_keymaps`.

Deprecated scroll functions: `smooth_scroll`, `visual_smooth_scroll`, `smooth_position`, `setup_keymaps`.

The shim will be removed in a future release. Update your config to use `whisk` directly.

---

## Compatibility

Requires Neovim >= 0.7.
