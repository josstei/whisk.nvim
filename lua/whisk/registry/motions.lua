local M = {}

local motions = {}
local categories = {}

local allowed_modes = { n = true, x = true }

local function validate_modes(id, modes)
  for _, mode in ipairs(modes) do
    if not allowed_modes[mode] then
      error(string.format(
        'whisk: motion "%s" maps mode "%s"; only "n" (Normal) and "x" (Visual) are allowed. "v" also maps Select mode, where typed keys must insert text.',
        tostring(id),
        tostring(mode)
      ), 3)
    end
  end
end

function M.register(definition)
  local modes = definition.modes or { "n", "x" }
  validate_modes(definition.id, modes)

  local motion = {
    id = definition.id,
    keys = definition.keys,
    modes = modes,
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
