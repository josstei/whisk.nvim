local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each, after_each = runner.describe, runner.it, runner.before_each, runner.after_each

describe('engine/loop', function()
  local loop

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    loop = require('luxmotion.engine.loop')
    loop.stop_all()
  end)

  after_each(function()
    loop.stop_all()
  end)

  it('exports all required functions', function()
    assert.is_type(loop.start, 'function')
    assert.is_type(loop.stop_all, 'function')
    assert.is_type(loop.complete_all, 'function')
    assert.is_type(loop.get_easing, 'function')
    assert.is_type(loop.get_active_count, 'function')
    assert.is_type(loop.is_running, 'function')
  end)

  it('is_running returns false initially', function()
    assert.is_false(loop.is_running())
  end)

  it('get_active_count returns 0 initially', function()
    assert.equals(loop.get_active_count(), 0)
  end)

  it('get_easing returns function for linear', function()
    local fn = loop.get_easing('linear')
    assert.is_type(fn, 'function')
    assert.equals(fn(0), 0)
    assert.equals(fn(0.5), 0.5)
    assert.equals(fn(1), 1)
  end)

  it('get_easing returns function for ease-in', function()
    local fn = loop.get_easing('ease-in')
    assert.is_type(fn, 'function')
    assert.equals(fn(0), 0)
    assert.equals(fn(1), 1)
    assert.less_than(fn(0.5), 0.5)
  end)

  it('get_easing returns function for ease-out', function()
    local fn = loop.get_easing('ease-out')
    assert.is_type(fn, 'function')
    assert.equals(fn(0), 0)
    assert.equals(fn(1), 1)
    assert.greater_than(fn(0.5), 0.5)
  end)

  it('get_easing returns function for ease-in-out', function()
    local fn = loop.get_easing('ease-in-out')
    assert.is_type(fn, 'function')
    assert.equals(fn(0), 0)
    assert.equals(fn(1), 1)
    assert.equals(fn(0.5), 0.5)
  end)

  it('get_easing returns linear for unknown type', function()
    local fn = loop.get_easing('unknown')
    assert.is_type(fn, 'function')
    assert.equals(fn(0.5), 0.5)
  end)

  it('get_easing returns linear for nil', function()
    local fn = loop.get_easing(nil)
    assert.is_type(fn, 'function')
    assert.equals(fn(0.5), 0.5)
  end)

  it('start schedules animation', function()
    local completed = false
    loop.start({
      duration = 100,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_complete = function()
        completed = true
      end,
    })

    assert.is_true(loop.is_running())
    assert.greater_than(loop.get_active_count(), 0)
  end)

  it('start uses defer_fn for scheduling', function()
    loop.start({
      duration = 100,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_complete = function() end,
    })

    local deferred = mocks.get_deferred_calls()
    assert.greater_than(#deferred, 0)
  end)

  it('stop_all clears active animations', function()
    loop.start({
      duration = 100,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_complete = function() end,
    })

    loop.stop_all()
    assert.is_false(loop.is_running())
    assert.equals(loop.get_active_count(), 0)
  end)

  it('multiple starts are tracked', function()
    loop.start({
      duration = 100,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_complete = function() end,
    })

    loop.start({
      duration = 100,
      easing = 'linear',
      context = { viewport = { topline = 1 } },
      result = { viewport = { topline = 10 } },
      traits = { 'scroll' },
      on_complete = function() end,
    })

    assert.greater_or_equal(loop.get_active_count(), 1)
  end)

  it('easing ease-in is quadratic', function()
    local fn = loop.get_easing('ease-in')
    assert.equals(fn(0.5), 0.25)
  end)

  it('easing ease-out is inverse quadratic', function()
    local fn = loop.get_easing('ease-out')
    assert.equals(fn(0.5), 0.75)
  end)

  it('easing ease-in-out is smooth', function()
    local fn = loop.get_easing('ease-in-out')
    assert.less_than(fn(0.25), 0.25)
    assert.greater_than(fn(0.75), 0.75)
  end)

  it('start with missing options does not crash', function()
    assert.does_not_throw(function()
      loop.start({
        duration = 100,
        context = {},
        result = {},
        traits = {},
      })
    end)
  end)

  it('start with zero duration completes immediately', function()
    local completed = false
    loop.start({
      duration = 0,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_complete = function()
        completed = true
      end,
    })
  end)

  it('exports complete_all function', function()
    assert.is_type(loop.complete_all, 'function')
  end)

  it('complete_all snaps animations to final position', function()
    local traits = require('luxmotion.registry.traits')
    traits.register({
      id = 'cursor',
      apply = function(context, result, progress)
        if result.cursor then
          mocks.set_cursor(result.cursor.line, result.cursor.col)
        end
      end,
    })

    loop.start({
      duration = 150,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_complete = function() end,
    })

    assert.is_true(loop.is_running())
    loop.complete_all()
    assert.is_false(loop.is_running())
    assert.equals(loop.get_active_count(), 0)

    local cursor = mocks.get_cursor()
    assert.equals(cursor[1], 5)
    assert.equals(cursor[2], 0)
  end)

  it('complete_all calls on_complete callback', function()
    local completed = false

    loop.start({
      duration = 150,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 3, col = 0 } },
      traits = {},
      on_complete = function()
        completed = true
      end,
    })

    loop.complete_all()
    assert.is_true(completed)
  end)

  it('complete_all does not call on_cancel callback', function()
    local cancelled = false

    loop.start({
      duration = 150,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 3, col = 0 } },
      traits = {},
      on_complete = function() end,
      on_cancel = function()
        cancelled = true
      end,
    })

    loop.complete_all()
    assert.is_false(cancelled)
  end)

  it('complete_all on empty queue does not crash', function()
    assert.does_not_throw(function()
      loop.complete_all()
    end)
    assert.is_false(loop.is_running())
    assert.equals(loop.get_active_count(), 0)
  end)

  it('complete_all processes all queued animations', function()
    local call_count = 0

    loop.start({
      duration = 150,
      easing = 'linear',
      context = { cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = {},
      on_complete = function() call_count = call_count + 1 end,
    })

    loop.start({
      duration = 150,
      easing = 'linear',
      context = { viewport = { topline = 1 } },
      result = { viewport = { topline = 10 } },
      traits = {},
      on_complete = function() call_count = call_count + 1 end,
    })

    assert.equals(loop.get_active_count(), 2)
    loop.complete_all()
    assert.equals(call_count, 2)
    assert.equals(loop.get_active_count(), 0)
    assert.is_false(loop.is_running())
  end)

  it('exports cancel_for_buffer function', function()
    assert.is_type(loop.cancel_for_buffer, 'function')
  end)

  it('exports cancel_for_window function', function()
    assert.is_type(loop.cancel_for_window, 'function')
  end)

  it('exports force_process_frame function', function()
    assert.is_type(loop.force_process_frame, 'function')
  end)

  it('cancel_for_buffer removes animations for specified buffer', function()
    loop.start({
      duration = 100,
      easing = 'linear',
      context = { bufnr = 1, winid = 1000, cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
    })

    loop.start({
      duration = 100,
      easing = 'linear',
      context = { bufnr = 2, winid = 1001, cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
    })

    assert.equals(loop.get_active_count(), 2)
    loop.cancel_for_buffer(1)
    assert.equals(loop.get_active_count(), 1)
  end)

  it('cancel_for_window removes animations for specified window', function()
    loop.start({
      duration = 100,
      easing = 'linear',
      context = { bufnr = 1, winid = 1000, cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
    })

    loop.start({
      duration = 100,
      easing = 'linear',
      context = { bufnr = 1, winid = 1001, cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
    })

    assert.equals(loop.get_active_count(), 2)
    loop.cancel_for_window(1000)
    assert.equals(loop.get_active_count(), 1)
  end)

  it('cancel_for_buffer calls on_cancel callback', function()
    local cancelled = false
    local cancel_reason = nil

    loop.start({
      duration = 100,
      easing = 'linear',
      context = { bufnr = 1, winid = 1000, cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_cancel = function(reason)
        cancelled = true
        cancel_reason = reason
      end,
    })

    loop.cancel_for_buffer(1)
    assert.is_true(cancelled)
    assert.equals(cancel_reason, 'buffer_invalidated')
  end)

  it('cancel_for_window calls on_cancel callback', function()
    local cancelled = false
    local cancel_reason = nil

    loop.start({
      duration = 100,
      easing = 'linear',
      context = { bufnr = 1, winid = 1000, cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
      on_cancel = function(reason)
        cancelled = true
        cancel_reason = reason
      end,
    })

    loop.cancel_for_window(1000)
    assert.is_true(cancelled)
    assert.equals(cancel_reason, 'window_invalidated')
  end)

  it('cancel_for_buffer sets is_running to false when no animations remain', function()
    loop.start({
      duration = 100,
      easing = 'linear',
      context = { bufnr = 1, winid = 1000, cursor = { line = 1, col = 0 } },
      result = { cursor = { line = 5, col = 0 } },
      traits = { 'cursor' },
    })

    assert.is_true(loop.is_running())
    loop.cancel_for_buffer(1)
    assert.is_false(loop.is_running())
  end)
end)
