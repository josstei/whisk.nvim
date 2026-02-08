local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/never', function()
  local never

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    never = require('luxmotion.trail.policies.never')
  end)

  it('exports id field', function()
    assert.equals(never.id, 'never')
  end)

  it('exports should_trail function', function()
    assert.is_type(never.should_trail, 'function')
  end)

  it('returns false for any context and result', function()
    local context = { cursor = { line = 1, col = 0 }, motion_id = 'basic_j' }
    local result = { cursor = { line = 100, col = 50 } }
    assert.is_false(never.should_trail(context, result))
  end)

  it('returns false with empty context and result', function()
    assert.is_false(never.should_trail({}, {}))
  end)
end)
