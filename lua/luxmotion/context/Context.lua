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

function Context:get_line_count()
  return vim.api.nvim_buf_line_count(self.bufnr)
end

function Context:get_line_length(line_num)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, line_num - 1, line_num, false)
  if not lines or not lines[1] then
    return 0
  end
  return #lines[1]
end

function Context:clamp_line(line)
  local line_count = self:get_line_count()
  return math.max(1, math.min(line, line_count))
end

function Context:clamp_column(col, line)
  local line_length = self:get_line_length(line)
  local max_col = math.max(line_length - 1, 0)
  return math.max(0, math.min(col, max_col))
end

function Context:clamp_position(line, col)
  local clamped_line = self:clamp_line(line)
  local clamped_col = self:clamp_column(col, clamped_line)
  return clamped_line, clamped_col
end

return Context
