local traits = require("whisk.registry.traits")
local motions = require("whisk.registry.motions")
local context_builder = require("whisk.context.builder")
local loop = require("whisk.engine.loop")
local config = require("whisk.config")

local M = {}

local function is_same_position(context, result)
  if not result.cursor then
    return false
  end
  return context.cursor.line == result.cursor.line and context.cursor.col == result.cursor.col
end

local function is_same_viewport(context, result)
  if not result.viewport or not result.viewport.topline then
    return true
  end
  return context.viewport.topline == result.viewport.topline
end

local function apply_final_result(motion, context, result)
  for _, trait_id in ipairs(motion.traits) do
    traits.apply_frame(trait_id, context, result, 1.0)
  end
end

local function should_skip_animation()
  return vim.fn.reg_executing() ~= "" or vim.fn.state("m") ~= ""
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

  loop.complete_all()

  local context = context_builder.build(input)
  local result = motion.calculator(context)

  if not result then
    return
  end

  if is_same_position(context, result) and is_same_viewport(context, result) then
    return
  end

  apply_final_result(motion, context, result)

  if should_skip_animation() then
    return
  end

  loop.start({
    context = context,
    result = result,
    traits = motion.traits,
    duration = category_config.duration,
    easing = category_config.easing,
  })
end

function M.fallback(motion, input)
  local keys = ""
  if input.count and input.count > 1 then
    keys = tostring(input.count)
  end
  keys = keys .. (input.direction or motion.keys[1])
  if input.char then
    keys = keys .. input.char
  end
  vim.cmd.normal({ vim.api.nvim_replace_termcodes(keys, true, false, true), bang = true })
end

return M
