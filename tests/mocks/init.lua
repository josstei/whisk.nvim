local M = {}

local vim_api = require('tests.mocks.vim_api')
local vim_fn = require('tests.mocks.vim_fn')
local vim_core = require('tests.mocks.vim_core')

local original_vim = nil

function M.setup()
  original_vim = _G.vim

  _G.vim = {
    api = vim_api.create(),
    fn = vim_fn.create(),
    cmd = vim_core.cmd,
    notify = vim_core.notify,
    schedule = vim_core.schedule,
    defer_fn = vim_core.defer_fn,
    keymap = vim_core.keymap,
    deepcopy = vim_core.deepcopy,
    tbl_deep_extend = vim_core.tbl_deep_extend,
    tbl_keys = vim_core.tbl_keys,
    tbl_contains = vim_core.tbl_contains,
    loop = vim_core.loop,
    o = vim_core.options,
    bo = vim_core.buffer_options,
    v = vim_core.v,
    log = { levels = { WARN = 2, ERROR = 3, INFO = 1 } },
  }

  vim_api.reset()
  vim_fn.reset()
  vim_core.reset()
end

function M.teardown()
  if original_vim then
    _G.vim = original_vim
    original_vim = nil
  end
end

function M.get_api_state()
  return vim_api.get_state()
end

function M.get_fn_state()
  return vim_fn.get_state()
end

function M.get_core_state()
  return vim_core.get_state()
end

function M.set_buffer_content(lines)
  vim_api.set_buffer_content(lines)
end

function M.set_cursor(line, col)
  vim_api.set_cursor(line, col)
end

function M.set_window_size(height, width)
  vim_api.set_window_size(height, width)
end

function M.set_topline(topline)
  vim_fn.set_topline(topline)
end

function M.get_cursor()
  return vim_api.get_cursor()
end

function M.get_notifications()
  return vim_core.get_notifications()
end

function M.get_commands()
  return vim_core.get_commands()
end

function M.get_keymaps()
  return vim_core.get_keymaps()
end

function M.get_deleted_keymaps()
  return vim_core.get_deleted_keymaps()
end

function M.get_deferred_calls()
  return vim_core.get_deferred_calls()
end

function M.execute_deferred(index)
  return vim_core.execute_deferred(index)
end

function M.clear_package_cache()
  for name, _ in pairs(package.loaded) do
    if name:match('^luxmotion') then
      package.loaded[name] = nil
    end
  end
end

function M.delete_buffer(bufnr)
  vim_api.delete_buffer(bufnr)
end

function M.close_window(winid)
  vim_api.close_window(winid)
end

function M.set_window_buffer(winid, bufnr)
  vim_api.set_window_buffer(winid, bufnr)
end

function M.get_extmarks(ns_id)
  return vim_api.get_extmarks(ns_id)
end

function M.get_highlights()
  return vim_api.get_highlights()
end

function M.get_namespaces()
  return vim_api.get_namespaces()
end

return M
