# Trail Policy System Design

## Problem

The cursor trail currently fires on every cursor movement, including single `h`, `j`, `k`, `l` presses. This creates visual noise, reduces the semantic emphasis of the trail on meaningful navigation jumps, and wastes rendering cycles on trivial movements.

## Solution

Introduce a **trail policy system** - an abstraction layer between motion execution and trail rendering that decides at runtime whether a given motion should produce a trail.

## Architecture

### Policy Interface

```lua
---@class TrailPolicyDefinition
---@field id string
---@field should_trail fun(context: Context, result: Result): boolean
```

Single-method contract. Receives motion context (start position, buffer, window, motion ID) and result (target position, viewport changes). Returns a boolean.

### Policy Registry

New module at `lua/luxmotion/trail/policies/init.lua`. Mirrors the existing trait registry pattern.

**API:**

- `policies.register(definition)` - Register a policy by definition
- `policies.get(policy_id)` - Get a policy by ID
- `policies.resolve(motion_id)` - Resolve effective policy for a motion

**Resolution chain (highest to lowest priority):**

1. User overrides: `config.trail.overrides[motion_id]`
2. Motion's declared `trail_policy` field
3. Category default: `config.trail.policy`
4. Fallback: `"always"` (backwards-compatible)

### File Structure

**New files:**

```
lua/luxmotion/trail/policies/
├── init.lua              -- Policy registry
├── always.lua            -- Always-trail policy
├── never.lua             -- Never-trail policy
└── distance.lua          -- Distance-threshold policy
```

**Modified files:**

```
lua/luxmotion/registry/builtin.lua    -- Add trail_policy to motion registrations, register policies
lua/luxmotion/registry/motions.lua    -- Store trail_policy field on motion definitions
lua/luxmotion/registry/traits.lua     -- Pass result to invoke_start
lua/luxmotion/engine/orchestrator.lua -- Attach motion_id to context
lua/luxmotion/config/defaults.lua     -- Add policy config
```

## Built-in Policies

### `always`

```lua
should_trail = function(context, result)
  return true
end
```

For navigation motions where trail is always meaningful (w, b, f, gg, G, etc.).

### `never`

```lua
should_trail = function(context, result)
  return false
end
```

Opt-out for motions that should never trail.

### `distance`

```lua
should_trail = function(context, result)
  if not result.cursor then return false end
  local delta_line = math.abs(result.cursor.line - context.cursor.line)
  local delta_col = math.abs(result.cursor.col - context.cursor.col)
  return delta_line >= min_lines or delta_col >= min_cols
end
```

Trails only when movement exceeds a threshold in either axis. Separate line and column thresholds because vertical and horizontal movement are visually distinct in a text editor.

**Default thresholds:**

- `min_lines = 2` - Anything more than a single line jump
- `min_cols = 5` - Roughly a word's width of horizontal movement

Thresholds read from config at registration time (no runtime config lookups in the hot path).

## Motion Policy Assignments

| Motions | Policy | Rationale |
|---|---|---|
| h, j, k, l | `distance` | Single-step moves are noise; counted moves are navigation |
| gj, gk | `distance` | Same as basic vertical movement |
| 0, $, \| | `always` | Line-position jumps are always intentional |
| w, b, e, W, B, E | `always` | Word navigation is always meaningful |
| f, F, t, T | `always` | Character find is deliberate targeting |
| gg, G | `always` | File-level jumps |
| {, }, (, ), % | `always` | Structural navigation |
| n, N | `always` | Search result hopping |
| Ctrl-d/u/f/b, zz/zt/zb | `always` | Scroll motions are large by nature |

## Trail Trait Integration

Policy evaluated **once in `on_start`**, cached on context as `trail_active`:

```lua
traits.register({
  id = "trail",
  on_start = function(context, result)
    local policy = policies.resolve(context.motion_id)
    context.trail_active = policy.should_trail(context, result)
    if context.trail_active then
      renderer.reset()
    end
  end,
  apply = function(context, result, progress)
    if not context.trail_active then return end
    local category_config = config.get(context.category or "cursor")
    local trail = category_config and category_config.trail
    if not trail then return end
    renderer.push_position(context.bufnr, result, trail.segments)
    renderer.render(context.bufnr, trail.segments)
  end,
  on_complete = function(context)
    if not context.trail_active then return end
    if context and context.bufnr then
      renderer.clear(context.bufnr)
    else
      renderer.reset()
    end
  end,
})
```

**Signature change:** `traits.invoke_start(trait_id, context)` becomes `traits.invoke_start(trait_id, context, result)` to pass result through for distance calculation.

## Configuration

### Defaults

```lua
cursor = {
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
```

### User Override Example

```lua
require("luxmotion").setup({
  cursor = {
    trail = {
      policy = "distance",
      distance = {
        min_lines = 3,
        min_cols = 8,
      },
      overrides = {
        basic_h = "never",
        basic_l = "never",
        word_w = "distance",
      },
    },
  },
})
```

## Error Handling

- **Unknown policy ID in override**: Log warning, fall through to next resolution level
- **Missing `result.cursor`**: Distance policy returns `false`
- **Policy not registered**: `resolve()` returns `always` as final fallback

## Backwards Compatibility

Zero behavior change for existing users. If no policy config is provided, resolution chain falls back to `"always"`, which replicates current behavior (every motion trails).

## Testing

- **Policy registry**: Register, get, resolve with full override chain
- **`always` policy**: Returns true for any input
- **`never` policy**: Returns false for any input
- **`distance` policy**: Threshold boundary cases (at threshold, beyond, zero, single-axis, both axes)
- **Resolution chain**: Override > motion declaration > category default > fallback
- **Integration**: Trail trait respects `trail_active` flag, extmarks created/suppressed correctly

## Future Extensibility

The policy interface supports future implementations without architectural changes:

- **`velocity`** - Suppress trail during rapid repeated keypresses
- **`visual_distance`** - Factor in screen position rather than buffer position
- **`composite`** - Combine multiple policies with AND/OR logic
- **User-defined policies** - Register custom policies via `policies.register()`
