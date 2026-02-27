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

function M.w(context)
  return calculate_via_native("w", context)
end

function M.b(context)
  return calculate_via_native("b", context)
end

function M.e(context)
  return calculate_via_native("e", context)
end

function M.W(context)
  return calculate_via_native("W", context)
end

function M.B(context)
  return calculate_via_native("B", context)
end

function M.E(context)
  return calculate_via_native("E", context)
end

return M
