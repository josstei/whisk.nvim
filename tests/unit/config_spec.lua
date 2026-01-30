local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('config (router)', function()
  local config

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    config = require('luxmotion.config')
    config.reset()
  end)

  it('exports all management functions', function()
    assert.is_type(config.get, 'function')
    assert.is_type(config.get_cursor, 'function')
    assert.is_type(config.get_scroll, 'function')
    assert.is_type(config.get_keymaps, 'function')
    assert.is_type(config.get_performance, 'function')
    assert.is_type(config.update, 'function')
    assert.is_type(config.reset, 'function')
  end)

  it('exports validate function', function()
    assert.is_type(config.validate, 'function')
  end)

  it('get returns full config', function()
    local cfg = config.get()
    assert.has_key(cfg, 'cursor')
    assert.has_key(cfg, 'scroll')
    assert.has_key(cfg, 'keymaps')
    assert.has_key(cfg, 'performance')
  end)

  it('get_cursor delegates to management', function()
    local cursor = config.get_cursor()
    assert.equals(cursor.duration, 250)
    assert.equals(cursor.easing, 'ease-out')
    assert.equals(cursor.enabled, true)
  end)

  it('get_scroll delegates to management', function()
    local scroll = config.get_scroll()
    assert.equals(scroll.duration, 400)
    assert.equals(scroll.easing, 'ease-out')
    assert.equals(scroll.enabled, true)
  end)

  it('get_keymaps delegates to management', function()
    local keymaps = config.get_keymaps()
    assert.equals(keymaps.cursor, true)
    assert.equals(keymaps.scroll, true)
  end)

  it('get_performance delegates to management', function()
    local perf = config.get_performance()
    assert.equals(perf.enabled, false)
    assert.equals(perf.large_file_threshold, 5000)
  end)

  it('update delegates to management', function()
    config.update({ cursor = { duration = 100 } })
    assert.equals(config.get_cursor().duration, 100)
  end)

  it('reset delegates to management', function()
    config.update({ cursor = { duration = 999 } })
    config.reset()
    assert.equals(config.get_cursor().duration, 250)
  end)

  it('validate delegates to validation', function()
    assert.does_not_throw(function()
      config.validate({ cursor = { duration = 100 } })
    end)

    assert.throws(function()
      config.validate({ cursor = { duration = -100 } })
    end)
  end)

  it('get with category parameter works', function()
    local cursor = config.get('cursor')
    assert.equals(cursor.duration, 250)

    local scroll = config.get('scroll')
    assert.equals(scroll.duration, 400)
  end)

  it('update and get roundtrip', function()
    config.update({
      cursor = { duration = 500, easing = 'linear' },
      scroll = { enabled = false },
      keymaps = { cursor = false },
    })

    assert.equals(config.get_cursor().duration, 500)
    assert.equals(config.get_cursor().easing, 'linear')
    assert.equals(config.get_scroll().enabled, false)
    assert.equals(config.get_keymaps().cursor, false)
  end)

  it('validate throws for invalid easing', function()
    assert.throws(function()
      config.validate({ cursor = { easing = 'invalid' } })
    end, 'easing')
  end)

  it('validate throws for invalid type', function()
    assert.throws(function()
      config.validate({ cursor = { enabled = 'yes' } })
    end, 'enabled')
  end)

  it('multiple updates accumulate', function()
    config.update({ cursor = { duration = 100 } })
    config.update({ scroll = { duration = 200 } })
    config.update({ keymaps = { cursor = false } })

    assert.equals(config.get_cursor().duration, 100)
    assert.equals(config.get_scroll().duration, 200)
    assert.equals(config.get_keymaps().cursor, false)
  end)
end)
