# Rename nvim-luxmotion to whisk.nvim — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename the plugin from `nvim-luxmotion` to `whisk.nvim` across all source, tests, docs, and scripts, with deprecation shims for backwards compatibility.

**Architecture:** Mechanical rename — no behavioral changes. The Lua module directory moves from `lua/luxmotion/` to `lua/whisk/`, all internal `require()` paths update accordingly, Vim commands change from `:LuxMotion*` to `:Whisk*`, and thin deprecation shims preserve the old names with warnings.

**Tech Stack:** Lua, VimScript, shell scripts

**Design doc:** `docs/plans/2026-02-25-rename-to-whisk-design.md`

---

### Task 1: Rename directories and files with git mv

**Files:**
- Rename: `lua/luxmotion/` → `lua/whisk/`
- Rename: `plugin/luxmotion.vim` → `plugin/whisk.vim`

**Step 1: Rename the Lua module directory**

```bash
cd /Users/josstei/Development/lux-workspace/nvim-plugins/nvim-luxmotion
git mv lua/luxmotion lua/whisk
```

**Step 2: Rename the plugin VimScript file**

```bash
git mv plugin/luxmotion.vim plugin/whisk.vim
```

**Step 3: Verify renames**

```bash
ls lua/whisk/init.lua && ls plugin/whisk.vim && echo "OK"
```

Expected: both files exist, prints "OK"

**Step 4: Commit**

```bash
git add -A && git commit -m "refactor: rename lua/luxmotion to lua/whisk and plugin file"
```

---

### Task 2: Update all require() paths in source files

**Files:**
- Modify: `lua/whisk/init.lua`
- Modify: `lua/whisk/config.lua`
- Modify: `lua/whisk/config/management.lua`
- Modify: `lua/whisk/context/builder.lua`
- Modify: `lua/whisk/cursor/keymaps.lua`
- Modify: `lua/whisk/scroll/keymaps.lua`
- Modify: `lua/whisk/calculators/init.lua`
- Modify: `lua/whisk/engine/loop.lua`
- Modify: `lua/whisk/engine/orchestrator.lua`
- Modify: `lua/whisk/engine/lifecycle.lua`
- Modify: `lua/whisk/performance.lua`
- Modify: `lua/whisk/registry/builtin.lua`
- Modify: `lua/whisk/registry/keymaps.lua`

**Step 1: Bulk replace require paths in all Lua source files**

In every `.lua` file under `lua/whisk/`, replace all occurrences:

| Before | After |
|--------|-------|
| `require("luxmotion.` | `require("whisk.` |
| `require('luxmotion.` | `require('whisk.` |
| `require("luxmotion")` | `require("whisk")` |
| `require('luxmotion')` | `require('whisk')` |

**Step 2: Update deprecation messages in cursor/keymaps.lua**

File: `lua/whisk/cursor/keymaps.lua`

Replace:
```lua
"[luxmotion] cursor.keymaps is deprecated. Use luxmotion.engine.orchestrator instead. See :help luxmotion-migration"
```
With:
```lua
"[whisk] cursor.keymaps is deprecated. Use whisk.engine.orchestrator instead. See :help whisk-migration"
```

**Step 3: Update deprecation messages in scroll/keymaps.lua**

File: `lua/whisk/scroll/keymaps.lua`

Replace:
```lua
"[luxmotion] scroll.keymaps is deprecated. Use luxmotion.engine.orchestrator instead. See :help luxmotion-migration"
```
With:
```lua
"[whisk] scroll.keymaps is deprecated. Use whisk.engine.orchestrator instead. See :help whisk-migration"
```

**Step 4: Update augroup name in lifecycle.lua**

File: `lua/whisk/engine/lifecycle.lua`

Replace:
```lua
vim.api.nvim_create_augroup('LuxmotionLifecycle', { clear = true })
```
With:
```lua
vim.api.nvim_create_augroup('WhiskLifecycle', { clear = true })
```

**Step 5: Verify no remaining luxmotion references in source**

```bash
grep -r "luxmotion" lua/whisk/ --include="*.lua"
```

Expected: zero matches

**Step 6: Commit**

```bash
git add lua/whisk/ && git commit -m "refactor: update all require paths from luxmotion to whisk"
```

