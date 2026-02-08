local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/distance', function()
  local distance

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    distance = require('luxmotion.trail.policies.distance')
  end)

  it('exports id field', function()
    assert.equals(distance.id, 'distance')
  end)

  it('exports create function', function()
    assert.is_type(distance.create, 'function')
  end)

  it('create returns a policy with should_trail', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    assert.is_type(policy.should_trail, 'function')
    assert.equals(policy.id, 'distance')
  end)

  it('returns false when movement is below both thresholds', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 2, col = 3 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns true when line movement meets threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 3, col = 0 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('returns true when column movement meets threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 1, col = 5 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('returns true when both axes meet threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 5, col = 10 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('returns false at exactly one below line threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 2, col = 0 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns false at exactly one below col threshold', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 1, col = 4 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns false when result has no cursor', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 1, col = 0 } }
    local result = { viewport = { topline = 5 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('returns false for zero movement', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 5, col = 10 } }
    local result = { cursor = { line = 5, col = 10 } }
    assert.is_false(policy.should_trail(context, result))
  end)

  it('handles backward movement (negative delta)', function()
    local policy = distance.create({ min_lines = 2, min_cols = 5 })
    local context = { cursor = { line = 10, col = 20 } }
    local result = { cursor = { line = 7, col = 20 } }
    assert.is_true(policy.should_trail(context, result))
  end)

  it('respects custom thresholds', function()
    local policy = distance.create({ min_lines = 5, min_cols = 10 })
    local context = { cursor = { line = 1, col = 0 } }
    local result_short = { cursor = { line = 5, col = 0 } }
    local result_long = { cursor = { line = 6, col = 0 } }
    assert.is_false(policy.should_trail(context, result_short))
    assert.is_true(policy.should_trail(context, result_long))
  end)
end)
