local Context = {}
Context.__index = Context

function Context.new(bufnr, winid)
  local self = setmetatable({}, Context)

  self.bufnr = bufnr or vim.api.nvim_get_current_buf()
  self.winid = winid or vim.api.nvim_get_current_win()

  self.start = {
    cursor = vim.api.nvim_win_get_cursor(self.winid),
    topline = vim.fn.getwininfo(self.winid)[1].topline,
    line_count = vim.api.nvim_buf_line_count(self.bufnr),
  }

  return self
end

function Context:is_valid()
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    return false, 'buffer_deleted'
  end

  if not vim.api.nvim_win_is_valid(self.winid) then
    return false, 'window_closed'
  end

  if vim.api.nvim_win_get_buf(self.winid) ~= self.bufnr then
    return false, 'buffer_changed'
  end

  return true, nil
end

return Context
