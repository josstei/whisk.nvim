local orchestrator = require("whisk.engine.orchestrator")

local M = {}

local deprecated_warned = false
local function warn_deprecated()
  if not deprecated_warned then
    vim.notify(
      "[whisk] scroll.keymaps is deprecated. Use whisk.engine.orchestrator instead. See :help whisk-migration",
      vim.log.levels.WARN
    )
    deprecated_warned = true
  end
end

local function map_scroll_motion(command)
  local mapping = {
    ctrl_d = "scroll_ctrl_d",
    ctrl_u = "scroll_ctrl_u",
    ctrl_f = "scroll_ctrl_f",
    ctrl_b = "scroll_ctrl_b",
  }
  return mapping[command]
end

local function map_position_motion(command)
  local mapping = {
    zz = "position_zz",
    zt = "position_zt",
    zb = "position_zb",
  }
  return mapping[command]
end

function M.smooth_scroll(command, count)
  warn_deprecated()
  local motion_id = map_scroll_motion(command)
  if motion_id then
    orchestrator.execute(motion_id, { count = count or 1, direction = command })
  end
end

function M.visual_smooth_scroll(command, count)
  warn_deprecated()
  M.smooth_scroll(command, count)
end

function M.smooth_position(command)
  warn_deprecated()
  local motion_id = map_position_motion(command)
  if motion_id then
    orchestrator.execute(motion_id, { direction = command })
  end
end

function M.setup_keymaps()
end

return M
