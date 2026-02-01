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

return Context
