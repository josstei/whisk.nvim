local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('registry/builtin', function()
  local builtin
  local motions
  local traits

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()

    motions = require('luxmotion.registry.motions')
    traits = require('luxmotion.registry.traits')
    builtin = require('luxmotion.registry.builtin')

    motions.clear()
    traits.clear()
  end)

  it('exports all required functions', function()
    assert.is_type(builtin.register_traits, 'function')
    assert.is_type(builtin.register_motions, 'function')
    assert.is_type(builtin.register_all, 'function')
  end)

  it('register_traits registers cursor trait', function()
    builtin.register_traits()

    local cursor = traits.get('cursor')
    assert.is_not_nil(cursor)
    assert.equals(cursor.id, 'cursor')
    assert.is_type(cursor.apply, 'function')
  end)

  it('register_traits registers scroll trait', function()
    builtin.register_traits()

    local scroll = traits.get('scroll')
    assert.is_not_nil(scroll)
    assert.equals(scroll.id, 'scroll')
    assert.is_type(scroll.apply, 'function')
  end)

  it('register_motions registers basic motions', function()
    builtin.register_motions()

    assert.is_not_nil(motions.get('basic_h'))
    assert.is_not_nil(motions.get('basic_j'))
    assert.is_not_nil(motions.get('basic_k'))
    assert.is_not_nil(motions.get('basic_l'))
    assert.is_not_nil(motions.get('basic_0'))
    assert.is_not_nil(motions.get('basic_$'))
  end)

  it('register_motions registers word motions', function()
    builtin.register_motions()

    assert.is_not_nil(motions.get('word_w'))
    assert.is_not_nil(motions.get('word_b'))
    assert.is_not_nil(motions.get('word_e'))
    assert.is_not_nil(motions.get('word_W'))
    assert.is_not_nil(motions.get('word_B'))
    assert.is_not_nil(motions.get('word_E'))
  end)

  it('register_motions registers find motions', function()
    builtin.register_motions()

    assert.is_not_nil(motions.get('find_f'))
    assert.is_not_nil(motions.get('find_F'))
    assert.is_not_nil(motions.get('find_t'))
    assert.is_not_nil(motions.get('find_T'))
  end)

  it('register_motions registers text object motions', function()
    builtin.register_motions()

    assert.is_not_nil(motions.get('text_object_{'))
    assert.is_not_nil(motions.get('text_object_}'))
    assert.is_not_nil(motions.get('text_object_('))
    assert.is_not_nil(motions.get('text_object_)'))
    assert.is_not_nil(motions.get('text_object_%'))
  end)

  it('register_motions registers line motions', function()
    builtin.register_motions()

    assert.is_not_nil(motions.get('line_gg'))
    assert.is_not_nil(motions.get('line_G'))
    assert.is_not_nil(motions.get('line_|'))
  end)

  it('register_motions registers search motions', function()
    builtin.register_motions()

    assert.is_not_nil(motions.get('search_n'))
    assert.is_not_nil(motions.get('search_N'))
    assert.is_not_nil(motions.get('screen_gj'))
    assert.is_not_nil(motions.get('screen_gk'))
  end)

  it('register_motions registers scroll motions', function()
    builtin.register_motions()

    assert.is_not_nil(motions.get('scroll_ctrl_d'))
    assert.is_not_nil(motions.get('scroll_ctrl_u'))
    assert.is_not_nil(motions.get('scroll_ctrl_f'))
    assert.is_not_nil(motions.get('scroll_ctrl_b'))
    assert.is_not_nil(motions.get('position_zz'))
    assert.is_not_nil(motions.get('position_zt'))
    assert.is_not_nil(motions.get('position_zb'))
  end)

  it('register_all registers both traits and motions', function()
    builtin.register_all()

    assert.is_not_nil(traits.get('cursor'))
    assert.is_not_nil(traits.get('scroll'))
    assert.is_not_nil(motions.get('basic_j'))
    assert.is_not_nil(motions.get('scroll_ctrl_d'))
  end)

  it('all cursor motions have cursor category', function()
    builtin.register_motions()

    local cursor_motions = motions.get_by_category('cursor')
    assert.greater_than(#cursor_motions, 0)

    for _, motion in ipairs(cursor_motions) do
      assert.equals(motion.category, 'cursor')
      assert.contains(motion.traits, 'cursor')
    end
  end)

  it('all scroll motions have scroll category', function()
    builtin.register_motions()

    local scroll_motions = motions.get_by_category('scroll')
    assert.greater_than(#scroll_motions, 0)

    for _, motion in ipairs(scroll_motions) do
      assert.equals(motion.category, 'scroll')
    end
  end)

  it('motions have valid calculator functions', function()
    builtin.register_motions()

    local all = motions.all()
    for id, motion in pairs(all) do
      assert.is_type(motion.calculator, 'function', 'Motion ' .. id .. ' has invalid calculator')
    end
  end)

  it('motions have valid keys', function()
    builtin.register_motions()

    local all = motions.all()
    for id, motion in pairs(all) do
      assert.is_type(motion.keys, 'table', 'Motion ' .. id .. ' has invalid keys')
      assert.greater_than(#motion.keys, 0, 'Motion ' .. id .. ' has no keys')
    end
  end)

  it('motions have valid modes', function()
    builtin.register_motions()

    local all = motions.all()
    for id, motion in pairs(all) do
      assert.is_type(motion.modes, 'table', 'Motion ' .. id .. ' has invalid modes')
      assert.greater_than(#motion.modes, 0, 'Motion ' .. id .. ' has no modes')
    end
  end)

  it('cursor trait apply function works with Context', function()
    builtin.register_traits()
    mocks.set_buffer_content({ "line1", "line2", "line3", "line4", "line5" })
    mocks.set_cursor(1, 0)
    mocks.set_topline(1)
    mocks.set_window_size(40, 120)

    local cursor_trait = traits.get('cursor')
    local Context = require('luxmotion.context.Context')
    local ctx = Context.new(1, 1000)
    ctx.cursor = { line = 1, col = 0 }

    local result = { cursor = { line = 5, col = 3 } }

    cursor_trait.apply(ctx, result, 1.0)

    local new_cursor = mocks.get_cursor()
    assert.equals(new_cursor[1], 5)
    assert.equals(new_cursor[2], 3)
  end)

  it('scroll trait apply function works with Context', function()
    builtin.register_traits()
    mocks.set_buffer_content({ "line1", "line2", "line3", "line4", "line5" })
    mocks.set_cursor(1, 0)
    mocks.set_topline(1)
    mocks.set_window_size(40, 120)

    local scroll_trait = traits.get('scroll')
    local Context = require('luxmotion.context.Context')
    local ctx = Context.new(1, 1000)
    ctx.viewport = { topline = 1 }

    local result = { viewport = { topline = 3 }, cursor = { line = 3, col = 0 } }

    assert.does_not_throw(function()
      scroll_trait.apply(ctx, result, 1.0)
    end)
  end)

  it('cursor trait does not crash without context methods', function()
    builtin.register_traits()

    local cursor_trait = traits.get('cursor')
    local plain_context = { cursor = { line = 1, col = 0 } }
    local result = { cursor = { line = 5, col = 3 } }

    assert.does_not_throw(function()
      cursor_trait.apply(plain_context, result, 1.0)
    end)
  end)

  it('cursor trait does not set cursor when context is invalid', function()
    builtin.register_traits()
    mocks.set_buffer_content({ "line1", "line2", "line3", "line4", "line5" })
    mocks.set_cursor(1, 0)
    mocks.set_topline(1)
    mocks.set_window_size(40, 120)

    local cursor_trait = traits.get('cursor')
    local Context = require('luxmotion.context.Context')
    local ctx = Context.new(1, 1000)
    ctx.cursor = { line = 1, col = 0 }

    mocks.delete_buffer(1)

    local result = { cursor = { line = 5, col = 3 } }
    cursor_trait.apply(ctx, result, 1.0)

    local new_cursor = mocks.get_cursor()
    assert.equals(new_cursor[1], 1)
    assert.equals(new_cursor[2], 0)
  end)

  it('register_traits registers trail trait when cursor trail enabled', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { trail = { enabled = true } } })

    traits.clear()
    builtin.register_traits()

    local trail = traits.get('trail')
    assert.is_not_nil(trail)
    assert.equals(trail.id, 'trail')
    assert.is_type(trail.apply, 'function')
  end)

  it('register_traits registers trail trait when scroll trail enabled', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { trail = { enabled = false } }, scroll = { trail = { enabled = true } } })

    traits.clear()
    builtin.register_traits()

    local trail = traits.get('trail')
    assert.is_not_nil(trail)
  end)

  it('register_traits skips trail trait when both trails disabled', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { trail = { enabled = false } }, scroll = { trail = { enabled = false } } })

    traits.clear()
    builtin.register_traits()

    local trail = traits.get('trail')
    assert.is_nil(trail)
  end)

  it('register_motions adds trail to cursor motion traits when cursor trail enabled', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { trail = { enabled = true } } })

    motions.clear()
    builtin.register_motions()

    local basic_j = motions.get('basic_j')
    assert.contains(basic_j.traits, 'trail')
  end)

  it('register_motions does not add trail to cursor motions when cursor trail disabled', function()
    local config = require('luxmotion.config')
    config.update({ cursor = { trail = { enabled = false } } })

    motions.clear()
    builtin.register_motions()

    local basic_j = motions.get('basic_j')
    local has_trail = false
    for _, t in ipairs(basic_j.traits) do
      if t == 'trail' then has_trail = true end
    end
    assert.is_false(has_trail)
  end)

  it('register_motions adds trail to scroll motion traits when scroll trail enabled', function()
    local config = require('luxmotion.config')
    config.update({ scroll = { trail = { enabled = true } } })

    motions.clear()
    builtin.register_motions()

    local scroll_d = motions.get('scroll_ctrl_d')
    assert.contains(scroll_d.traits, 'trail')
  end)

  it('register_motions does not add trail to scroll motions when scroll trail disabled', function()
    local config = require('luxmotion.config')
    config.update({ scroll = { trail = { enabled = false } } })

    motions.clear()
    builtin.register_motions()

    local scroll_d = motions.get('scroll_ctrl_d')
    local has_trail = false
    for _, t in ipairs(scroll_d.traits) do
      if t == 'trail' then has_trail = true end
    end
    assert.is_false(has_trail)
  end)

  it('basic motions have distance trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'basic_h', 'basic_j', 'basic_k', 'basic_l' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'distance', id .. ' should have distance policy')
    end
  end)

  it('screen motions have distance trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'screen_gj', 'screen_gk' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'distance', id .. ' should have distance policy')
    end
  end)

  it('word motions have always trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'word_w', 'word_b', 'word_e', 'word_W', 'word_B', 'word_E' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
    end
  end)

  it('find motions have always trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'find_f', 'find_F', 'find_t', 'find_T' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
    end
  end)

  it('line position motions have always trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'basic_0', 'basic_$', 'line_gg', 'line_G', 'line_|' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
    end
  end)

  it('text object motions have always trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'text_object_{', 'text_object_}', 'text_object_(', 'text_object_)', 'text_object_%' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
    end
  end)

  it('search motions have always trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'search_n', 'search_N' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
    end
  end)

  it('scroll motions have always trail_policy', function()
    builtin.register_motions()
    for _, id in ipairs({ 'scroll_ctrl_d', 'scroll_ctrl_u', 'scroll_ctrl_f', 'scroll_ctrl_b', 'position_zz', 'position_zt', 'position_zb' }) do
      local motion = motions.get(id)
      assert.equals(motion.trail_policy, 'always', id .. ' should have always policy')
    end
  end)
end)
