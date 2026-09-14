local config = require("whisk.config")
local builtin = require("whisk.registry.builtin")
local keymaps = require("whisk.registry.keymaps")
local traits = require("whisk.registry.traits")
local motions = require("whisk.registry.motions")
local loop = require("whisk.engine.loop")
local lifecycle = require("whisk.engine.lifecycle")

local M = {}

local initialized = false

function M.setup(user_config)
  if vim.fn.has("nvim-0.10") == 0 then
    vim.notify("whisk.nvim requires Neovim 0.10 or newer", vim.log.levels.ERROR)
    return
  end

  if initialized then
    M.reset()
  end

  config.reset()
  config.validate(user_config)
  config.update(user_config)

  local performance = require("whisk.performance")
  performance.setup()

  builtin.register_all()
  keymaps.setup()
  lifecycle.setup()

  initialized = true
end

function M.reset()
  keymaps.clear()
  local landed, landing_error = pcall(loop.complete_all)
  traits.clear()
  motions.clear()
  lifecycle.teardown()
  local performance = require("whisk.performance")
  performance.teardown()
  initialized = false
  if not landed then
    error(landing_error, 0)
  end
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
  local performance = require("whisk.performance")
  if performance.is_active() then
    performance.disable()
  else
    performance.enable()
  end
end

return M
