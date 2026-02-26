local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('scroll/keymaps (shims)', function()
  local scroll_keymaps
  local orchestrator_calls = {}

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    orchestrator_calls = {}

    package.loaded['whisk.engine.orchestrator'] = {
      execute = function(motion_id, input)
        table.insert(orchestrator_calls, { motion_id = motion_id, input = input })
      end,
      fallback = function() end,
    }

    scroll_keymaps = require('whisk.scroll.keymaps')
  end)

  it('exports deprecated functions', function()
    assert.is_type(scroll_keymaps.smooth_scroll, 'function')
    assert.is_type(scroll_keymaps.visual_smooth_scroll, 'function')
    assert.is_type(scroll_keymaps.smooth_position, 'function')
    assert.is_type(scroll_keymaps.setup_keymaps, 'function')
  end)

  it('smooth_scroll ctrl_d calls orchestrator', function()
    scroll_keymaps.smooth_scroll('ctrl_d', 1)
    assert.equals(#orchestrator_calls, 1)
    assert.equals(orchestrator_calls[1].motion_id, 'scroll_ctrl_d')
  end)

  it('smooth_scroll ctrl_u calls orchestrator', function()
    scroll_keymaps.smooth_scroll('ctrl_u', 2)
    assert.equals(orchestrator_calls[1].motion_id, 'scroll_ctrl_u')
    assert.equals(orchestrator_calls[1].input.count, 2)
  end)

  it('smooth_scroll ctrl_f calls orchestrator', function()
    scroll_keymaps.smooth_scroll('ctrl_f', 1)
    assert.equals(orchestrator_calls[1].motion_id, 'scroll_ctrl_f')
  end)

  it('smooth_scroll ctrl_b calls orchestrator', function()
    scroll_keymaps.smooth_scroll('ctrl_b', 1)
    assert.equals(orchestrator_calls[1].motion_id, 'scroll_ctrl_b')
  end)

  it('visual_smooth_scroll calls same as smooth_scroll', function()
    scroll_keymaps.visual_smooth_scroll('ctrl_d', 3)
    assert.equals(orchestrator_calls[1].motion_id, 'scroll_ctrl_d')
    assert.equals(orchestrator_calls[1].input.count, 3)
  end)

  it('smooth_position zz calls orchestrator', function()
    scroll_keymaps.smooth_position('zz')
    assert.equals(orchestrator_calls[1].motion_id, 'position_zz')
  end)

  it('smooth_position zt calls orchestrator', function()
    scroll_keymaps.smooth_position('zt')
    assert.equals(orchestrator_calls[1].motion_id, 'position_zt')
  end)

  it('smooth_position zb calls orchestrator', function()
    scroll_keymaps.smooth_position('zb')
    assert.equals(orchestrator_calls[1].motion_id, 'position_zb')
  end)

  it('setup_keymaps is a no-op', function()
    assert.does_not_throw(function()
      scroll_keymaps.setup_keymaps()
    end)
  end)

  it('smooth_scroll passes count correctly', function()
    scroll_keymaps.smooth_scroll('ctrl_d', 5)
    assert.equals(orchestrator_calls[1].input.count, 5)

    scroll_keymaps.smooth_scroll('ctrl_u', 10)
    assert.equals(orchestrator_calls[2].input.count, 10)
  end)

  it('smooth_position passes input', function()
    scroll_keymaps.smooth_position('zz')
    assert.is_not_nil(orchestrator_calls[1].input)
  end)

  it('multiple calls accumulate in order', function()
    scroll_keymaps.smooth_scroll('ctrl_d', 1)
    scroll_keymaps.smooth_scroll('ctrl_u', 1)
    scroll_keymaps.smooth_position('zz')

    assert.equals(#orchestrator_calls, 3)
    assert.equals(orchestrator_calls[1].motion_id, 'scroll_ctrl_d')
    assert.equals(orchestrator_calls[2].motion_id, 'scroll_ctrl_u')
    assert.equals(orchestrator_calls[3].motion_id, 'position_zz')
  end)
end)
