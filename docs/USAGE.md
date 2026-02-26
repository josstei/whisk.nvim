# Whisk Usage

Whisk is a smooth motion plugin for Neovim. It wraps standard motion commands with animated cursor/scroll transitions while preserving Vim's native behavior.

## Quick start

### Installation

Use your plugin manager of choice (lazy.nvim, packer.nvim, vim-plug, etc.). The plugin auto-calls `require("whisk").setup()` by default on startup.

### Minimal setup

```lua
require("whisk").setup()
```

### Disable auto-setup (optional)

The Vimscript entrypoint calls setup automatically unless you disable it:

```vim
let g:whisk_auto_setup = 0
```

Then call `require("whisk").setup()` yourself after loading the plugin.

## Configuration

All configuration is passed to `require("whisk").setup({...})`.

```lua
require("whisk").setup({
  cursor = {
    duration = 150,
    easing = "ease-out",
    enabled = true,
  },
  scroll = {
    duration = 240,
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

### Options

- `cursor.duration`: Animation duration for cursor motions, in ms.
- `cursor.easing`: `linear`, `ease-in`, `ease-out`, `ease-in-out`.
- `cursor.enabled`: Enable/disable cursor animations.
- `scroll.duration`: Animation duration for scrolling motions, in ms.
- `scroll.easing`: `linear`, `ease-in`, `ease-out`, `ease-in-out`.
- `scroll.enabled`: Enable/disable scroll animations.
- `keymaps.cursor`: Install default cursor motion keymaps.
- `keymaps.scroll`: Install default scroll motion keymaps.
- `performance.enabled`: Start in performance mode.
- `performance.disable_syntax_during_scroll`: Disable syntax highlighting while active.
- `performance.ignore_events`: Event list tracked by the performance module.
- `performance.reduce_frame_rate`: Switch to ~30fps while performance mode is active.
- `performance.frame_rate_threshold`: Reserved for future use (not referenced by core loop).
- `performance.auto_enable_on_large_files`: Auto-enable performance mode for large buffers.
- `performance.large_file_threshold`: Line count threshold for auto-enable.

## Commands

- `:WhiskEnable` / `:WhiskDisable` / `:WhiskToggle`
- `:WhiskEnableCursor` / `:WhiskDisableCursor`
- `:WhiskEnableScroll` / `:WhiskDisableScroll`
- `:WhiskPerformanceEnable` / `:WhiskPerformanceDisable` / `:WhiskPerformanceToggle`

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
```

Performance module:

```lua
local performance = require("whisk.performance")

performance.enable()
performance.disable()
performance.is_active()
performance.get_current_fps()
```

## Manual motions (custom keymaps)

If you want custom mappings or to trigger motions manually, use the orchestrator:

```lua
local orchestrator = require("whisk.engine.orchestrator")

orchestrator.execute("basic_j", { count = 5, direction = "j" })
orchestrator.execute("word_w", { count = 2, direction = "w" })
orchestrator.execute("find_f", { char = "x", count = 1, direction = "f" })
orchestrator.execute("scroll_ctrl_d", { count = 1, direction = "<C-d>" })
```

### Motion IDs

Categories and examples:

- Basic: `basic_h`, `basic_j`, `basic_k`, `basic_l`, `basic_0`, `basic_$`
- Word: `word_w`, `word_b`, `word_e`, `word_W`, `word_B`, `word_E`
- Find/Till: `find_f`, `find_F`, `find_t`, `find_T`
- Text objects: `text_object_{`, `text_object_}`, `text_object_(`, `text_object_)`, `text_object_%`
- Line jumps: `line_gg`, `line_G`, `line_|`
- Search: `search_n`, `search_N`, `screen_gj`, `screen_gk`
- Scroll: `scroll_ctrl_d`, `scroll_ctrl_u`, `scroll_ctrl_f`, `scroll_ctrl_b`, `position_zz`, `position_zt`, `position_zb`

## Keymaps and custom mappings

To disable default mappings and provide your own:

```lua
require("whisk").setup({
  keymaps = { cursor = false, scroll = false },
})

local orchestrator = require("whisk.engine.orchestrator")

vim.keymap.set("n", "j", function()
  orchestrator.execute("basic_j", { count = vim.v.count1, direction = "j" })
end, { silent = true })
```

## Behavior notes

- If a motion category is disabled, Whisk falls back to native `normal!` motion behavior.
- Several calculators use native motions to compute accurate targets, then restore the cursor before animating.
- Visual mode is supported for motions registered with `modes = { "n", "v" }`.

## Deprecated APIs

`whisk.cursor.keymaps` and `whisk.scroll.keymaps` are deprecated. Use `whisk.engine.orchestrator` for custom mappings.

## Compatibility

- Requires Neovim 0.7 or newer.
