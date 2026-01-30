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
