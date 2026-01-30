local viewport = require("luxmotion.core.viewport")

local M = {}

local function get_first_non_blank(line_num)
  local line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""
  local leading_space = line_content:match("^%s*")
  return leading_space and #leading_space or 0
end

local function calculate_topline(target_line, context)
  local win_height = context.viewport.height
  local topline = target_line - math.floor(win_height / 2)
  return math.max(1, math.min(topline, context.buffer.line_count - win_height + 1))
end

function M.gg(context)
  local target_line = context.input.count
  target_line = math.max(1, math.min(target_line, context.buffer.line_count))
  local target_col = get_first_non_blank(target_line)

  return {
    cursor = { line = target_line, col = target_col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.G(context)
  local target_line
  if vim.v.count == 0 then
    target_line = context.buffer.line_count
  else
    target_line = math.max(1, math.min(context.input.count, context.buffer.line_count))
  end
  local target_col = get_first_non_blank(target_line)

  return {
    cursor = { line = target_line, col = target_col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

M["|"] = function(context)
  local target_col = math.max(context.input.count - 1, 0)
  return {
    cursor = { line = context.cursor.line, col = target_col },
  }
end

return M
