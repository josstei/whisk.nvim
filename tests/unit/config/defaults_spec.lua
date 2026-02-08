local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('config/defaults', function()
  local defaults

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    defaults = require('luxmotion.config.defaults')
  end)

  it('exports a config table', function()
    assert.is_not_nil(defaults.config)
    assert.is_type(defaults.config, 'table')
  end)

  it('has cursor configuration', function()
    assert.has_key(defaults.config, 'cursor')
    assert.equals(defaults.config.cursor.duration, 150)
    assert.equals(defaults.config.cursor.easing, 'ease-out')
    assert.equals(defaults.config.cursor.enabled, true)
  end)

  it('has scroll configuration', function()
    assert.has_key(defaults.config, 'scroll')
    assert.equals(defaults.config.scroll.duration, 200)
    assert.equals(defaults.config.scroll.easing, 'ease-in-out')
    assert.equals(defaults.config.scroll.enabled, true)
  end)

  it('has keymaps configuration', function()
    assert.has_key(defaults.config, 'keymaps')
    assert.equals(defaults.config.keymaps.cursor, true)
    assert.equals(defaults.config.keymaps.scroll, true)
  end)

  it('has performance configuration', function()
    assert.has_key(defaults.config, 'performance')
    assert.equals(defaults.config.performance.enabled, false)
    assert.equals(defaults.config.performance.disable_syntax_during_scroll, true)
    assert.equals(defaults.config.performance.reduce_frame_rate, false)
    assert.equals(defaults.config.performance.frame_rate_threshold, 60)
    assert.equals(defaults.config.performance.auto_enable_on_large_files, true)
    assert.equals(defaults.config.performance.large_file_threshold, 5000)
  end)

  it('has ignore_events in performance config', function()
    assert.is_type(defaults.config.performance.ignore_events, 'table')
    assert.contains(defaults.config.performance.ignore_events, 'WinScrolled')
    assert.contains(defaults.config.performance.ignore_events, 'CursorMoved')
    assert.contains(defaults.config.performance.ignore_events, 'CursorMovedI')
  end)

  it('all values are of correct types', function()
    assert.is_type(defaults.config.cursor.duration, 'number')
    assert.is_type(defaults.config.cursor.easing, 'string')
    assert.is_type(defaults.config.cursor.enabled, 'boolean')
    assert.is_type(defaults.config.scroll.duration, 'number')
    assert.is_type(defaults.config.scroll.easing, 'string')
    assert.is_type(defaults.config.scroll.enabled, 'boolean')
    assert.is_type(defaults.config.keymaps.cursor, 'boolean')
    assert.is_type(defaults.config.keymaps.scroll, 'boolean')
    assert.is_type(defaults.config.performance.enabled, 'boolean')
    assert.is_type(defaults.config.performance.large_file_threshold, 'number')
  end)

  it('has positive duration values', function()
    assert.greater_than(defaults.config.cursor.duration, 0)
    assert.greater_than(defaults.config.scroll.duration, 0)
  end)

  it('has valid easing values', function()
    local valid_easings = { 'linear', 'ease-in', 'ease-out', 'ease-in-out' }
    local function is_valid_easing(easing)
      for _, v in ipairs(valid_easings) do
        if v == easing then return true end
      end
      return false
    end
    assert.is_true(is_valid_easing(defaults.config.cursor.easing))
    assert.is_true(is_valid_easing(defaults.config.scroll.easing))
  end)

  it('has cursor trail configuration', function()
    assert.has_key(defaults.config.cursor, 'trail')
    assert.equals(defaults.config.cursor.trail.enabled, true)
    assert.equals(defaults.config.cursor.trail.color, 'auto')
    assert.equals(defaults.config.cursor.trail.segments, 6)
  end)

  it('has scroll trail configuration', function()
    assert.has_key(defaults.config.scroll, 'trail')
    assert.equals(defaults.config.scroll.trail.enabled, false)
    assert.equals(defaults.config.scroll.trail.color, 'auto')
    assert.equals(defaults.config.scroll.trail.segments, 6)
  end)

  it('trail config values are correct types', function()
    assert.is_type(defaults.config.cursor.trail.enabled, 'boolean')
    assert.is_type(defaults.config.cursor.trail.color, 'string')
    assert.is_type(defaults.config.cursor.trail.segments, 'number')
    assert.is_type(defaults.config.scroll.trail.enabled, 'boolean')
    assert.is_type(defaults.config.scroll.trail.color, 'string')
    assert.is_type(defaults.config.scroll.trail.segments, 'number')
  end)
end)
