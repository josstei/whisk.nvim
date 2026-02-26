local config = require("luxmotion.config")
local builtin = require("luxmotion.registry.builtin")
local keymaps = require("luxmotion.registry.keymaps")
local traits = require("luxmotion.registry.traits")
local motions = require("luxmotion.registry.motions")
local loop = require("luxmotion.engine.loop")
local lifecycle = require("luxmotion.engine.lifecycle")

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

  builtin.register_all()
  keymaps.setup()
  lifecycle.setup()

  initialized = true
end

function M.reset()
  keymaps.clear()
  loop.stop_all()
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
