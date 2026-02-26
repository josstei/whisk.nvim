local M = {}

local autocmd_group = nil

function M.setup()
  local loop = require('whisk.engine.loop')

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
  if autocmd_group then
    vim.api.nvim_del_augroup_by_id(autocmd_group)
    autocmd_group = nil
  end
end

function M.is_active()
  return autocmd_group ~= nil
end

return M
