local M = {}

local intensities = { 0.90, 0.72, 0.54, 0.36, 0.18, 0.06 }

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

function M.setup(trail_color, bg_color, segments)
  for i = 1, segments do
    local intensity = intensities[i] or (1.0 - (i - 1) / segments)
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
