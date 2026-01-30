local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each, after_each = runner.describe, runner.it, runner.before_each, runner.after_each

describe('init (main module)', function()
  local luxmotion

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({ "line 1", "line 2", "line 3" })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    luxmotion = require('luxmotion')
  end)

  after_each(function()
    if luxmotion and luxmotion.reset then
      luxmotion.reset()
    end
  end)

  it('exports setup function', function()
    assert.is_type(luxmotion.setup, 'function')
  end)

  it('exports enable/disable functions', function()
    assert.is_type(luxmotion.enable, 'function')
    assert.is_type(luxmotion.disable, 'function')
    assert.is_type(luxmotion.toggle, 'function')
  end)

  it('exports cursor enable/disable functions', function()
    assert.is_type(luxmotion.enable_cursor, 'function')
    assert.is_type(luxmotion.disable_cursor, 'function')
  end)

  it('exports scroll enable/disable functions', function()
    assert.is_type(luxmotion.enable_scroll, 'function')
    assert.is_type(luxmotion.disable_scroll, 'function')
  end)

  it('exports toggle_performance function', function()
    assert.is_type(luxmotion.toggle_performance, 'function')
  end)

  it('exports reset function', function()
    assert.is_type(luxmotion.reset, 'function')
  end)

  it('setup with no config works', function()
    assert.does_not_throw(function()
      luxmotion.setup()
    end)
  end)

  it('setup with empty config works', function()
    assert.does_not_throw(function()
      luxmotion.setup({})
    end)
  end)

  it('setup with partial config works', function()
    assert.does_not_throw(function()
      luxmotion.setup({
        cursor = { duration = 100 },
      })
    end)
  end)

  it('setup with full config works', function()
    assert.does_not_throw(function()
      luxmotion.setup({
        cursor = { duration = 200, easing = 'linear', enabled = true },
        scroll = { duration = 300, easing = 'ease-in', enabled = false },
        keymaps = { cursor = true, scroll = false },
        performance = { enabled = false },
      })
    end)
  end)

  it('setup creates keymaps', function()
    luxmotion.setup()
    local keymaps = mocks.get_keymaps()
    local count = 0
    for _ in pairs(keymaps) do count = count + 1 end
    assert.greater_than(count, 0)
  end)

  it('enable enables both cursor and scroll', function()
    luxmotion.setup()
    luxmotion.disable()
    luxmotion.enable()

    local config = require('luxmotion.config')
    assert.is_true(config.get_cursor().enabled)
    assert.is_true(config.get_scroll().enabled)
  end)

  it('disable disables both cursor and scroll', function()
    luxmotion.setup()
    luxmotion.disable()

    local config = require('luxmotion.config')
    assert.is_false(config.get_cursor().enabled)
    assert.is_false(config.get_scroll().enabled)
  end)

  it('toggle toggles both cursor and scroll', function()
    luxmotion.setup()
    local config = require('luxmotion.config')

    local initial_cursor = config.get_cursor().enabled
    luxmotion.toggle()
    assert.equals(config.get_cursor().enabled, not initial_cursor)
  end)

  it('enable_cursor only enables cursor', function()
    luxmotion.setup()
    luxmotion.disable()
    luxmotion.enable_cursor()

    local config = require('luxmotion.config')
    assert.is_true(config.get_cursor().enabled)
    assert.is_false(config.get_scroll().enabled)
  end)

  it('disable_cursor only disables cursor', function()
    luxmotion.setup()
    luxmotion.disable_cursor()

    local config = require('luxmotion.config')
    assert.is_false(config.get_cursor().enabled)
    assert.is_true(config.get_scroll().enabled)
  end)

  it('enable_scroll only enables scroll', function()
    luxmotion.setup()
    luxmotion.disable()
    luxmotion.enable_scroll()

    local config = require('luxmotion.config')
    assert.is_false(config.get_cursor().enabled)
    assert.is_true(config.get_scroll().enabled)
  end)

  it('disable_scroll only disables scroll', function()
    luxmotion.setup()
    luxmotion.disable_scroll()

    local config = require('luxmotion.config')
    assert.is_true(config.get_cursor().enabled)
    assert.is_false(config.get_scroll().enabled)
  end)

  it('toggle_performance toggles performance mode', function()
    luxmotion.setup()
    local performance = require('luxmotion.performance')

    local initial = performance.is_active()
    luxmotion.toggle_performance()
    assert.equals(performance.is_active(), not initial)
  end)

  it('reset clears all state', function()
    luxmotion.setup()
    assert.does_not_throw(function()
      luxmotion.reset()
    end)
  end)

  it('setup applies user config', function()
    luxmotion.setup({
      cursor = { duration = 999 },
    })

    local config = require('luxmotion.config')
    assert.equals(config.get_cursor().duration, 999)
  end)

  it('setup validates config', function()
    assert.throws(function()
      luxmotion.setup({
        cursor = { duration = -100 },
      })
    end)
  end)

  it('multiple setup calls work', function()
    assert.does_not_throw(function()
      luxmotion.setup()
      luxmotion.setup({ cursor = { duration = 100 } })
      luxmotion.setup({ scroll = { duration = 200 } })
    end)
  end)

  it('setup registers traits', function()
    luxmotion.setup()
    local traits = require('luxmotion.registry.traits')
    assert.is_not_nil(traits.get('cursor'))
    assert.is_not_nil(traits.get('scroll'))
  end)

  it('setup registers motions', function()
    luxmotion.setup()
    local motions = require('luxmotion.registry.motions')
    assert.is_not_nil(motions.get('basic_j'))
    assert.is_not_nil(motions.get('scroll_ctrl_d'))
  end)
end)
