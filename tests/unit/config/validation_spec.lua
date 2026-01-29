local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('config/validation', function()
  local validation

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    validation = require('luxmotion.config.validation')
  end)

  it('exports validate_config function', function()
    assert.is_not_nil(validation.validate_config)
    assert.is_type(validation.validate_config, 'function')
  end)

  it('accepts valid complete config', function()
    local config = {
      cursor = { duration = 250, easing = 'ease-out', enabled = true },
      scroll = { duration = 400, easing = 'linear', enabled = false },
      keymaps = { cursor = true, scroll = false },
    }
    assert.does_not_throw(function()
      validation.validate_config(config)
    end)
  end)

  it('accepts partial config', function()
    local config = {
      cursor = { duration = 100 },
    }
    assert.does_not_throw(function()
      validation.validate_config(config)
    end)
  end)

  it('accepts empty config', function()
    assert.does_not_throw(function()
      validation.validate_config({})
    end)
  end)

  it('accepts nil config', function()
    assert.does_not_throw(function()
      validation.validate_config(nil)
    end)
  end)

  it('rejects negative cursor duration', function()
    local config = {
      cursor = { duration = -100 },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'duration')
  end)

  it('accepts zero cursor duration', function()
    local config = {
      cursor = { duration = 0 },
    }
    assert.does_not_throw(function()
      validation.validate_config(config)
    end)
  end)

  it('rejects non-number cursor duration', function()
    local config = {
      cursor = { duration = 'fast' },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'duration')
  end)

  it('rejects invalid cursor easing', function()
    local config = {
      cursor = { easing = 'bounce' },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'easing')
  end)

  it('rejects non-string cursor easing', function()
    local config = {
      cursor = { easing = 123 },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'easing')
  end)

  it('rejects non-boolean cursor enabled', function()
    local config = {
      cursor = { enabled = 'yes' },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'enabled')
  end)

  it('accepts all valid easing types for cursor', function()
    local easings = { 'linear', 'ease-in', 'ease-out', 'ease-in-out' }
    for _, easing in ipairs(easings) do
      assert.does_not_throw(function()
        validation.validate_config({ cursor = { easing = easing } })
      end)
    end
  end)

  it('rejects negative scroll duration', function()
    local config = {
      scroll = { duration = -50 },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'duration')
  end)

  it('rejects invalid scroll easing', function()
    local config = {
      scroll = { easing = 'cubic' },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'easing')
  end)

  it('rejects non-boolean scroll enabled', function()
    local config = {
      scroll = { enabled = 1 },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'enabled')
  end)

  it('accepts all valid easing types for scroll', function()
    local easings = { 'linear', 'ease-in', 'ease-out', 'ease-in-out' }
    for _, easing in ipairs(easings) do
      assert.does_not_throw(function()
        validation.validate_config({ scroll = { easing = easing } })
      end)
    end
  end)

  it('rejects non-boolean keymaps.cursor', function()
    local config = {
      keymaps = { cursor = 'enabled' },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'cursor')
  end)

  it('rejects non-boolean keymaps.scroll', function()
    local config = {
      keymaps = { scroll = nil, scroll = 0 },
    }
    assert.throws(function()
      validation.validate_config(config)
    end, 'scroll')
  end)

  it('accepts boolean false values', function()
    local config = {
      cursor = { enabled = false },
      scroll = { enabled = false },
      keymaps = { cursor = false, scroll = false },
    }
    assert.does_not_throw(function()
      validation.validate_config(config)
    end)
  end)

  it('validates large duration values', function()
    local config = {
      cursor = { duration = 10000 },
      scroll = { duration = 99999 },
    }
    assert.does_not_throw(function()
      validation.validate_config(config)
    end)
  end)

  it('validates decimal duration values', function()
    local config = {
      cursor = { duration = 250.5 },
      scroll = { duration = 400.75 },
    }
    assert.does_not_throw(function()
      validation.validate_config(config)
    end)
  end)
end)
