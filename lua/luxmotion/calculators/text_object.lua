local M = {}

local function calculate_via_native(motion_cmd, context)
  local original = { context.cursor.line, context.cursor.col }
  vim.api.nvim_win_set_cursor(0, original)

  local cmd = context.input.count .. motion_cmd
  local success = pcall(vim.cmd, "normal! " .. cmd)

  if not success then
    vim.api.nvim_win_set_cursor(0, original)
    return {
      cursor = { line = context.cursor.line, col = context.cursor.col },
    }
  end

  local target = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, original)

  return {
    cursor = { line = target[1], col = target[2] },
  }
end

M["{"] = function(context)
  return calculate_via_native("{", context)
end

M["}"] = function(context)
  return calculate_via_native("}", context)
end

M["("] = function(context)
  return calculate_via_native("(", context)
end

M[")"] = function(context)
  return calculate_via_native(")", context)
end

M["%"] = function(context)
  return calculate_via_native("%", context)
end

return M
