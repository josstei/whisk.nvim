local highlights = require('luxmotion.trail.highlights')

local M = {}

local namespace_id = nil
local positions = {}

function M.get_namespace_id()
  if not namespace_id then
    namespace_id = vim.api.nvim_create_namespace('luxmotion_trail')
  end
  return namespace_id
end

function M.reset()
  positions = {}
end

function M.get_positions()
  return positions
end

function M.push_position(bufnr, result, max_length)
  if not result.cursor then
    return
  end

  local line = result.cursor.line
  local col = result.cursor.col

  if #positions > 0 then
    local last = positions[1]
    if last.line == line and last.col == col then
      return
    end
  end

  table.insert(positions, 1, { line = line, col = col })

  while #positions > max_length do
    table.remove(positions)
  end
end

function M.render(bufnr, segments)
  local ns = M.get_namespace_id()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for i, pos in ipairs(positions) do
    if i > segments then
      break
    end

    local hl_group = highlights.get_group_name(i)
    vim.api.nvim_buf_set_extmark(bufnr, ns, pos.line - 1, pos.col, {
      end_col = pos.col + 1,
      hl_group = hl_group,
    })
  end
end

function M.clear(bufnr)
  local ns = M.get_namespace_id()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  positions = {}
end

return M
