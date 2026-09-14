local M = {}

local autocmd_group = nil
local input_namespace = nil

function M.setup()
  local loop = require('whisk.engine.loop')
  input_namespace = input_namespace or vim.api.nvim_create_namespace('whisk.input')
  -- on_key runs before the next command is processed, including macro/mapping input.
  -- An edit must see the motion's final position, never an intermediate frame.
  vim.on_key(function()
    if loop.get_active_count() > 0 then loop.complete_all() end
  end, input_namespace)

  autocmd_group = vim.api.nvim_create_augroup('WhiskLifecycle', { clear = true })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = autocmd_group,
    callback = function(args)
      loop.cancel_for_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = autocmd_group,
    callback = function(args)
      local winid = tonumber(args.match)
      if winid then
        loop.cancel_for_window(winid)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    group = autocmd_group,
    callback = function(args)
      loop.cancel_for_buffer(args.buf)
    end,
  })
end

function M.teardown()
  if input_namespace then
    vim.on_key(nil, input_namespace)
  end
  if autocmd_group then
    vim.api.nvim_del_augroup_by_id(autocmd_group)
    autocmd_group = nil
  end
end

function M.is_active()
  return autocmd_group ~= nil
end

return M
