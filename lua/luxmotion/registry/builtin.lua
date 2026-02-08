local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local calculators = require("luxmotion.calculators")
local config = require("luxmotion.config")
local renderer = require("luxmotion.trail.renderer")
local trail_highlights = require("luxmotion.trail.highlights")

local M = {}

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
    traits.register({
      id = "trail",
      apply = function(context, result, progress)
        local category_config = config.get(context.category or "cursor")
        local trail = category_config and category_config.trail
        if not trail then
          return
        end
        renderer.push_position(context.bufnr, result, trail.segments)
        renderer.render(context.bufnr, trail.segments)
      end,
      on_start = function(context)
        renderer.reset()
      end,
      on_complete = function(context)
        if context and context.bufnr then
          renderer.clear(context.bufnr)
        else
          renderer.reset()
        end
      end,
    })
  end
end

function M.register_motions()
  local cursor_cfg = config.get("cursor")
  local scroll_cfg = config.get("scroll")
  local cursor_trail_enabled = cursor_cfg and cursor_cfg.trail and cursor_cfg.trail.enabled
  local scroll_trail_enabled = scroll_cfg and scroll_cfg.trail and scroll_cfg.trail.enabled

  local function cursor_traits(base)
    if cursor_trail_enabled then
      local t = {}
      for _, v in ipairs(base) do table.insert(t, v) end
      table.insert(t, "trail")
      return t
    end
    return base
  end

  local function scroll_traits(base)
    if scroll_trail_enabled then
      local t = {}
      for _, v in ipairs(base) do table.insert(t, v) end
      table.insert(t, "trail")
      return t
    end
    return base
  end

  for _, dir in ipairs({ "h", "j", "k", "l" }) do
    motions.register({
      id = "basic_" .. dir,
      keys = { dir },
      modes = { "n", "v" },
      traits = cursor_traits({ "cursor" }),
      category = "cursor",
      calculator = calculators.basic[dir],
      description = "move " .. dir,
      input = "count",
      trail_policy = "distance",
    })
  end

  motions.register({
    id = "basic_0",
    keys = { "0" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor" }),
    category = "cursor",
    calculator = calculators.basic["0"],
    description = "move to line start",
    trail_policy = "always",
  })

  motions.register({
    id = "basic_$",
    keys = { "$" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor" }),
    category = "cursor",
    calculator = calculators.basic["$"],
    description = "move to line end",
    trail_policy = "always",
  })

  for _, dir in ipairs({ "w", "b", "e", "W", "B", "E" }) do
    motions.register({
      id = "word_" .. dir,
      keys = { dir },
      modes = { "n", "v" },
      traits = cursor_traits({ "cursor" }),
      category = "cursor",
      calculator = calculators.word[dir],
      description = "word " .. dir,
      input = "count",
      trail_policy = "always",
    })
  end

  for _, dir in ipairs({ "f", "F", "t", "T" }) do
    motions.register({
      id = "find_" .. dir,
      keys = { dir },
      modes = { "n", "v" },
      traits = cursor_traits({ "cursor" }),
      category = "cursor",
      calculator = calculators.find[dir],
      description = "find " .. dir,
      input = "char",
      trail_policy = "always",
    })
  end

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
      traits = cursor_traits({ "cursor" }),
      category = "cursor",
      calculator = calculators.text_object[key],
      description = desc,
      input = "count",
      trail_policy = "always",
    })
  end

  motions.register({
    id = "line_gg",
    keys = { "gg" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor", "scroll" }),
    category = "cursor",
    calculator = calculators.line.gg,
    description = "goto first line",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "line_G",
    keys = { "G" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor", "scroll" }),
    category = "cursor",
    calculator = calculators.line.G,
    description = "goto last line",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "line_|",
    keys = { "|" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor" }),
    category = "cursor",
    calculator = calculators.line["|"],
    description = "goto column",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "search_n",
    keys = { "n" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor" }),
    category = "cursor",
    calculator = calculators.search.n,
    description = "next search result",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "search_N",
    keys = { "N" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor" }),
    category = "cursor",
    calculator = calculators.search.N,
    description = "previous search result",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "screen_gj",
    keys = { "gj" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor" }),
    category = "cursor",
    calculator = calculators.search.gj,
    description = "down screen line",
    input = "count",
    trail_policy = "distance",
  })

  motions.register({
    id = "screen_gk",
    keys = { "gk" },
    modes = { "n", "v" },
    traits = cursor_traits({ "cursor" }),
    category = "cursor",
    calculator = calculators.search.gk,
    description = "up screen line",
    input = "count",
    trail_policy = "distance",
  })

  motions.register({
    id = "scroll_ctrl_d",
    keys = { "<C-d>" },
    modes = { "n", "v" },
    traits = scroll_traits({ "cursor", "scroll" }),
    category = "scroll",
    calculator = calculators.scroll.ctrl_d,
    description = "scroll down half-page",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "scroll_ctrl_u",
    keys = { "<C-u>" },
    modes = { "n", "v" },
    traits = scroll_traits({ "cursor", "scroll" }),
    category = "scroll",
    calculator = calculators.scroll.ctrl_u,
    description = "scroll up half-page",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "scroll_ctrl_f",
    keys = { "<C-f>" },
    modes = { "n", "v" },
    traits = scroll_traits({ "cursor", "scroll" }),
    category = "scroll",
    calculator = calculators.scroll.ctrl_f,
    description = "scroll down full-page",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "scroll_ctrl_b",
    keys = { "<C-b>" },
    modes = { "n", "v" },
    traits = scroll_traits({ "cursor", "scroll" }),
    category = "scroll",
    calculator = calculators.scroll.ctrl_b,
    description = "scroll up full-page",
    input = "count",
    trail_policy = "always",
  })

  motions.register({
    id = "position_zz",
    keys = { "zz" },
    modes = { "n" },
    traits = scroll_traits({ "scroll" }),
    category = "scroll",
    calculator = calculators.scroll.zz,
    description = "center cursor",
    trail_policy = "always",
  })

  motions.register({
    id = "position_zt",
    keys = { "zt" },
    modes = { "n" },
    traits = scroll_traits({ "scroll" }),
    category = "scroll",
    calculator = calculators.scroll.zt,
    description = "cursor to top",
    trail_policy = "always",
  })

  motions.register({
    id = "position_zb",
    keys = { "zb" },
    modes = { "n" },
    traits = scroll_traits({ "scroll" }),
    category = "scroll",
    calculator = calculators.scroll.zb,
    description = "cursor to bottom",
    trail_policy = "always",
  })
end

function M.register_all()
  M.register_traits()
  M.register_motions()
end

return M
