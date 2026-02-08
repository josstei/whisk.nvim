local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('engine/orchestrator', function()
  local orchestrator
  local motions
  local traits
  local loop

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "line 1",
      "line 2",
      "line 3",
      "line 4",
      "line 5",
    })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)

    motions = require('luxmotion.registry.motions')
    traits = require('luxmotion.registry.traits')
    loop = require('luxmotion.engine.loop')
    orchestrator = require('luxmotion.engine.orchestrator')

    motions.clear()
    traits.clear()
    loop.stop_all()

    traits.register({
      id = 'cursor',
      apply = function(context, result, progress)
        if result.cursor then
          context:set_cursor(result.cursor.line, result.cursor.col)
        end
      end,
    })

    motions.register({
      id = 'test_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        return {
          cursor = {
            line = ctx.cursor.line + ctx.input.count,
            col = ctx.cursor.col,
          },
        }
      end,
    })
  end)

  it('exports required functions', function()
    assert.is_type(orchestrator.execute, 'function')
    assert.is_type(orchestrator.fallback, 'function')
  end)

  it('execute starts animation for registered motion', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    orchestrator.execute('test_j', { count = 2 })

    assert.is_true(loop.is_running())
  end)

  it('execute calls calculator with context', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    local calculator_called = false
    motions.register({
      id = 'test_calc',
      keys = { 'x' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        calculator_called = true
        assert.is_not_nil(ctx.cursor)
        assert.is_not_nil(ctx.input)
        return { cursor = { line = 1, col = 0 } }
      end,
    })

    orchestrator.execute('test_calc', {})
    assert.is_true(calculator_called)
  end)

  it('execute uses fallback when category disabled', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = false } })

    orchestrator.execute('test_j', { count = 1 })

    local commands = mocks.get_commands()
    assert.greater_than(#commands, 0)
  end)

  it('fallback executes normal command', function()
    local motion = motions.get('test_j')
    orchestrator.fallback(motion, { count = 3 })

    local commands = mocks.get_commands()
    assert.greater_than(#commands, 0)
  end)

  it('execute handles unknown motion gracefully', function()
    assert.does_not_throw(function()
      orchestrator.execute('nonexistent_motion', {})
    end)
  end)

  it('execute passes count to calculator', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    local received_count = nil
    motions.register({
      id = 'test_count',
      keys = { 'y' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        received_count = ctx.input.count
        return { cursor = { line = ctx.cursor.line + ctx.input.count, col = 0 } }
      end,
    })

    orchestrator.execute('test_count', { count = 5 })
    assert.equals(received_count, 5)
  end)

  it('execute passes direction to calculator', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    local received_direction = nil
    motions.register({
      id = 'test_dir',
      keys = { 'z' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        received_direction = ctx.input.direction
        return { cursor = { line = 1, col = 0 } }
      end,
    })

    orchestrator.execute('test_dir', { direction = 'forward' })
    assert.equals(received_direction, 'forward')
  end)

  it('execute does nothing when target equals current', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    motions.register({
      id = 'test_same',
      keys = { 's' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        return { cursor = { line = ctx.cursor.line, col = ctx.cursor.col } }
      end,
    })

    orchestrator.execute('test_same', {})
    assert.is_false(loop.is_running())
  end)

  it('execute marks traits as animating', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    orchestrator.execute('test_j', { count = 1 })
    assert.is_true(traits.is_animating('cursor'))
  end)

  it('execute sets category on context', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    local received_category = nil
    motions.register({
      id = 'test_cat',
      keys = { 'x' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        received_category = ctx.category
        return { cursor = { line = 2, col = 0 } }
      end,
    })

    orchestrator.execute('test_cat', { count = 1 })
    assert.equals(received_category, 'cursor')
  end)

  it('execute calls trait on_start before animation', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    local start_called = false
    traits.clear()
    traits.register({
      id = 'cursor',
      apply = function(context, result, progress)
        if result.cursor then
          context:set_cursor(result.cursor.line, result.cursor.col)
        end
      end,
      on_start = function(ctx) start_called = true end,
    })

    motions.clear()
    motions.register({
      id = 'test_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        return { cursor = { line = ctx.cursor.line + 1, col = ctx.cursor.col } }
      end,
    })

    orchestrator.execute('test_j', { count = 1 })
    assert.is_true(start_called)
  end)

  it('execute sets motion_id on context', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { enabled = true } })

    local received_motion_id = nil
    traits.clear()
    traits.register({
      id = 'cursor',
      apply = function(context, result, progress)
        if result.cursor then
          context:set_cursor(result.cursor.line, result.cursor.col)
        end
      end,
    })

    motions.clear()
    motions.register({
      id = 'test_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function(ctx)
        received_motion_id = ctx.motion_id
        return { cursor = { line = ctx.cursor.line + 1, col = ctx.cursor.col } }
      end,
    })

    orchestrator.execute('test_j', { count = 1 })
    assert.equals(received_motion_id, 'test_j')
  end)
end)
