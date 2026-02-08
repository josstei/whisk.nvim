local config = require("luxmotion.config")
local motions = require("luxmotion.registry.motions")

local M = {}

local policies = {}

function M.register(definition)
  policies[definition.id] = {
    id = definition.id,
    should_trail = definition.should_trail,
  }
end

function M.get(policy_id)
  return policies[policy_id]
end

function M.resolve(motion_id)
  local motion = motions.get(motion_id)
  local category = motion and motion.category or "cursor"
  local category_config = config.get(category)
  local trail_config = category_config and category_config.trail

  local override_id = trail_config and trail_config.overrides and trail_config.overrides[motion_id]
  if override_id then
    local override_policy = policies[override_id]
    if override_policy then
      return override_policy
    end
    vim.notify(
      string.format("[luxmotion] Unknown trail policy '%s' in overrides for motion '%s'", override_id, motion_id),
      vim.log.levels.WARN
    )
  end

  if motion and motion.trail_policy then
    local motion_policy = policies[motion.trail_policy]
    if motion_policy then
      return motion_policy
    end
  end

  local default_id = trail_config and trail_config.policy
  if default_id then
    local default_policy = policies[default_id]
    if default_policy then
      return default_policy
    end
  end

  return policies["always"] or { id = "always", should_trail = function() return true end }
end

function M.clear()
  policies = {}
end

return M
