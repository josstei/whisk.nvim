local M = {}

function M.numbered_lines(count)
  local lines = {}
  for i = 1, count do
    lines[i] = "line " .. i
  end
  return lines
end

function M.fresh_buffer(lines, cursor)
  require("whisk").reset()
  vim.cmd("silent! %bwipeout!")
  vim.cmd("enew!")
  vim.o.scrolloff = 0
  vim.wo.scroll = 0
  vim.wo.foldenable = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, cursor or { 1, 0 })
end

function M.missing_numbered_lines(count)
  local present = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    present[line] = true
  end
  local missing = {}
  for i = 1, count do
    if not present["line " .. i] then
      table.insert(missing, "line " .. i)
    end
  end
  return table.concat(missing, ",")
end

return M
