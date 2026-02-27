local M = {}

local animation_pool = {}
local pool_size = 0
local MAX_POOL_SIZE = 10

function M.acquire()
  if pool_size > 0 then
    pool_size = pool_size - 1
    return table.remove(animation_pool)
  else
    return {
      start_time = 0,
      duration_ns = 0,
      easing_fn = nil,
      context = nil,
      result = nil,
      traits = nil,
      on_complete = nil,
      on_cancel = nil,
    }
  end
end

function M.release(animation)
  if pool_size < MAX_POOL_SIZE then
    animation.start_time = 0
    animation.duration_ns = 0
    animation.easing_fn = nil
    animation.context = nil
    animation.result = nil
    animation.traits = nil
    animation.on_complete = nil
    animation.on_cancel = nil
    pool_size = pool_size + 1
    table.insert(animation_pool, animation)
  end
end

function M.get_stats()
  return {
    pool_size = pool_size,
    max_pool_size = MAX_POOL_SIZE,
  }
end

function M.clear()
  animation_pool = {}
  pool_size = 0
end

return M
