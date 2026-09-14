local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('Integration: Context + Lifecycle', function()
  local whisk
  local loop
  local builder
  local traits

  local function commit_and_start(target_line, duration)
    local ctx = builder.build({})
    local result = { cursor = { line = target_line, col = 0 } }
    traits.apply_frame('cursor', ctx, result, 1.0)
    loop.start({
      context = ctx,
      result = result,
      traits = { 'cursor' },
      duration = duration,
      easing = 'linear',
    })
    return ctx
  end

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
    traits = require('whisk.registry.traits')

    whisk.setup({})
  end)

  it('a replayed animation completes on the committed position', function()
    commit_and_start(5, 10)
    mocks.trigger_autocmd('SafeState')

    for _ = 1, 10 do
      loop.force_process_frame()
    end

    assert.equals(mocks.get_cursor()[1], 5)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('an animation is dropped when its buffer is deleted mid-animation', function()
    local ctx = commit_and_start(5, 1000)
    mocks.trigger_autocmd('SafeState')
    assert.equals(loop.get_active_count(), 1)

    mocks.delete_buffer(ctx.bufnr)
    loop.force_process_frame()

    assert.equals(loop.get_active_count(), 0)
  end)

  it('the cursor is clamped when the buffer shrinks during an animation', function()
    commit_and_start(10, 10)
    mocks.trigger_autocmd('SafeState')

    mocks.set_buffer_content({ "line 1", "line 2", "line 3" })

    for _ = 1, 10 do
      loop.force_process_frame()
    end

    assert.equals(mocks.get_cursor()[1], 3)
  end)
end)
