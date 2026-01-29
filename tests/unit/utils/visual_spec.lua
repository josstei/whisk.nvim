local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('utils/visual', function()
  local visual

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    visual = require('luxmotion.utils.visual')
  end)

  it('exports all required functions', function()
    assert.is_type(visual.get_mode, 'function')
    assert.is_type(visual.save_selection, 'function')
    assert.is_type(visual.restore_selection, 'function')
    assert.is_type(visual.exit_visual_mode, 'function')
    assert.is_type(visual.is_visual_mode, 'function')
  end)

  it('get_mode returns current mode', function()
    local mode = visual.get_mode()
    assert.is_type(mode, 'string')
    assert.equals(mode, 'n')
  end)

  it('get_mode reflects mode changes', function()
    require('tests.mocks.vim_fn').set_mode('v')
    local mode = visual.get_mode()
    assert.equals(mode, 'v')
  end)

  it('is_visual_mode returns true for v', function()
    assert.is_true(visual.is_visual_mode('v'))
  end)

  it('is_visual_mode returns true for V', function()
    assert.is_true(visual.is_visual_mode('V'))
  end)

  it('is_visual_mode returns true for block visual', function()
    assert.is_true(visual.is_visual_mode(''))
  end)

  it('is_visual_mode returns false for n', function()
    assert.is_false(visual.is_visual_mode('n'))
  end)

  it('is_visual_mode returns false for i', function()
    assert.is_false(visual.is_visual_mode('i'))
  end)

  it('is_visual_mode returns false for nil', function()
    assert.is_false(visual.is_visual_mode(nil))
  end)

  it('save_selection returns selection data', function()
    require('tests.mocks.vim_fn').set_visual_selection(
      { 0, 2, 5, 0 },
      { 0, 4, 10, 0 }
    )

    local selection = visual.save_selection()
    assert.is_not_nil(selection)
    assert.is_not_nil(selection.start_pos)
    assert.is_not_nil(selection.end_pos)
  end)

  it('save_selection captures start and end positions', function()
    require('tests.mocks.vim_fn').set_visual_selection(
      { 0, 1, 0, 0 },
      { 0, 5, 10, 0 }
    )

    local selection = visual.save_selection()
    assert.table_equals(selection.start_pos, { 0, 1, 0, 0 })
    assert.table_equals(selection.end_pos, { 0, 5, 10, 0 })
  end)

  it('save_selection captures mode', function()
    require('tests.mocks.vim_fn').set_mode('V')
    local selection = visual.save_selection()
    assert.equals(selection.mode, 'V')
  end)

  it('restore_selection sets marks', function()
    local selection = {
      start_pos = { 0, 2, 3, 0 },
      end_pos = { 0, 5, 8, 0 },
      mode = 'v',
    }

    assert.does_not_throw(function()
      visual.restore_selection(selection)
    end)

    local fn_state = require('tests.mocks.vim_fn').get_state()
    assert.table_equals(fn_state.visual_start, { 0, 2, 3, 0 })
    assert.table_equals(fn_state.visual_end, { 0, 5, 8, 0 })
  end)

  it('restore_selection requires valid selection', function()
    assert.throws(function()
      visual.restore_selection(nil)
    end)
  end)

  it('exit_visual_mode sends escape', function()
    visual.exit_visual_mode()

    local commands = mocks.get_commands()
    assert.greater_than(#commands, 0)
  end)

  it('save and restore roundtrip', function()
    require('tests.mocks.vim_fn').set_visual_selection(
      { 0, 3, 5, 0 },
      { 0, 7, 12, 0 }
    )
    require('tests.mocks.vim_fn').set_mode('v')

    local selection = visual.save_selection()
    visual.restore_selection(selection)

    local fn_state = require('tests.mocks.vim_fn').get_state()
    assert.table_equals(fn_state.visual_start, { 0, 3, 5, 0 })
    assert.table_equals(fn_state.visual_end, { 0, 7, 12, 0 })
  end)

  it('multiple visual modes are detected', function()
    assert.is_true(visual.is_visual_mode('v'))
    assert.is_true(visual.is_visual_mode('V'))
    assert.is_true(visual.is_visual_mode(''))
    assert.is_false(visual.is_visual_mode('n'))
    assert.is_false(visual.is_visual_mode('i'))
    assert.is_false(visual.is_visual_mode('c'))
    assert.is_false(visual.is_visual_mode('R'))
  end)
end)
