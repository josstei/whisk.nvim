local traits = require("whisk.registry.traits")
local pool = require("whisk.engine.pool")
local performance = require("whisk.performance")

local M = {}

local queue = {}
local tick_pending = false
local key_namespace = nil
local safe_state_autocmd = nil

local easing_functions = {
  linear = function(t) return t end,
  ["ease-in"] = function(t) return t * t end,
  ["ease-out"] = function(t) return 1 - (1 - t) * (1 - t) end,
  ["ease-in-out"] = function(t)
    if t < 0.5 then
      return 2 * t * t
    else
      return 1 - 2 * (1 - t) * (1 - t)
    end
  end,
}

local function lerp(start_val, end_val, progress)
  return start_val + (end_val - start_val) * progress
end

local function interpolate_result(context, result, progress)
  local interpolated = { cursor = {}, viewport = {} }

  if result.cursor then
    interpolated.cursor.line = math.floor(lerp(context.cursor.line, result.cursor.line, progress) + 0.5)
    interpolated.cursor.col = math.floor(lerp(context.cursor.col, result.cursor.col, progress) + 0.5)
  end

  if result.viewport and result.viewport.topline then
    interpolated.viewport.topline = math.floor(lerp(context.viewport.topline, result.viewport.topline, progress) + 0.5)
  end

  return interpolated
end

local function apply_frame(anim, progress)
  local eased = anim.easing_fn(progress)
  local frame = interpolate_result(anim.context, anim.result, eased)
  for _, trait_id in ipairs(anim.traits) do
    traits.apply_frame(trait_id, anim.context, frame, eased)
  end
end

local function report(err)
  vim.schedule(function()
    vim.notify("whisk: " .. tostring(err), vim.log.levels.ERROR)
  end)
end

local function land(anim)
  local ok, err = pcall(function()
    for _, trait_id in ipairs(anim.traits) do
      traits.apply_frame(trait_id, anim.context, anim.result, 1.0)
    end
  end)

  local view = anim.landing_view
  if view then
    vim.api.nvim_win_call(anim.context.winid, function()
      vim.fn.winrestview(view)
    end)
  end

  if not ok then
    error(err, 0)
  end
end

local function still_committed(anim)
  local context = anim.context
  local cursor = vim.api.nvim_win_get_cursor(context.winid)
  return cursor[1] == anim.committed.cursor[1]
    and cursor[2] == anim.committed.cursor[2]
    and vim.api.nvim_buf_get_changedtick(context.bufnr) == anim.committed.tick
end

local function release_hooks()
  if key_namespace then
    vim.on_key(nil, key_namespace)
    key_namespace = nil
  end
  if safe_state_autocmd then
    pcall(vim.api.nvim_del_autocmd, safe_state_autocmd)
    safe_state_autocmd = nil
  end
end

local function discard(index)
  pool.release(table.remove(queue, index))
  if #queue == 0 then
    release_hooks()
  end
end

local function finish_where(predicate)
  local kept = {}
  local finishing = {}
  for _, anim in ipairs(queue) do
    if predicate(anim) then
      table.insert(finishing, anim)
    else
      table.insert(kept, anim)
    end
  end

  queue = kept
  if #queue == 0 then
    release_hooks()
  end

  local first_error = nil
  for _, anim in ipairs(finishing) do
    if anim.phase == "running" and anim.context:is_valid() then
      local ok, err = pcall(land, anim)
      if not ok and not first_error then
        first_error = err
      end
    end
    pool.release(anim)
  end

  if first_error then
    error(first_error, 0)
  end
end

local schedule_tick

local function run_frame()
  local now = vim.loop.hrtime()
  performance.record_frame_time()
  local running = false
  local first_error = nil

  for i = #queue, 1, -1 do
    local anim = queue[i]
    if anim.phase == "running" then
      if not anim.context:is_valid() then
        discard(i)
      else
        local progress = 1.0
        if anim.duration_ns > 0 then
          progress = math.min((now - anim.start_time) / anim.duration_ns, 1.0)
        end
        if progress >= 1.0 then
          local ok, err = pcall(land, anim)
          if not ok and not first_error then
            first_error = err
          end
          discard(i)
        else
          apply_frame(anim, progress)
          running = true
        end
      end
    end
  end

  return running, first_error
end

local function advance()
  local running, err = run_frame()
  if running then
    schedule_tick()
  end
  if err then
    report(err)
  end
end

local function on_tick()
  tick_pending = false
  advance()
end

schedule_tick = function()
  if tick_pending then
    return
  end
  tick_pending = true
  vim.defer_fn(on_tick, performance.get_frame_interval())
end

local function begin_pending()
  local started = false
  for i = #queue, 1, -1 do
    local anim = queue[i]
    if anim.phase == "pending" then
      if anim.context:is_valid() and still_committed(anim) then
        anim.landing_view = vim.api.nvim_win_call(anim.context.winid, vim.fn.winsaveview)
        anim.context:restore_start()
        anim.phase = "running"
        anim.start_time = vim.loop.hrtime()
        started = true
      else
        discard(i)
      end
    end
  end

  if started then
    schedule_tick()
  end
end

local function guarded(fn)
  return function()
    local ok, err = pcall(fn)
    if not ok then
      report(err)
    end
  end
end

local function attach_hooks()
  if not key_namespace then
    key_namespace = vim.api.nvim_create_namespace("whisk.engine.loop")
    vim.on_key(guarded(M.complete_all), key_namespace)
  end

  if not safe_state_autocmd then
    local begin = guarded(begin_pending)
    safe_state_autocmd = vim.api.nvim_create_autocmd("SafeState", {
      once = true,
      callback = function()
        safe_state_autocmd = nil
        begin()
      end,
    })
  end
end

function M.get_easing(easing_type)
  return easing_functions[easing_type] or easing_functions.linear
end

function M.start(options)
  local context = options.context
  local anim = pool.acquire()
  anim.phase = "pending"
  anim.start_time = 0
  anim.duration_ns = (options.duration or 0) * 1000000
  anim.easing_fn = M.get_easing(options.easing)
  anim.context = context
  anim.result = options.result
  anim.traits = options.traits or {}
  anim.committed = {
    cursor = vim.api.nvim_win_get_cursor(context.winid),
    tick = vim.api.nvim_buf_get_changedtick(context.bufnr),
  }

  table.insert(queue, anim)
  attach_hooks()
end

function M.complete_all()
  finish_where(function()
    return true
  end)
end

function M.complete_for_buffer(bufnr)
  finish_where(function(anim)
    return anim.context.bufnr == bufnr
  end)
end

function M.complete_for_window(winid)
  finish_where(function(anim)
    return anim.context.winid == winid
  end)
end

function M.get_active_count()
  return #queue
end

function M.is_running()
  return tick_pending
end

function M.force_process_frame()
  advance()
end

return M