---

### Task 3: Update plugin/whisk.vim (commands and globals)

**Files:**
- Modify: `plugin/whisk.vim`

**Step 1: Rewrite plugin/whisk.vim with new names**

Replace the entire file contents with:

```vim
if exists('g:loaded_whisk')
  finish
endif
let g:loaded_whisk = 1

command! WhiskEnable lua require('whisk').enable()
command! WhiskDisable lua require('whisk').disable()
command! WhiskToggle lua require('whisk').toggle()

command! WhiskEnableCursor lua require('whisk').enable_cursor()
command! WhiskDisableCursor lua require('whisk').disable_cursor()
command! WhiskEnableScroll lua require('whisk').enable_scroll()
command! WhiskDisableScroll lua require('whisk').disable_scroll()

command! WhiskPerformanceEnable lua require('whisk.performance').enable()
command! WhiskPerformanceDisable lua require('whisk.performance').disable()
command! WhiskPerformanceToggle lua require('whisk').toggle_performance()

if !exists('g:whisk_auto_setup')
  let g:whisk_auto_setup = 1
endif

if g:whisk_auto_setup
  lua require('whisk').setup()
endif
```

**Step 2: Verify no remaining luxmotion references**

```bash
grep -i "luxmotion" plugin/whisk.vim
```

Expected: zero matches

**Step 3: Commit**

```bash
git add plugin/whisk.vim && git commit -m "refactor: rename vim commands from LuxMotion to Whisk"
```

---

### Task 4: Update all require() paths in test files

**Files:**
- Modify: `tests/mocks/init.lua`
- Modify: `tests/unit/init_spec.lua`
- Modify: `tests/unit/config_spec.lua`
- Modify: `tests/unit/config/defaults_spec.lua`
- Modify: `tests/unit/config/management_spec.lua`
- Modify: `tests/unit/config/validation_spec.lua`
- Modify: `tests/unit/context/builder_spec.lua`
- Modify: `tests/unit/context/Context_spec.lua`
- Modify: `tests/unit/engine/lifecycle_spec.lua`
- Modify: `tests/unit/engine/loop_spec.lua`
- Modify: `tests/unit/engine/orchestrator_spec.lua`
- Modify: `tests/unit/engine/pool_spec.lua`
- Modify: `tests/unit/performance_spec.lua`
- Modify: `tests/unit/registry/builtin_spec.lua`
- Modify: `tests/unit/registry/keymaps_spec.lua`
- Modify: `tests/unit/registry/motions_spec.lua`
- Modify: `tests/unit/registry/traits_spec.lua`
- Modify: `tests/unit/calculators/basic_spec.lua`
- Modify: `tests/unit/calculators/find_spec.lua`
- Modify: `tests/unit/calculators/line_spec.lua`
- Modify: `tests/unit/calculators/scroll_spec.lua`
- Modify: `tests/unit/calculators/search_spec.lua`
- Modify: `tests/unit/calculators/text_object_spec.lua`
- Modify: `tests/unit/calculators/word_spec.lua`
- Modify: `tests/unit/shims/cursor_keymaps_spec.lua`
- Modify: `tests/unit/shims/scroll_keymaps_spec.lua`
- Modify: `tests/unit/utils/visual_spec.lua`
- Modify: `tests/integration/context_lifecycle_spec.lua`
- Modify: `tests/shim_test.lua`

**Step 1: Bulk replace require paths in all test files**

In every `.lua` file under `tests/`, replace all occurrences:

| Before | After |
|--------|-------|
| `require("luxmotion.` | `require("whisk.` |
| `require('luxmotion.` | `require('whisk.` |
| `require("luxmotion")` | `require("whisk")` |
| `require('luxmotion')` | `require('whisk')` |

**Step 2: Update package.loaded references in test files**

In `tests/mocks/init.lua`, replace:
```lua
if name:match('^luxmotion') then
```
With:
```lua
if name:match('^whisk') then
```

In `tests/unit/shims/cursor_keymaps_spec.lua`, replace:
```lua
package.loaded['luxmotion.engine.orchestrator'] = {
```
With:
```lua
package.loaded['whisk.engine.orchestrator'] = {
```

In `tests/unit/shims/scroll_keymaps_spec.lua`, apply the same replacement.

