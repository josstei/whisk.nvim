# Architecture

whisk.nvim is organized around a motion registry, a context layer that captures buffer/window state, calculators that compute target positions, and an animation engine that interpolates between start and target over time.

---

## High-level flow

1. A keymap (or custom call) triggers `orchestrator.execute(motion_id, input)`.
2. The orchestrator checks if the motion's category is enabled. If not, it falls back to `normal!`.
3. If any of the motion's traits are already animating, all active animations complete instantly at their final positions (domination).
4. The context builder captures a snapshot of cursor, viewport, and buffer state.
5. The motion's calculator returns a target cursor/viewport position.
6. The animation loop interpolates from start to target over time, applying easing.
7. Trait handlers apply each interpolated frame to Neovim.

---

## Module structure

```
lua/whisk/
  init.lua                    Main entry point (setup, toggles)
  config.lua                  Config facade (re-exports submodules)
  performance.lua             Performance mode and frame monitoring

  config/
    defaults.lua              Default configuration values
    validation.lua            Config validation
    management.lua            Runtime config get/update/reset (get accepts optional category key)

  registry/
    builtin.lua               Registers built-in traits and motions
    motions.lua               Motion definition store (tracks by category via internal categories table)
    traits.lua                Trait store and animation state
    keymaps.lua               Keymap installation from registry (skips categories where config is false)

  context/
    Context.lua               Context class (buffer/window snapshot + methods)
    builder.lua               Builds a hydrated context from input

  calculators/
    init.lua                  Aggregator for all calculator modules
    basic.lua                 h, j, k, l, 0, $ (direct math)
    word.lua                  w, b, e, W, B, E (native delegation)
    find.lua                  f, F, t, T (native delegation, requires char)
    text_object.lua           {, }, (, ), % (native delegation)
    line.lua                  gg, G, | (direct math + viewport calculation)
    search.lua                n, N, gj, gk (native delegation; gj/gk are screen-line motions colocated here)
    scroll.lua                ctrl_d/u/f/b, zz/zt/zb (direct math)

  engine/
    orchestrator.lua          Motion execution, domination, fallback
    loop.lua                  Animation loop, easing, frame interpolation
    pool.lua                  Object pool for animation tables
    lifecycle.lua             Autocmd-based animation cancellation

  cursor/
    keymaps.lua               Deprecated cursor motion wrappers
  scroll/
    keymaps.lua               Deprecated scroll motion wrappers

  utils/
    visual.lua                Visual mode helpers

lua/luxmotion/
  init.lua                    Deprecation shim (forwards to whisk with warning)

plugin/
  whisk.vim                   VimScript entry point (auto-setup, Whisk* commands: Enable/Disable/Toggle, EnableCursor/DisableCursor, EnableScroll/DisableScroll, PerformanceEnable/PerformanceDisable/PerformanceToggle)
  luxmotion.vim               Deprecation shim (bridges g:luxmotion_auto_setup → g:whisk_auto_setup, defines LuxMotion* command aliases)
```

---

## Runtime flow

```mermaid
flowchart TD
  A[Keymap or custom call] --> B[orchestrator.execute]
  B --> C{Category enabled?}
  C -- no --> D[Fallback: normal!]
  C -- yes --> E{Trait already animating?}
  E -- yes --> F[Complete active animation at final position]
  F --> G[Build context snapshot]
  E -- no --> G
  G --> H[Run calculator]
  H --> I{Movement detected?}
  I -- no --> J[Return]
  I -- yes --> K[Start animation loop]
  K --> L[Interpolate frames with easing]
  L --> M[Traits apply to Neovim]
```

---

## Module dependencies

```mermaid
flowchart LR
  shim[plugin/luxmotion.vim] -.->|bridges g:luxmotion_auto_setup → g:whisk_auto_setup + defines LuxMotion* aliases| plugin[plugin/whisk.vim]
  plugin --> init[whisk/init.lua]
  init --> config[config/*]
  init --> builtin[registry/builtin.lua]
  init --> keymaps_reg[registry/keymaps.lua]
  init --> traits_reg[registry/traits.lua]
  init --> motions[registry/motions.lua]
  init --> loop[engine/loop.lua]
  init --> lifecycle[engine/lifecycle.lua]

  builtin --> motions
  builtin --> traits_reg
  builtin --> calcs[calculators/*]

  keymaps_reg --> motions
  keymaps_reg --> config
  keymaps_reg --> orch[engine/orchestrator.lua]
  orch --> motions
  orch --> traits_reg
  orch --> config
  orch --> builder[context/builder.lua]
  orch --> loop

  builder --> ctx[context/Context.lua]
  loop --> pool[engine/pool.lua]
  loop --> perf[performance.lua]
  loop --> traits_reg
  perf --> config
  lifecycle -.->|lazy require| loop
```

