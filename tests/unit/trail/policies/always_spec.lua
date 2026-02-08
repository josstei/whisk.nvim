local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/always', function()
  local always

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    always = require('luxmotion.trail.policies.always')
  end)

  it('exports id field', function()
    assert.equals(always.id, 'always')
  end)

  it('exports should_trail function', function()
    assert.is_type(always.should_trail, 'function')
  end)

  it('returns true for any context and result', function()
    local context = { cursor = { line = 1, col = 0 }, motion_id = 'basic_j' }
    local result = { cursor = { line = 2, col = 0 } }
    assert.is_true(always.should_trail(context, result))
  end)

  it('returns true with nil cursor in result', function()
    local context = { cursor = { line = 1, col = 0 }, motion_id = 'position_zz' }
    local result = { viewport = { topline = 5 } }
    assert.is_true(always.should_trail(context, result))
  end)

  it('returns true with empty context and result', function()
    assert.is_true(always.should_trail({}, {}))
  end)
end)
