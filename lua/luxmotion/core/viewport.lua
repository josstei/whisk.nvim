local M = {}

local viewport_cache = {
  height = nil,
  width = nil,
  topline = nil,
  buf_line_count = nil,
  last_update = 0,
  cache_duration = 50000000,
}

local function update_cache_if_needed()
  local current_time = vim.loop.hrtime()
  if current_time - viewport_cache.last_update > viewport_cache.cache_duration then
    viewport_cache.height = vim.api.nvim_win_get_height(0)
    viewport_cache.width = vim.api.nvim_win_get_width(0)
    viewport_cache.topline = vim.fn.line('w0')
    viewport_cache.buf_line_count = vim.api.nvim_buf_line_count(0)
    viewport_cache.last_update = current_time
  end
end

function M.get_height()
  update_cache_if_needed()
  return viewport_cache.height
end

function M.get_width()
  update_cache_if_needed()
  return viewport_cache.width
end

function M.get_topline()
  update_cache_if_needed()
  return viewport_cache.topline
end

function M.get_cursor_position()
  return vim.api.nvim_win_get_cursor(0)
end

function M.set_cursor_position(line, col)
  local clamped_line = M.clamp_line(line)
  local clamped_col = M.clamp_column(col, clamped_line)
  vim.api.nvim_win_set_cursor(0, {clamped_line, clamped_col})
end

function M.restore_view(topline, line, col)
  vim.fn.winrestview({
    topline = topline,
    lnum = line,
    col = col,
    leftcol = 0
  })
end

function M.get_line_count()
  update_cache_if_needed()
  return viewport_cache.buf_line_count
end

function M.get_line_length(line_num)
  line_num = line_num or vim.fn.line('.')
  local line = vim.fn.getline(line_num)
  return #line
end

function M.clamp_line(line_num)
  return math.max(1, math.min(line_num, M.get_line_count()))
end

function M.clamp_column(col, line_num)
  line_num = line_num or vim.fn.line('.')
  local line_length = M.get_line_length(line_num)
  return math.max(0, math.min(col, math.max(line_length - 1, 0)))
end

function M.invalidate_cache()
  viewport_cache.last_update = 0
end

return M
