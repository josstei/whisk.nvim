local M = {}

local state = {
  topline = 1,
  mode = 'n',
  visual_start = { 0, 1, 1, 0 },
  visual_end = { 0, 1, 1, 0 },
  search_pattern = '',
  last_char = '',
}

function M.reset()
  state = {
    topline = 1,
    mode = 'n',
    visual_start = { 0, 1, 1, 0 },
    visual_end = { 0, 1, 1, 0 },
    search_pattern = '',
    last_char = '',
  }
end

function M.get_state()
  return state
end

function M.set_topline(topline)
  state.topline = topline
end

function M.set_mode(mode)
  state.mode = mode
end

function M.set_visual_selection(start_pos, end_pos)
  state.visual_start = start_pos
  state.visual_end = end_pos
end

function M.set_last_char(char)
  state.last_char = char
end

function M.create()
  local api_state = nil

  local function get_api_state()
    if not api_state then
      api_state = require('tests.mocks.vim_api').get_state()
    end
    return api_state
  end

  return {
    line = function(expr)
      if expr == '.' then
        return get_api_state().cursor[1]
      elseif expr == 'w0' then
        return state.topline
      elseif expr == 'w$' then
        return state.topline + get_api_state().window_height - 1
      elseif expr == '$' then
        return #get_api_state().buffer_lines
      elseif type(expr) == 'number' then
        return expr
      end
      return 1
    end,

    col = function(expr)
      if expr == '.' then
        return get_api_state().cursor[2] + 1
      elseif expr == '$' then
        local line = get_api_state().buffer_lines[get_api_state().cursor[1]] or ""
        return #line + 1
      end
      return 1
    end,

    getline = function(lnum)
      return get_api_state().buffer_lines[lnum] or ""
    end,

    mode = function()
      return state.mode
    end,

    getpos = function(mark)
      if mark == "'<" then
        return state.visual_start
      elseif mark == "'>" then
        return state.visual_end
      end
      return { 0, 1, 1, 0 }
    end,

    setpos = function(mark, pos)
      if mark == "'<" then
        state.visual_start = pos
      elseif mark == "'>" then
        state.visual_end = pos
      end
      return 0
    end,

    winrestview = function(view)
      if view.topline then
        state.topline = view.topline
      end
    end,

    winsaveview = function()
      return {
        topline = state.topline,
        lnum = get_api_state().cursor[1],
        col = get_api_state().cursor[2],
        leftcol = 0,
      }
    end,

    getcharstr = function()
      return state.last_char
    end,

    search = function(pattern, flags)
      return 0
    end,

    matchstr = function(str, pattern)
      return ""
    end,

    indent = function(lnum)
      local line = get_api_state().buffer_lines[lnum] or ""
      local indent = line:match("^(%s*)")
      return indent and #indent or 0
    end,

    virtcol = function(expr)
      return get_api_state().cursor[2] + 1
    end,

    screenrow = function()
      return get_api_state().cursor[1] - state.topline + 1
    end,

    screencol = function()
      return get_api_state().cursor[2] + 1
    end,
  }
end

return M
