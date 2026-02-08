local M = {}

M.id = "distance"

function M.create(thresholds)
  local min_lines = thresholds.min_lines
  local min_cols = thresholds.min_cols

  return {
    id = "distance",
    should_trail = function(context, result)
      if not result.cursor then
        return false
      end
      local delta_line = math.abs(result.cursor.line - context.cursor.line)
      local delta_col = math.abs(result.cursor.col - context.cursor.col)
      return delta_line >= min_lines or delta_col >= min_cols
    end,
  }
end

return M
