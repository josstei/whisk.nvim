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

    motions = require('whisk.registry.motions')
    traits = require('whisk.registry.traits')
    loop = require('whisk.engine.loop')
    orchestrator = require('whisk.engine.orchestrator')

    motions.clear()
    traits.clear()
    loop.complete_all()

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

  it('execute moves the cursor to the target before returning', function()
    local config = require('whisk.config')
    config.update({ cursor = { enabled = true } })

    orchestrator.execute('test_j', { count = 2 })

    assert.equals(mocks.get_cursor()[1], 3)
  end)

  it('execute queues an animation that replays from the start at SafeState', function()
    local config = require('whisk.config')
    config.update({ cursor = { enabled = true } })

    orchestrator.execute('test_j', { count = 2 })
    assert.equals(loop.get_active_count(), 1)
    assert.equals(mocks.get_cursor()[1], 3)

    mocks.trigger_autocmd('SafeState')

    assert.equals(mocks.get_cursor()[1], 1)
    assert.is_true(loop.is_running())
  end)

  it('execute skips the animation while more input is queued', function()
    local config = require('whisk.config')
    config.update({ cursor = { enabled = true } })
    mocks.set_editor_state('mS')

    orchestrator.execute('test_j', { count = 2 })

    assert.equals(mocks.get_cursor()[1], 3)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('execute skips the animation while a macro is replaying', function()
    local config = require('whisk.config')
    config.update({ cursor = { enabled = true } })
    mocks.set_reg_executing('q')

    orchestrator.execute('test_j', { count = 2 })

    assert.equals(mocks.get_cursor()[1], 3)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('execute animates when only unrelated editor state is set', function()
    local config = require('whisk.config')
    config.update({ cursor = { enabled = true } })
    mocks.set_editor_state('S')

    orchestrator.execute('test_j', { count = 2 })

    assert.equals(loop.get_active_count(), 1)
  end)

  it('execute calls calculator with context', function()
    local config = require('whisk.config')
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

  it('execute runs the native motion when the category is disabled', function()
    local config = require('whisk.config')
    config.update({ cursor = { enabled = false } })

    orchestrator.execute('test_j', { count = 1, direction = 'j' })

    assert.table_equals(mocks.get_commands(), { 'normal! j' })
    assert.equals(loop.get_active_count(), 0)
  end)

  it('fallback runs the counted keys immediately with :normal! instead of queueing them', function()
    local motion = motions.get('test_j')
    orchestrator.fallback(motion, { count = 3, direction = 'j' })

    assert.table_equals(mocks.get_commands(), { 'normal! 3j' })
    assert.equals(#mocks.get_api_state().fed_keys, 0)
  end)

  it('fallback appends the find character after the motion key', function()
    orchestrator.fallback({ keys = { 'f' } }, { count = 2, direction = 'f', char = 'x' })

    assert.table_equals(mocks.get_commands(), { 'normal! 2fx' })
  end)

  it('execute handles unknown motion gracefully', function()
    assert.does_not_throw(function()
      orchestrator.execute('nonexistent_motion', {})
    end)
  end)

  it('execute passes count to calculator', function()
    local config = require('whisk.config')
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
    local config = require('whisk.config')
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
    local config = require('whisk.config')
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
    assert.equals(loop.get_active_count(), 0)
  end)

  it('execute finishes a running animation before computing the next motion', function()
    local config = require('whisk.config')
    config.update({ cursor = { enabled = true } })

    orchestrator.execute('test_j', { count = 1 })
    mocks.trigger_autocmd('SafeState')
    assert.equals(mocks.get_cursor()[1], 1)

    orchestrator.execute('test_j', { count = 1 })

    assert.equals(mocks.get_cursor()[1], 3)
    assert.equals(loop.get_active_count(), 1)
  end)

  it('execute detects change in viewport', function()
    local config = require('whisk.config')
    config.update({ scroll = { enabled = true } })

    motions.register({
      id = 'test_view_detect',
      keys = { 's' },
      modes = { 'n' },
      traits = { 'scroll' },
      category = 'scroll',
      calculator = function(_)
        return { viewport = { topline = 50 } }
      end,
    })

    orchestrator.execute('test_view_detect', {})
    assert.equals(loop.get_active_count(), 1)
  end)

  it('execute does not start loop when cursor and viewport unchanged', function()
    local config = require('whisk.config')
    config.update({ scroll = { enabled = true } })

    motions.register({
      id = 'test_view_unchanged',
      keys = { 't' },
      modes = { 'n' },
      traits = { 'scroll' },
      category = 'scroll',
      calculator = function(ctx)
        return {
          cursor = { line = ctx.cursor.line, col = ctx.cursor.col },
          viewport = { topline = ctx.viewport.topline },
        }
      end,
    })

    orchestrator.execute('test_view_unchanged', {})
    assert.equals(loop.get_active_count(), 0)
  end)
end)
