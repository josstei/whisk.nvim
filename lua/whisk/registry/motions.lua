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

function M.clear()
  motions = {}
  categories = {}
end

return M
