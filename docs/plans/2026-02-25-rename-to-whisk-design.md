# Design: Rename nvim-luxmotion to whisk.nvim

**Date**: 2026-02-25
**Status**: Approved
**Scope**: Full plugin rename with deprecation shims for backwards compatibility

## Decision

Rename the plugin from `LuxVim/nvim-luxmotion` to `josstei/whisk.nvim`. In-place rename with GitHub repo transfer to preserve stars, issues, and watchers.

## Naming Convention Map

| Context | Before | After |
|---------|--------|-------|
| GitHub repo | `LuxVim/nvim-luxmotion` | `josstei/whisk.nvim` |
| Plugin spec | `"LuxVim/nvim-luxmotion"` | `"josstei/whisk.nvim"` |
| Lua namespace | `require("luxmotion")` | `require("whisk")` |
| Vim commands | `:LuxMotionEnable` | `:WhiskEnable` |
| Vim globals | `g:loaded_luxmotion` | `g:loaded_whisk` |
| Augroups | `LuxmotionLifecycle` | `WhiskLifecycle` |
| Plugin file | `plugin/luxmotion.vim` | `plugin/whisk.vim` |
| Lua directory | `lua/luxmotion/` | `lua/whisk/` |

## Directory & File Renames

| Before | After |
|--------|-------|
| `lua/luxmotion/` | `lua/whisk/` |
| `plugin/luxmotion.vim` | `plugin/whisk.vim` |

Internal directory structure under `lua/whisk/` is preserved: `config/`, `engine/`, `registry/`, `context/`, `calculators/`, `cursor/`, `scroll/`, `utils/`.

## String Replacements (~200-250 occurrences)

| Pattern | Before | After | Scope |
|---------|--------|-------|-------|
| Lua requires | `require("luxmotion` | `require("whisk` | ~70-80 in source, ~40 in tests |
| Vim commands | `LuxMotion` | `Whisk` | `plugin/whisk.vim` |
| Vim globals | `g:loaded_luxmotion`, `g:luxmotion_auto_setup` | `g:loaded_whisk`, `g:whisk_auto_setup` | `plugin/whisk.vim` |
| Augroup | `LuxmotionLifecycle` | `WhiskLifecycle` | `engine/lifecycle.lua` |
| Plugin name in docs | `nvim-luxmotion` | `whisk.nvim` | README, USAGE, ARCHITECTURE |
| Plugin spec in docs | `"LuxVim/nvim-luxmotion"` | `"josstei/whisk.nvim"` | README examples |
| Test runner output | `"Running nvim-luxmotion tests..."` | `"Running whisk.nvim tests..."` | `scripts/run_tests.sh` |

## Deprecation Shims

Thin forwarding layers that preserve backwards compatibility with a deprecation warning. Marked for removal in a future major version.

### `lua/luxmotion/init.lua`

Forwards `require("luxmotion")` to `require("whisk")` with a `vim.notify` warning at `WARN` level.

### `plugin/luxmotion.vim`

Aliases all old `:LuxMotion*` commands to their `:Whisk*` equivalents:

- `:LuxMotionEnable` -> `:WhiskEnable`
- `:LuxMotionDisable` -> `:WhiskDisable`
- `:LuxMotionToggle` -> `:WhiskToggle`
- `:LuxMotionEnableCursor` -> `:WhiskEnableCursor`
- `:LuxMotionDisableCursor` -> `:WhiskDisableCursor`
- `:LuxMotionEnableScroll` -> `:WhiskEnableScroll`
- `:LuxMotionDisableScroll` -> `:WhiskDisableScroll`
- `:LuxMotionPerformanceEnable` -> `:WhiskPerformanceEnable`
- `:LuxMotionPerformanceDisable` -> `:WhiskPerformanceDisable`
- `:LuxMotionPerformanceToggle` -> `:WhiskPerformanceToggle`

## LuxVim Integration

- Rename `LuxVim/lua/plugins/ui/luxmotion.lua` to `whisk.lua`
- Update source to `"josstei/whisk.nvim"`
- Update `require("luxmotion")` to `require("whisk")`

## GitHub Repo Transfer (Manual)

1. Transfer `LuxVim/nvim-luxmotion` to `josstei` (preserves stars, issues, watchers)
2. Rename to `whisk.nvim`
3. Update local git remote: `git remote set-url origin git@github.com:josstei/whisk.nvim.git`

## Breaking Changes

| What breaks | Before | After | Mitigation |
|-------------|--------|-------|------------|
| Plugin spec | `"LuxVim/nvim-luxmotion"` | `"josstei/whisk.nvim"` | GitHub redirect via transfer |
| `require("luxmotion")` | `require("luxmotion").setup({})` | `require("whisk").setup({})` | Deprecation shim forwards with warning |
| `:LuxMotion*` commands | `:LuxMotionToggle` | `:WhiskToggle` | Deprecation shim aliases with warning |
| Vim globals | `g:luxmotion_auto_setup` | `g:whisk_auto_setup` | Deprecation shim forwards with warning |
| `orchestrator.execute()` path | `require("luxmotion.engine.orchestrator")` | `require("whisk.engine.orchestrator")` | Deprecation shim forwards top-level only |

## What Does NOT Change

- Config structure (`cursor`, `scroll`, `keymaps`, `performance`)
- Motion IDs (`basic_j`, `word_w`, `scroll_ctrl_d`, etc.)
- Internal architecture (engine, registry, calculators, traits, context)
- All behavior and functionality
- Test structure and coverage
