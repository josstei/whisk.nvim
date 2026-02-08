local config = require("luxmotion.config")
local builtin = require("luxmotion.registry.builtin")
local keymaps = require("luxmotion.registry.keymaps")
local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local loop = require("luxmotion.engine.loop")
local lifecycle = require("luxmotion.engine.lifecycle")
local trail_highlights = require("luxmotion.trail.highlights")

local M = {}

local initialized = false

function M.setup(user_config)
  if initialized then
    M.reset()
  end

  config.validate(user_config)
  config.update(user_config)

  local performance = require("luxmotion.performance")
  performance.setup()

  local cursor_cfg = config.get("cursor")
  local scroll_cfg = config.get("scroll")

  local bg_color = '#1E1E2E'
  local hl_ok, normal_hl = pcall(vim.api.nvim_get_hl, 0, { name = 'Normal' })
  if hl_ok and normal_hl and normal_hl.bg then
    bg_color = trail_highlights.to_hex(
      math.floor(normal_hl.bg / 65536) % 256,
      math.floor(normal_hl.bg / 256) % 256,
      normal_hl.bg % 256
    )
  end

  if cursor_cfg.trail and cursor_cfg.trail.enabled then
    trail_highlights.setup(cursor_cfg.trail.color, bg_color, cursor_cfg.trail.segments)
  end

  if scroll_cfg.trail and scroll_cfg.trail.enabled then
    local scroll_segments = scroll_cfg.trail.segments
    local cursor_already_covers = cursor_cfg.trail and cursor_cfg.trail.enabled and cursor_cfg.trail.segments >= scroll_segments
    if not cursor_already_covers then
      trail_highlights.setup(scroll_cfg.trail.color, bg_color, scroll_segments)
    end
  end

  builtin.register_all()
  keymaps.setup()
  lifecycle.setup()

  initialized = true
end

function M.reset()
  keymaps.clear()
  loop.stop_all()
  trail_highlights.teardown()
  traits.clear()
  motions.clear()
  lifecycle.teardown()
  initialized = false
end

function M.enable()
  local cfg = config.get()
  cfg.cursor.enabled = true
  cfg.scroll.enabled = true
end

function M.disable()
  local cfg = config.get()
  cfg.cursor.enabled = false
  cfg.scroll.enabled = false
end

function M.toggle()
  local cfg = config.get()
  if cfg.cursor.enabled or cfg.scroll.enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.enable_cursor()
  config.get().cursor.enabled = true
end

function M.disable_cursor()
  config.get().cursor.enabled = false
end

function M.enable_scroll()
  config.get().scroll.enabled = true
end

function M.disable_scroll()
  config.get().scroll.enabled = false
end

function M.toggle_performance()
  local performance = require("luxmotion.performance")
  if performance.is_active() then
    performance.disable()
  else
    performance.enable()
  end
end

return M
