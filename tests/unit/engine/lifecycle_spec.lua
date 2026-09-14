local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each, after_each = runner.describe, runner.it, runner.before_each, runner.after_each

describe('engine/lifecycle', function()
  local lifecycle

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    lifecycle = require('whisk.engine.lifecycle')
  end)

  after_each(function()
    lifecycle.teardown()
  end)

  it('setup() creates autocmd group', function()
    lifecycle.setup()
    local state = mocks.get_api_state()
    assert.greater_than(#state.autocmds, 0)
  end)

  it('setup() registers BufDelete autocmd', function()
    lifecycle.setup()
    local state = mocks.get_api_state()
    local found = false
    for _, autocmd in ipairs(state.autocmds) do
      if type(autocmd.events) == 'table' then
        for _, event in ipairs(autocmd.events) do
          if event == 'BufDelete' then
            found = true
            break
          end
        end
      elseif autocmd.events == 'BufDelete' then
        found = true
      end
      if found then break end
    end
    assert.is_true(found)
  end)

  it('setup() registers WinClosed autocmd', function()
    lifecycle.setup()
    local state = mocks.get_api_state()
    local found = false
    for _, autocmd in ipairs(state.autocmds) do
      if type(autocmd.events) == 'table' then
        for _, event in ipairs(autocmd.events) do
          if event == 'WinClosed' then
            found = true
            break
          end
        end
      elseif autocmd.events == 'WinClosed' then
        found = true
      end
      if found then break end
    end
    assert.is_true(found)
  end)

  it('setup() registers BufLeave autocmd', function()
    lifecycle.setup()
    local state = mocks.get_api_state()
    local found = false
    for _, autocmd in ipairs(state.autocmds) do
      if type(autocmd.events) == 'table' then
        for _, event in ipairs(autocmd.events) do
          if event == 'BufLeave' then
            found = true
            break
          end
        end
      elseif autocmd.events == 'BufLeave' then
        found = true
      end
      if found then break end
    end
    assert.is_true(found)
  end)

  it('leaving a buffer lands its running animation on the committed position', function()
    mocks.set_buffer_content({ 'l1', 'l2', 'l3', 'l4', 'l5', 'l6', 'l7', 'l8', 'l9', 'l10' })
    mocks.set_cursor(1, 0)
    local traits = require('whisk.registry.traits')
    traits.clear()
    require('whisk.registry.builtin').register_traits()
    local loop = require('whisk.engine.loop')
    local context = require('whisk.context.builder').build({})
    local result = { cursor = { line = 10, col = 0 } }
    traits.apply_frame('cursor', context, result, 1.0)
    loop.start({ context = context, result = result, traits = { 'cursor' }, duration = 1000, easing = 'linear' })
    mocks.trigger_autocmd('SafeState')
    mocks.execute_deferred(1)
    assert.is_true(mocks.get_cursor()[1] < 10)

    lifecycle.setup()
    mocks.trigger_autocmd('BufLeave', { buf = 1 })

    assert.equals(mocks.get_cursor()[1], 10)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('teardown() removes autocmds', function()
    lifecycle.setup()
    lifecycle.teardown()
    assert.is_false(lifecycle.is_active())
  end)

  it('is_active() returns true after setup', function()
    lifecycle.setup()
    assert.is_true(lifecycle.is_active())
  end)

  it('is_active() returns false before setup', function()
    assert.is_false(lifecycle.is_active())
  end)
end)
