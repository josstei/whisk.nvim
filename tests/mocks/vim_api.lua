local M = {}

local state = {
  cursor = { 1, 0 },
  window_height = 40,
  window_width = 120,
  buffer_lines = { "line 1", "line 2", "line 3" },
  autocmds = {},
  autocmd_id = 0,
  deleted_buffers = {},
  closed_windows = {},
  window_buffers = {},
  augroups = {},
  augroup_id = 0,
  namespaces = {},
  namespace_id = 0,
  extmarks = {},
  highlights = {},
}

function M.reset()
  state = {
    cursor = { 1, 0 },
    window_height = 40,
    window_width = 120,
    buffer_lines = { "line 1", "line 2", "line 3" },
    autocmds = {},
    autocmd_id = 0,
    deleted_buffers = {},
    closed_windows = {},
    window_buffers = {},
    augroups = {},
    augroup_id = 0,
    namespaces = {},
    namespace_id = 0,
    extmarks = {},
    highlights = {},
  }
end

function M.get_state()
  return state
end

function M.set_buffer_content(lines)
  state.buffer_lines = lines
end

function M.set_cursor(line, col)
  state.cursor = { line, col }
end

function M.get_cursor()
  return { state.cursor[1], state.cursor[2] }
end

function M.set_window_size(height, width)
  state.window_height = height
  state.window_width = width
end

function M.delete_buffer(bufnr)
  state.deleted_buffers[bufnr] = true
end

function M.close_window(winid)
  state.closed_windows[winid] = true
end

function M.set_window_buffer(winid, bufnr)
  state.window_buffers[winid] = bufnr
end

function M.get_extmarks(ns_id)
  return state.extmarks[ns_id] or {}
end

function M.get_highlights()
  return state.highlights
end

function M.get_namespaces()
  return state.namespaces
end

function M.create()
  return {
    nvim_win_get_height = function(winid)
      return state.window_height
    end,

    nvim_win_get_width = function(winid)
      return state.window_width
    end,

    nvim_win_get_cursor = function(winid)
      return { state.cursor[1], state.cursor[2] }
    end,

    nvim_win_set_cursor = function(winid, pos)
      local line = math.max(1, math.min(pos[1], #state.buffer_lines))
      local line_len = #(state.buffer_lines[line] or "")
      local col = math.max(0, math.min(pos[2], math.max(0, line_len - 1)))
      state.cursor = { line, col }
    end,

    nvim_buf_get_lines = function(bufnr, start_line, end_line, strict)
      local result = {}
      local actual_end = end_line == -1 and #state.buffer_lines or end_line
      for i = start_line + 1, actual_end do
        table.insert(result, state.buffer_lines[i] or "")
      end
      return result
    end,

    nvim_buf_line_count = function(bufnr)
      return #state.buffer_lines
    end,

    nvim_get_current_buf = function()
      return 1
    end,

    nvim_get_current_win = function()
      return 1000
    end,

    nvim_create_autocmd = function(events, opts)
      state.autocmd_id = state.autocmd_id + 1
      table.insert(state.autocmds, {
        id = state.autocmd_id,
        events = events,
        opts = opts,
      })
      return state.autocmd_id
    end,

    nvim_del_autocmd = function(id)
      for i, autocmd in ipairs(state.autocmds) do
        if autocmd.id == id then
          table.remove(state.autocmds, i)
          return
        end
      end
    end,

    nvim_create_augroup = function(name, opts)
      return name
    end,

    nvim_buf_get_option = function(bufnr, option)
      if option == "filetype" then
        return "lua"
      end
      return nil
    end,

    nvim_get_option = function(option)
      if option == "scrolloff" then
        return 5
      end
      return nil
    end,

    nvim_get_current_line = function()
      return state.buffer_lines[state.cursor[1]] or ""
    end,

    nvim_buf_is_valid = function(bufnr)
      return not state.deleted_buffers[bufnr]
    end,

    nvim_win_is_valid = function(winid)
      return not state.closed_windows[winid]
    end,

    nvim_win_get_buf = function(winid)
      return state.window_buffers[winid] or 1
    end,

    nvim_win_call = function(winid, func)
      return func()
    end,

    nvim_del_augroup_by_id = function(id)
      state.augroups[id] = nil
      for i = #state.autocmds, 1, -1 do
        if state.autocmds[i].group == id then
          table.remove(state.autocmds, i)
        end
      end
    end,

    nvim_create_namespace = function(name)
      if state.namespaces[name] then
        return state.namespaces[name]
      end
      state.namespace_id = state.namespace_id + 1
      state.namespaces[name] = state.namespace_id
      return state.namespace_id
    end,

    nvim_buf_set_extmark = function(bufnr, ns_id, line, col, opts)
      if not state.extmarks[ns_id] then
        state.extmarks[ns_id] = {}
      end
      local mark = { bufnr = bufnr, line = line, col = col, opts = opts or {} }
      table.insert(state.extmarks[ns_id], mark)
      return #state.extmarks[ns_id]
    end,

    nvim_buf_clear_namespace = function(bufnr, ns_id, line_start, line_end)
      if state.extmarks[ns_id] then
        state.extmarks[ns_id] = {}
      end
    end,

    nvim_set_hl = function(ns, name, val)
      state.highlights[name] = { ns = ns, val = val }
    end,

    nvim_get_hl = function(ns, opts)
      local name = opts and opts.name
      if name and state.highlights[name] then
        return state.highlights[name].val or {}
      end
      return {}
    end,
  }
end

return M
