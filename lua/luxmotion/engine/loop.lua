local traits = require("luxmotion.registry.traits")
local pool = require("luxmotion.engine.pool")
local performance = require("luxmotion.performance")

local M = {}

local frame_queue = {}
local is_running = false

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

local function process_frame()
  local current_time = vim.loop.hrtime()
  performance.record_frame_time()

  for i = #frame_queue, 1, -1 do
    local anim = frame_queue[i]
    local elapsed = current_time - anim.start_time
    local progress = math.min(elapsed / anim.duration_ns, 1.0)
    local eased = anim.easing_fn(progress)

    local interpolated = interpolate_result(anim.context, anim.result, eased)

    for _, trait_id in ipairs(anim.traits) do
      traits.apply_frame(trait_id, anim.context, interpolated, eased)
    end

    if progress >= 1.0 then
      if anim.on_complete then
        anim.on_complete()
      end
      table.remove(frame_queue, i)
      pool.release(anim)
    end
  end

  if #frame_queue > 0 then
    vim.defer_fn(process_frame, performance.get_frame_interval())
  else
    is_running = false
  end
end

function M.get_easing(easing_type)
  return easing_functions[easing_type] or easing_functions.linear
end

function M.start(options)
  local anim = pool.acquire()
  anim.start_time = vim.loop.hrtime()
  anim.duration_ns = options.duration * 1000000
  anim.easing_fn = M.get_easing(options.easing)
  anim.context = options.context
  anim.result = options.result
  anim.traits = options.traits
  anim.on_complete = options.on_complete

  table.insert(frame_queue, anim)

  if not is_running then
    is_running = true
    vim.defer_fn(process_frame, performance.get_frame_interval())
  end
end

function M.stop_all()
  for _, anim in ipairs(frame_queue) do
    pool.release(anim)
  end
  frame_queue = {}
  is_running = false
end

function M.get_active_count()
  return #frame_queue
end

function M.is_running()
  return is_running
end

function M.cancel_for_buffer(bufnr)
end

function M.cancel_for_window(winid)
end

return M
