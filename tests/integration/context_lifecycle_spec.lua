local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('Integration: Context + Lifecycle', function()
  local whisk
  local loop
  local builder

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "line 1", "line 2", "line 3", "line 4", "line 5",
      "line 6", "line 7", "line 8", "line 9", "line 10",
    })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)

    whisk = require('whisk')
    loop = require('whisk.engine.loop')
    builder = require('whisk.context.builder')

    whisk.setup({})
  end)

  it('animation completes successfully with valid context', function()
    local ctx = builder.build({})
    local completed = false

    loop.start({
      context = ctx,
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      duration = 10,
      easing = 'linear',
      on_complete = function()
        completed = true
      end,
    })

    for _ = 1, 10 do
      loop.force_process_frame()
    end

    assert.is_true(completed)
  end)

  it('animation cancels when buffer is deleted mid-animation', function()
    local ctx = builder.build({})
    local cancelled = false
    local cancel_reason = nil

    loop.start({
      context = ctx,
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      duration = 100,
      easing = 'linear',
      on_cancel = function(reason)
        cancelled = true
        cancel_reason = reason
      end,
    })

    assert.equals(loop.get_active_count(), 1)

    mocks.delete_buffer(ctx.bufnr)
    loop.force_process_frame()

    assert.is_true(cancelled)
    assert.equals(cancel_reason, 'buffer_deleted')
    assert.equals(loop.get_active_count(), 0)
  end)

  it('cursor is clamped when buffer shrinks during animation', function()
    local ctx = builder.build({})

    loop.start({
      context = ctx,
      result = { cursor = { line = 10, col = 0 } },
      traits = { 'cursor' },
      duration = 10,
      easing = 'linear',
    })

    mocks.set_buffer_content({ "line 1", "line 2", "line 3" })

    for _ = 1, 10 do
      loop.force_process_frame()
    end

    local cursor = mocks.get_cursor()
    assert.equals(cursor[1], 3)
  end)
end)