Dashed lines indicate lazy `require()` calls (deferred to function call time rather than module load time). `lifecycle.lua` defers its `require("whisk.engine.loop")` to function bodies to avoid a circular dependency at load time. Although `init.lua` uses `require("whisk.performance")` inside `setup()` and `toggle_performance()`, this is not a true lazy load — `performance.lua` is already cached because `init.lua` eagerly requires `loop.lua` at module load time, and `loop.lua` eagerly requires `performance.lua`.

---

## Setup and teardown

`init.setup(user_config)` handles re-initialization: if already initialized, it calls `reset()` before proceeding. This allows users to call `setup()` multiple times (e.g., to change config at runtime) without leaking keymaps or autocmds.

`init.reset()` tears down in this order: `keymaps.clear()`, `loop.stop_all()`, `traits.clear()`, `motions.clear()`, `lifecycle.teardown()`. Note that `performance.setup()` installs `BufEnter`/`BufWinEnter` autocmds without a named augroup, so these are **not** torn down by `reset()`. Performance autocmds persist across re-initialization.

---

## Orchestrator

`orchestrator.execute(motion_id, input)` performs:

1. Look up the motion definition from `motions.get(motion_id)`.
2. Check category config (`cursor` or `scroll`) is enabled. If disabled, call `fallback()` which runs `normal! [count]<key>[char]` (count is only prepended when greater than 1).
3. Check if any of the motion's traits are currently animating. If so, call `loop.complete_all()` to snap **all** active animations to their final positions (domination). The check is per-trait, but the effect is global.
4. Build a context snapshot via `context.builder.build(input)`.
5. Run the calculator. Exit early if no result or if the cursor position hasn't changed. Note: the check compares cursor line/col only — viewport-only changes (e.g., topline shift with cursor stationary) will also exit early.
6. Mark all motion traits as animating.
7. Start the animation loop with the context, result, traits, duration, and easing. The `on_complete` callback clears all trait animating flags.

---

## Context

The context layer captures a snapshot of Neovim state and provides safe mutation methods.

### Context class (`context/Context.lua`)

Constructed via `Context.new(bufnr, winid)`. Captures buffer and window state at construction time in `self.start`:

| Method | Description |
|--------|-------------|
| `is_valid()` | Returns false if buffer deleted, window closed, or buffer changed |
| `get_line_count()` | Current buffer line count |
| `get_line_length(line)` | Length of a specific line |
| `clamp_line(line)` | Clamp to valid line range |
| `clamp_column(col, line)` | Clamp to valid column range |
| `clamp_position(line, col)` | Clamp both line and column |
| `set_cursor(line, col)` | Validate, clamp, and set cursor position |
| `restore_view(topline, line, col)` | Validate, clamp, and restore viewport + cursor |

### Context builder (`context/builder.lua`)

`build(input)` constructs a Context and populates derived fields:

- `ctx.input` — `{ char, count, direction }`
- `ctx.cursor` — `{ line, col }` (1-indexed line from the snapshot)
- `ctx.viewport` — `{ topline, height, width }`
- `ctx.buffer` — `{ line_count }`

---

## Animation engine

### Loop (`engine/loop.lua`)

The animation loop uses `vim.defer_fn` for frame scheduling and `vim.loop.hrtime()` for high-resolution timing.

Each frame:

1. Records frame time via `performance.record_frame_time()`.
2. Iterates the frame queue in reverse for safe removal.
3. If `context.is_valid` is truthy (i.e., the field exists as a function), validates via `context:is_valid()`. If invalid, fires `on_cancel` with a reason string, removes the animation, and skips to the next entry.
4. Computes `progress = elapsed / duration`, clamped to `[0, 1]`.
5. Applies the easing function to get `eased` progress.
6. Calls `interpolate_result()` to lerp cursor line/col and viewport topline between start and target.
7. Calls `traits.apply_frame()` for each trait.
8. When `progress >= 1.0`: fires `on_complete`, removes from queue, releases animation object to pool.
9. Reschedules itself if the queue is non-empty; otherwise stops.

Frame interval is determined by `performance.get_frame_interval()`: 16ms (~60fps) normally, 33ms (~30fps) when both performance mode is active and `reduce_frame_rate` is enabled. Durations are converted from milliseconds to nanoseconds internally (`duration * 1000000`) for use with `vim.loop.hrtime()`.

**Easing functions:** `linear`, `ease-in`, `ease-out`, `ease-in-out`.

**Additional loop exports:**

