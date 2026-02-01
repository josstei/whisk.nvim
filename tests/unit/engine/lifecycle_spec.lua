local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each, after_each = runner.describe, runner.it, runner.before_each, runner.after_each

describe('engine/lifecycle', function()
  local lifecycle

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    lifecycle = require('luxmotion.engine.lifecycle')
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
