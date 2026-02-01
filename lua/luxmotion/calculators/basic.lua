local M = {}

local function get_line_length(context, line_num)
  if context.get_line_length then
    return context:get_line_length(line_num)
  end
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)
  if not lines or not lines[1] then
    return 0
  end
  return #lines[1]
end

function M.h(context)
  local target_col = math.max(context.cursor.col - context.input.count, 0)
  return {
    cursor = { line = context.cursor.line, col = target_col },
  }
end

function M.j(context)
  local target_line = math.min(context.cursor.line + context.input.count, context.buffer.line_count)
  return {
    cursor = { line = target_line, col = context.cursor.col },
  }
end

function M.k(context)
  local target_line = math.max(context.cursor.line - context.input.count, 1)
  return {
    cursor = { line = target_line, col = context.cursor.col },
  }
end

function M.l(context)
  local line_length = get_line_length(context, context.cursor.line)
  local target_col = math.min(context.cursor.col + context.input.count, math.max(line_length - 1, 0))
  return {
    cursor = { line = context.cursor.line, col = target_col },
  }
end

M["0"] = function(context)
  return {
    cursor = { line = context.cursor.line, col = 0 },
  }
end

M["$"] = function(context)
  local line_length = get_line_length(context, context.cursor.line)
  return {
    cursor = { line = context.cursor.line, col = math.max(line_length - 1, 0) },
  }
end

return M
