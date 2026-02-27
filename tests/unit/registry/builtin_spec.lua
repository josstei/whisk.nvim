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

    motions = require('whisk.registry.motions')
    traits = require('whisk.registry.traits')
    builtin = require('whisk.registry.builtin')

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
    local Context = require('whisk.context.Context')
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
    local Context = require('whisk.context.Context')
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
    local Context = require('whisk.context.Context')
    local ctx = Context.new(1, 1000)
    ctx.cursor = { line = 1, col = 0 }

    mocks.delete_buffer(1)

    local result = { cursor = { line = 5, col = 3 } }
    cursor_trait.apply(ctx, result, 1.0)

    local new_cursor = mocks.get_cursor()
    assert.equals(new_cursor[1], 1)
    assert.equals(new_cursor[2], 0)
  end)
end)
