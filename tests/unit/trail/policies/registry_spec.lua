local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('trail/policies/registry', function()
  local policies
  local config

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    policies = require('luxmotion.trail.policies')
    config = require('luxmotion.config')
    policies.clear()
  end)

  it('exports all required functions', function()
    assert.is_type(policies.register, 'function')
    assert.is_type(policies.get, 'function')
    assert.is_type(policies.resolve, 'function')
    assert.is_type(policies.clear, 'function')
  end)

  it('register adds a policy', function()
    policies.register({
      id = 'test_policy',
      should_trail = function() return true end,
    })
    local policy = policies.get('test_policy')
    assert.is_not_nil(policy)
    assert.equals(policy.id, 'test_policy')
  end)

  it('get returns nil for unknown policy', function()
    assert.is_nil(policies.get('nonexistent'))
  end)

  it('register overwrites existing policy', function()
    local fn1 = function() return true end
    local fn2 = function() return false end
    policies.register({ id = 'same', should_trail = fn1 })
    policies.register({ id = 'same', should_trail = fn2 })
    local policy = policies.get('same')
    assert.equals(policy.should_trail, fn2)
  end)

  it('clear removes all policies', function()
    policies.register({ id = 'p1', should_trail = function() return true end })
    policies.clear()
    assert.is_nil(policies.get('p1'))
  end)

  it('resolve returns user override when present', function()
    policies.register({ id = 'always', should_trail = function() return true end })
    policies.register({ id = 'never', should_trail = function() return false end })

    config.update({
      cursor = {
        trail = {
          overrides = { basic_j = 'never' },
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      trail_policy = 'always',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'never')
  end)

  it('resolve returns motion trail_policy when no override', function()
    policies.register({ id = 'always', should_trail = function() return true end })
    policies.register({ id = 'never', should_trail = function() return false end })

    config.update({
      cursor = {
        trail = {
          overrides = {},
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      trail_policy = 'never',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'never')
  end)

  it('resolve returns category default when no override and no motion policy', function()
    policies.register({ id = 'always', should_trail = function() return true end })
    policies.register({ id = 'never', should_trail = function() return false end })

    config.update({
      cursor = {
        trail = {
          policy = 'never',
          overrides = {},
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'never')
  end)

  it('resolve falls back to always when nothing configured', function()
    policies.register({ id = 'always', should_trail = function() return true end })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'always')
  end)

  it('resolve logs warning for unknown override policy ID', function()
    policies.register({ id = 'always', should_trail = function() return true end })

    config.update({
      cursor = {
        trail = {
          overrides = { basic_j = 'nonexistent_policy' },
        },
      },
    })

    local motions = require('luxmotion.registry.motions')
    motions.clear()
    motions.register({
      id = 'basic_j',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      trail_policy = 'always',
      calculator = function() return {} end,
    })

    local policy = policies.resolve('basic_j')
    assert.equals(policy.id, 'always')

    local notifications = mocks.get_notifications()
    local found_warning = false
    for _, notif in ipairs(notifications) do
      if notif.msg:match('nonexistent_policy') then
        found_warning = true
      end
    end
    assert.is_true(found_warning)
  end)

  it('resolve returns always fallback for unknown motion', function()
    policies.register({ id = 'always', should_trail = function() return true end })

    local policy = policies.resolve('nonexistent_motion')
    assert.equals(policy.id, 'always')
  end)
end)