**Step 3: Update local variable names in init_spec.lua**

File: `tests/unit/init_spec.lua`

Replace:
```lua
local luxmotion
```
With:
```lua
local whisk
```

And all references to `luxmotion.setup`, `luxmotion.enable`, `luxmotion.disable`, `luxmotion.toggle`, `luxmotion.reset`, `luxmotion.enable_cursor`, `luxmotion.disable_cursor`, `luxmotion.enable_scroll`, `luxmotion.disable_scroll`, `luxmotion.toggle_performance` become `whisk.*` equivalents.

**Step 4: Update local variable names in integration test**

File: `tests/integration/context_lifecycle_spec.lua`

Replace `local luxmotion` → `local whisk` and all `luxmotion.*` → `whisk.*` references.

**Step 5: Update shim_test.lua**

File: `tests/shim_test.lua`

Replace all `require("luxmotion")` and `require("luxmotion.engine.orchestrator")` and `require("luxmotion.cursor.keymaps")` and `require("luxmotion.scroll.keymaps")` with their `whisk` equivalents.

**Step 6: Verify no remaining luxmotion references in tests**

```bash
grep -r "luxmotion" tests/ --include="*.lua"
```

Expected: zero matches

**Step 7: Commit**

```bash
git add tests/ && git commit -m "refactor: update all test require paths from luxmotion to whisk"
```

---

### Task 5: Run tests to verify rename

**Step 1: Run the test suite**

```bash
cd /Users/josstei/Development/lux-workspace/nvim-plugins/nvim-luxmotion
./scripts/run_tests.sh
```

Expected: all tests pass

**Step 2: If tests fail, fix any missed references**

Search for any remaining `luxmotion` references:

```bash
grep -ri "luxmotion" lua/ tests/ plugin/ scripts/ --include="*.lua" --include="*.vim" --include="*.sh"
```

Fix any found references and re-run tests.

---

### Task 6: Create deprecation shims

**Files:**
- Create: `lua/luxmotion/init.lua`
- Create: `plugin/luxmotion.vim`

**Step 1: Create Lua deprecation shim**

Create `lua/luxmotion/init.lua`:

```lua
vim.notify(
  "[luxmotion] nvim-luxmotion has been renamed to whisk.nvim. "
    .. 'Update your config to require("whisk"). '
    .. "This shim will be removed in a future release.",
  vim.log.levels.WARN
)

return require("whisk")
```

**Step 2: Create VimScript deprecation shim**

Create `plugin/luxmotion.vim`:

```vim
command! LuxMotionEnable WhiskEnable
command! LuxMotionDisable WhiskDisable
command! LuxMotionToggle WhiskToggle
command! LuxMotionEnableCursor WhiskEnableCursor
command! LuxMotionDisableCursor WhiskDisableCursor
command! LuxMotionEnableScroll WhiskEnableScroll
command! LuxMotionDisableScroll WhiskDisableScroll
command! LuxMotionPerformanceEnable WhiskPerformanceEnable
command! LuxMotionPerformanceDisable WhiskPerformanceDisable
command! LuxMotionPerformanceToggle WhiskPerformanceToggle
```

**Step 3: Verify shim files exist and have correct content**

```bash
cat lua/luxmotion/init.lua
cat plugin/luxmotion.vim
```

**Step 4: Commit**

```bash
git add lua/luxmotion/init.lua plugin/luxmotion.vim && git commit -m "feat: add deprecation shims for backwards compatibility"
```

---

### Task 7: Update scripts

**Files:**
- Modify: `scripts/run_tests.sh`

**Step 1: Update test runner output**

File: `scripts/run_tests.sh`

Replace:
```bash
echo "Running nvim-luxmotion tests..."
```
With:
```bash
echo "Running whisk.nvim tests..."
```

**Step 2: Commit**

```bash
git add scripts/ && git commit -m "refactor: update script references from luxmotion to whisk"
```

---

### Task 8: Update documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/USAGE.md`
- Modify: `docs/ARCHITECTURE.md`

**Step 1: Bulk replace in README.md**

Apply these replacements throughout the file:

