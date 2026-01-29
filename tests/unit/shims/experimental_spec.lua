local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('experimental/keymaps (shims)', function()
  local experimental

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    experimental = require('luxmotion.experimental.keymaps')
  end)

  it('exports setup_keymaps function', function()
    assert.is_type(experimental.setup_keymaps, 'function')
  end)

  it('setup_keymaps is a no-op', function()
    assert.does_not_throw(function()
      experimental.setup_keymaps()
    end)
  end)

  it('module loads without error', function()
    assert.is_not_nil(experimental)
  end)

  it('setup_keymaps can be called multiple times', function()
    assert.does_not_throw(function()
      experimental.setup_keymaps()
      experimental.setup_keymaps()
      experimental.setup_keymaps()
    end)
  end)
end)
