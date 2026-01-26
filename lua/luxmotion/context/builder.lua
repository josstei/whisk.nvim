local viewport = require("luxmotion.core.viewport")

local M = {}

function M.build(input)
  local cursor_pos = viewport.get_cursor_position()
  local win_height = viewport.get_height()
  local win_width = viewport.get_width()
  local topline = viewport.get_topline()
  local line_count = viewport.get_line_count()

  return {
    cursor = {
      line = cursor_pos[1],
      col = cursor_pos[2],
    },
    viewport = {
      topline = topline,
      height = win_height,
      width = win_width,
    },
    buffer = {
      line_count = line_count,
    },
    input = {
      char = input.char,
      count = input.count or 1,
      direction = input.direction,
    },
  }
end

return M
