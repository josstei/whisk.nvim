local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('registry/motions', function()
  local motions

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    motions = require('luxmotion.registry.motions')
    motions.clear()
  end)

  it('exports all required functions', function()
    assert.is_type(motions.register, 'function')
    assert.is_type(motions.get, 'function')
    assert.is_type(motions.get_by_category, 'function')
    assert.is_type(motions.all, 'function')
    assert.is_type(motions.clear, 'function')
  end)

  it('register adds a motion', function()
    motions.register({
      id = 'test_motion',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    local motion = motions.get('test_motion')
    assert.is_not_nil(motion)
    assert.equals(motion.id, 'test_motion')
  end)

  it('get returns registered motion', function()
    motions.register({
      id = 'my_motion',
      keys = { 'k' },
      modes = { 'n', 'v' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
      description = 'Move up',
    })

    local motion = motions.get('my_motion')
    assert.equals(motion.id, 'my_motion')
    assert.table_equals(motion.keys, { 'k' })
    assert.table_equals(motion.modes, { 'n', 'v' })
    assert.table_equals(motion.traits, { 'cursor' })
    assert.equals(motion.category, 'cursor')
    assert.equals(motion.description, 'Move up')
  end)

  it('get returns nil for unknown motion', function()
    local motion = motions.get('unknown')
    assert.is_nil(motion)
  end)

  it('get_by_category returns motions in category', function()
    motions.register({
      id = 'cursor_1',
      keys = { 'j' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })
    motions.register({
      id = 'cursor_2',
      keys = { 'k' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })
    motions.register({
      id = 'scroll_1',
      keys = { '<C-d>' },
      modes = { 'n' },
      traits = { 'scroll' },
      category = 'scroll',
      calculator = function() return {} end,
    })

    local cursor_motions = motions.get_by_category('cursor')
    assert.length(cursor_motions, 2)

    local scroll_motions = motions.get_by_category('scroll')
    assert.length(scroll_motions, 1)
  end)

  it('get_by_category returns empty table for unknown category', function()
    local result = motions.get_by_category('unknown')
    assert.is_type(result, 'table')
    assert.length(result, 0)
  end)

  it('all returns all registered motions', function()
    motions.register({
      id = 'motion_1',
      keys = { 'a' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })
    motions.register({
      id = 'motion_2',
      keys = { 'b' },
      modes = { 'n' },
      traits = { 'scroll' },
      category = 'scroll',
      calculator = function() return {} end,
    })

    local all = motions.all()
    assert.has_key(all, 'motion_1')
    assert.has_key(all, 'motion_2')
  end)

  it('clear removes all motions', function()
    motions.register({
      id = 'motion_1',
      keys = { 'a' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    motions.clear()

    assert.is_nil(motions.get('motion_1'))
    local all = motions.all()
    local count = 0
    for _ in pairs(all) do count = count + 1 end
    assert.equals(count, 0)
  end)

  it('register overwrites existing motion with same id', function()
    motions.register({
      id = 'same_id',
      keys = { 'a' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return { v = 1 } end,
    })
    motions.register({
      id = 'same_id',
      keys = { 'b' },
      modes = { 'v' },
      traits = { 'scroll' },
      category = 'scroll',
      calculator = function() return { v = 2 } end,
    })

    local motion = motions.get('same_id')
    assert.table_equals(motion.keys, { 'b' })
    assert.equals(motion.category, 'scroll')
  end)

  it('register with multiple keys', function()
    motions.register({
      id = 'multi_key',
      keys = { 'gg', 'G' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    local motion = motions.get('multi_key')
    assert.length(motion.keys, 2)
    assert.contains(motion.keys, 'gg')
    assert.contains(motion.keys, 'G')
  end)

  it('register with input type', function()
    motions.register({
      id = 'with_input',
      keys = { 'f' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
      input = 'char',
    })

    local motion = motions.get('with_input')
    assert.equals(motion.input, 'char')
  end)

  it('motion calculator is callable', function()
    local calc_result = { cursor = { line = 5, col = 0 } }
    motions.register({
      id = 'callable',
      keys = { 'x' },
      modes = { 'n' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return calc_result end,
    })

    local motion = motions.get('callable')
    local result = motion.calculator({})
    assert.table_equals(result, calc_result)
  end)

  it('register defaults modes to n and v', function()
    motions.register({
      id = 'default_modes',
      keys = { 'x' },
      traits = { 'cursor' },
      category = 'cursor',
      calculator = function() return {} end,
    })

    local motion = motions.get('default_modes')
    assert.is_not_nil(motion.modes)
  end)
end)