| Function | Description |
|----------|-------------|
| `stop_all()` | Cancels all animations without firing `on_complete` (used by `init.reset()`) |
| `complete_all()` | Snaps all animations to their final positions and fires `on_complete` (domination) |
| `cancel_for_buffer(bufnr)` | Cancels animations targeting the specified buffer (used by lifecycle) |
| `cancel_for_window(winid)` | Cancels animations targeting the specified window (used by lifecycle) |
| `get_active_count()` | Returns the number of active animations in the frame queue |
| `is_running()` | Returns whether the animation loop is currently running |
| `force_process_frame()` | Triggers an immediate frame tick (useful for testing) |

### Object pool (`engine/pool.lua`)

Recycles animation table allocations to reduce garbage collection pressure.

- Maximum pool size: 10 objects.
- `acquire()` returns a pooled object or allocates a new one.
- `release(animation)` resets all fields (numbers to 0, references to nil) and returns the object to the pool if under capacity.
- `get_stats()` returns `{ pool_size, max_pool_size }` for introspection.
- `clear()` empties the pool entirely.

### Lifecycle (`engine/lifecycle.lua`)

Creates a `WhiskLifecycle` augroup with three autocmds:

| Event | Action |
|-------|--------|
| `BufDelete` | Cancel animations for the deleted buffer |
| `WinClosed` | Cancel animations for the closed window |
| `BufLeave` | Cancel animations for the left buffer |

**Additional lifecycle exports:**

| Function | Description |
|----------|-------------|
| `teardown()` | Deletes the `WhiskLifecycle` augroup and all its autocmds (called by `init.reset()`) |
| `is_active()` | Returns whether the lifecycle augroup is currently registered |

---

## Traits

Traits are small apply functions that know how to write an interpolated frame to Neovim:

- **cursor** trait calls `context:set_cursor(line, col)`.
- **scroll** trait calls `context:restore_view(topline, line, col)`.

Traits also track per-trait animation state to enable domination (preventing overlapping animations of the same type).

Trait definitions (stored in the traits registry) accept `on_start` and `on_complete` hooks alongside the `apply` function. These hooks live on the trait definition, not on animation objects. Animation objects in the pool carry `on_complete` and `on_cancel` callbacks that are set per-animation by the orchestrator — these are distinct from the trait-level hooks.

The traits module exposes two reset mechanisms:

- `reset()` — resets all animation state flags to `false` but preserves trait definitions.
- `clear()` — removes both definitions and state entirely (used by `init.reset()`).

---

## Calculators

Calculators receive a context and return a target:

```lua
{
  cursor = { line = ..., col = ... },
  viewport = { topline = ... },
}
```

Two calculation strategies:

- **Direct math** — basic, line, and scroll calculators compute targets arithmetically from context values.
- **Native delegation** — word, find, search (including screen-line motions gj/gk), and text object calculators execute `normal!` motions to find the accurate target, then restore the cursor before returning the result. Note: `gj`/`gk` are colocated in `search.lua` for implementation convenience, but their motion IDs use a `screen_` prefix (`screen_gj`, `screen_gk`) and are registered under the `cursor` category.

---

## Performance mode

When enabled, performance mode:

- Conditionally disables syntax highlighting (`vim.bo.syntax = "off"`, restored on disable) when `disable_syntax_during_scroll` is set.
- Reduces frame rate from 60fps to 30fps when both performance mode is active **and** `reduce_frame_rate` is set.
- Populates a passive lookup table of ignored events (default: `WinScrolled`, `CursorMoved`, `CursorMovedI`). Callers check `should_ignore_event(event)` to decide whether to skip logic — no autocmds are registered to intercept events.
- Auto-toggles on `BufEnter`/`BufWinEnter` via `auto_toggle()`: enables for files exceeding `large_file_threshold` lines or when `performance.enabled` is `true` in config; disables otherwise.
- Maintains a rolling window of the last 10 frame times for FPS calculation.
- Exposes `get_frame_interval()` and `get_current_fps()` for introspection.

Note: `frame_rate_threshold` is defined in defaults (`60`) but is not currently read by any code path. It exists as a placeholder for future use.

---

## Extension points

- **Custom keymaps** — call `orchestrator.execute()` directly with any registered motion ID, or use `require("whisk.registry.keymaps").create_handler(motion)` to generate a keymap handler function that reads `vim.v.count1` and collects char input automatically.
- **Custom motions** — register via `require("whisk.registry.motions").register()`.
- **Custom traits** — register via `require("whisk.registry.traits").register()`.
- **Selective built-in registration** — `require("whisk.registry.builtin")` exposes `register_all()`, `register_traits()`, and `register_motions()` separately.
- Built-in motions and traits are registered through `registry/builtin.lua` during setup.
