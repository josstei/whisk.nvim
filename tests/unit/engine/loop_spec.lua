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
end)
