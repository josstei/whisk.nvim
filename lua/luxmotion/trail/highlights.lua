local M = {}

local function compute_intensity(index, total)
  if total <= 1 then
    return 1.0
  end
  local t = (index - 1) / (total - 1)
  return (1.0 - t) ^ 1.2
end

function M.parse_hex(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return r, g, b
end

function M.to_hex(r, g, b)
  r = math.max(0, math.min(255, math.floor(r + 0.5)))
  g = math.max(0, math.min(255, math.floor(g + 0.5)))
  b = math.max(0, math.min(255, math.floor(b + 0.5)))
  return string.format('#%02X%02X%02X', r, g, b)
end

function M.blend_hex(fg_hex, bg_hex, ratio)
  local fr, fg, fb = M.parse_hex(fg_hex)
  local br, bg_c, bb = M.parse_hex(bg_hex)
  local r = br + (fr - br) * ratio
  local g = bg_c + (fg - bg_c) * ratio
  local b = bb + (fb - bb) * ratio
  return M.to_hex(r, g, b)
end

function M.get_group_name(index)
  return 'LuxMotionTrail' .. index
end

function M.resolve_color(color_value)
  if color_value ~= "auto" then
    return color_value
  end

  local ok, cursor_hl = pcall(vim.api.nvim_get_hl, 0, { name = 'Cursor' })
  if ok and cursor_hl then
    local bg = cursor_hl.bg
    if bg then
      return M.to_hex(
        math.floor(bg / 65536) % 256,
        math.floor(bg / 256) % 256,
        bg % 256
      )
    end
    local fg = cursor_hl.fg
    if fg then
      return M.to_hex(
        math.floor(fg / 65536) % 256,
        math.floor(fg / 256) % 256,
        fg % 256
      )
    end
  end

  return '#FFFFFF'
end

function M.setup(trail_color, bg_color, segments)
  for i = 1, segments do
    local intensity = compute_intensity(i, segments)
    local blended = M.blend_hex(trail_color, bg_color, intensity)
    vim.api.nvim_set_hl(0, M.get_group_name(i), { bg = blended })
  end
end

function M.teardown()
  for i = 1, 12 do
    pcall(vim.api.nvim_set_hl, 0, M.get_group_name(i), {})
  end
end

return M