| Before | After |
|--------|-------|
| `nvim-luxmotion` | `whisk.nvim` |
| `"LuxVim/nvim-luxmotion"` | `"josstei/whisk.nvim"` |
| `require("luxmotion` | `require("whisk` |
| `require('luxmotion` | `require('whisk` |
| `:LuxMotionEnable` | `:WhiskEnable` |
| `:LuxMotionDisable` | `:WhiskDisable` |
| `:LuxMotionToggle` | `:WhiskToggle` |
| `:LuxMotionEnableCursor` | `:WhiskEnableCursor` |
| `:LuxMotionDisableCursor` | `:WhiskDisableCursor` |
| `:LuxMotionEnableScroll` | `:WhiskEnableScroll` |
| `:LuxMotionDisableScroll` | `:WhiskDisableScroll` |
| `:LuxMotionPerformanceEnable` | `:WhiskPerformanceEnable` |
| `:LuxMotionPerformanceDisable` | `:WhiskPerformanceDisable` |
| `:LuxMotionPerformanceToggle` | `:WhiskPerformanceToggle` |
| `luxmotion` (standalone lowercase in prose) | `whisk` |
| `LuxMotion` (standalone CamelCase in prose) | `Whisk` |

**Step 2: Bulk replace in docs/USAGE.md**

Apply same replacement table as README.md. Additionally:

| Before | After |
|--------|-------|
| `# LuxMotion Usage` | `# Whisk Usage` |
| `LuxMotion is a smooth motion plugin` | `Whisk is a smooth motion plugin` |
| `g:luxmotion_auto_setup` | `g:whisk_auto_setup` |
| `luxmotion.cursor.keymaps` | `whisk.cursor.keymaps` |
| `luxmotion.scroll.keymaps` | `whisk.scroll.keymaps` |
| `luxmotion.engine.orchestrator` | `whisk.engine.orchestrator` |
| `LuxMotion falls back` | `Whisk falls back` |

**Step 3: Bulk replace in docs/ARCHITECTURE.md**

Apply same replacement table. Additionally:

| Before | After |
|--------|-------|
| `# LuxMotion Architecture` | `# Whisk Architecture` |
| `LuxMotion is organized` | `Whisk is organized` |
| `plugin/luxmotion.vim` | `plugin/whisk.vim` |
| `lua/luxmotion/` | `lua/whisk/` |

**Step 4: Verify no remaining luxmotion references in docs (except design plan)**

```bash
grep -ri "luxmotion" README.md docs/USAGE.md docs/ARCHITECTURE.md
```

Expected: zero matches (the design plan file is expected to still have references)

**Step 5: Commit**

```bash
git add README.md docs/USAGE.md docs/ARCHITECTURE.md && git commit -m "docs: update all references from luxmotion to whisk"
```

---

### Task 9: Final verification

**Step 1: Run full test suite**

```bash
cd /Users/josstei/Development/lux-workspace/nvim-plugins/nvim-luxmotion
./scripts/run_tests.sh
```

Expected: all tests pass

**Step 2: Verify no stray references (excluding design plan and deprecation shims)**

```bash
grep -ri "luxmotion" lua/whisk/ tests/ plugin/whisk.vim scripts/ README.md docs/USAGE.md docs/ARCHITECTURE.md --include="*.lua" --include="*.vim" --include="*.sh" --include="*.md"
```

Expected: zero matches

**Step 3: Verify deprecation shims only have intentional references**

```bash
grep -c "luxmotion" lua/luxmotion/init.lua plugin/luxmotion.vim
```

Expected: references only in the deprecation warning text and command aliases

---

### Task 10: Update git remote (manual, after GitHub transfer)

This task is performed AFTER the GitHub repository transfer is complete.

**Step 1: Transfer repo on GitHub**

Go to `github.com/LuxVim/nvim-luxmotion` → Settings → Transfer ownership → Transfer to `josstei`

**Step 2: Rename repo on GitHub**

Go to `github.com/josstei/nvim-luxmotion` → Settings → Rename to `whisk.nvim`

**Step 3: Update local git remote**

```bash
git remote set-url origin git@github.com:josstei/whisk.nvim.git
git remote -v
```

Expected: origin points to `git@github.com:josstei/whisk.nvim.git`

**Step 4: Push all changes**

```bash
git push origin HEAD
```
