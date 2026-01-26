local viewport = require("luxmotion.core.viewport")

local M = {}

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
  local line_length = viewport.get_line_length(context.cursor.line)
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
  local line_length = viewport.get_line_length(context.cursor.line)
  return {
    cursor = { line = context.cursor.line, col = math.max(line_length - 1, 0) },
  }
end

return M
