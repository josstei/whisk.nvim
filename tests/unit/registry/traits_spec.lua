local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('registry/traits', function()
  local traits

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    traits = require('luxmotion.registry.traits')
    traits.clear()
  end)

  it('exports all required functions', function()
    assert.is_type(traits.register, 'function')
    assert.is_type(traits.get, 'function')
    assert.is_type(traits.is_animating, 'function')
    assert.is_type(traits.set_animating, 'function')
    assert.is_type(traits.apply_frame, 'function')
    assert.is_type(traits.all, 'function')
    assert.is_type(traits.reset, 'function')
    assert.is_type(traits.clear, 'function')
  end)

  it('register adds a trait', function()
    traits.register({
      id = 'test_trait',
      apply = function() end,
    })

    local trait = traits.get('test_trait')
    assert.is_not_nil(trait)
    assert.equals(trait.id, 'test_trait')
  end)

  it('get returns registered trait', function()
    local apply_fn = function() end
    local on_start_fn = function() end
    local on_complete_fn = function() end

    traits.register({
      id = 'my_trait',
      apply = apply_fn,
      on_start = on_start_fn,
      on_complete = on_complete_fn,
    })

    local trait = traits.get('my_trait')
    assert.equals(trait.id, 'my_trait')
    assert.equals(trait.apply, apply_fn)
    assert.equals(trait.on_start, on_start_fn)
    assert.equals(trait.on_complete, on_complete_fn)
  end)

  it('get returns nil for unknown trait', function()
    local trait = traits.get('unknown')
    assert.is_nil(trait)
  end)

  it('is_animating returns false initially', function()
    traits.register({
      id = 'cursor',
      apply = function() end,
    })

    assert.is_false(traits.is_animating('cursor'))
  end)

  it('set_animating updates animating state', function()
    traits.register({
      id = 'cursor',
      apply = function() end,
    })

    traits.set_animating('cursor', true)
    assert.is_true(traits.is_animating('cursor'))

    traits.set_animating('cursor', false)
    assert.is_false(traits.is_animating('cursor'))
  end)

  it('is_animating returns false for unregistered trait', function()
    assert.is_false(traits.is_animating('nonexistent'))
  end)

  it('apply_frame calls trait apply function', function()
    local applied = false
    local received_context, received_result, received_progress

    traits.register({
      id = 'test',
      apply = function(ctx, res, prog)
        applied = true
        received_context = ctx
        received_result = res
        received_progress = prog
      end,
    })

    local context = { cursor = { line = 1 } }
    local result = { cursor = { line = 5 } }
    traits.apply_frame('test', context, result, 0.5)

    assert.is_true(applied)
    assert.equals(received_context, context)
    assert.equals(received_result, result)
    assert.equals(received_progress, 0.5)
  end)

  it('apply_frame does nothing for unknown trait', function()
    assert.does_not_throw(function()
      traits.apply_frame('unknown', {}, {}, 0.5)
    end)
  end)

  it('all returns all registered traits', function()
    traits.register({ id = 'trait1', apply = function() end })
    traits.register({ id = 'trait2', apply = function() end })
    traits.register({ id = 'trait3', apply = function() end })

    local all = traits.all()
    assert.has_key(all, 'trait1')
    assert.has_key(all, 'trait2')
    assert.has_key(all, 'trait3')
  end)

  it('reset clears all animating states', function()
    traits.register({ id = 'cursor', apply = function() end })
    traits.register({ id = 'scroll', apply = function() end })

    traits.set_animating('cursor', true)
    traits.set_animating('scroll', true)

    traits.reset()

    assert.is_false(traits.is_animating('cursor'))
    assert.is_false(traits.is_animating('scroll'))
  end)

  it('clear removes all traits and states', function()
    traits.register({ id = 'trait1', apply = function() end })
    traits.set_animating('trait1', true)

    traits.clear()

    assert.is_nil(traits.get('trait1'))
    assert.is_false(traits.is_animating('trait1'))
  end)

  it('register overwrites existing trait', function()
    local fn1 = function() return 1 end
    local fn2 = function() return 2 end

    traits.register({ id = 'same', apply = fn1 })
    traits.register({ id = 'same', apply = fn2 })

    local trait = traits.get('same')
    assert.equals(trait.apply, fn2)
  end)

  it('multiple traits can have independent states', function()
    traits.register({ id = 'cursor', apply = function() end })
    traits.register({ id = 'scroll', apply = function() end })

    traits.set_animating('cursor', true)
    traits.set_animating('scroll', false)

    assert.is_true(traits.is_animating('cursor'))
    assert.is_false(traits.is_animating('scroll'))

    traits.set_animating('cursor', false)
    traits.set_animating('scroll', true)

    assert.is_false(traits.is_animating('cursor'))
    assert.is_true(traits.is_animating('scroll'))
  end)

  it('trait with on_start callback', function()
    local started = false
    traits.register({
      id = 'with_start',
      apply = function() end,
      on_start = function() started = true end,
    })

    local trait = traits.get('with_start')
    trait.on_start()
    assert.is_true(started)
  end)

  it('trait with on_complete callback', function()
    local completed = false
    traits.register({
      id = 'with_complete',
      apply = function() end,
      on_complete = function() completed = true end,
    })

    local trait = traits.get('with_complete')
    trait.on_complete()
    assert.is_true(completed)
  end)

  it('trait without optional callbacks', function()
    traits.register({
      id = 'minimal',
      apply = function() end,
    })

    local trait = traits.get('minimal')
    assert.is_nil(trait.on_start)
    assert.is_nil(trait.on_complete)
  end)
end)
