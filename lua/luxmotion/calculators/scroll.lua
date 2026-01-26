local viewport = require("luxmotion.core.viewport")

local M = {}

local function calculate_topline(target_line, context)
  local win_height = context.viewport.height
  local topline = target_line - math.floor(win_height / 2)
  return math.max(1, math.min(topline, context.buffer.line_count - win_height + 1))
end

function M.ctrl_d(context)
  local scroll_amount = math.floor(context.viewport.height / 2) * context.input.count
  local target_line = math.min(context.cursor.line + scroll_amount, context.buffer.line_count)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.ctrl_u(context)
  local scroll_amount = math.floor(context.viewport.height / 2) * context.input.count
  local target_line = math.max(context.cursor.line - scroll_amount, 1)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.ctrl_f(context)
  local scroll_amount = (context.viewport.height - 2) * context.input.count
  local target_line = math.min(context.cursor.line + scroll_amount, context.buffer.line_count)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.ctrl_b(context)
  local scroll_amount = (context.viewport.height - 2) * context.input.count
  local target_line = math.max(context.cursor.line - scroll_amount, 1)

  return {
    cursor = { line = target_line, col = context.cursor.col },
    viewport = { topline = calculate_topline(target_line, context) },
  }
end

function M.zz(context)
  local win_height = context.viewport.height
  local target_topline = context.cursor.line - math.floor(win_height / 2)
  target_topline = math.max(1, math.min(target_topline, context.buffer.line_count - win_height + 1))

  return {
    cursor = { line = context.cursor.line, col = context.cursor.col },
    viewport = { topline = target_topline },
  }
end

function M.zt(context)
  local target_topline = context.cursor.line

  return {
    cursor = { line = context.cursor.line, col = context.cursor.col },
    viewport = { topline = target_topline },
  }
end

function M.zb(context)
  local win_height = context.viewport.height
  local target_topline = context.cursor.line - win_height + 1
  target_topline = math.max(1, target_topline)

  return {
    cursor = { line = context.cursor.line, col = context.cursor.col },
    viewport = { topline = target_topline },
  }
end

return M
