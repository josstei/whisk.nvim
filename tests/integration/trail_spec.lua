local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each, after_each = runner.describe, runner.it, runner.before_each, runner.after_each

describe('Integration: Trail with Animation', function()
  local luxmotion

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({ "line 1", "line 2", "line 3", "line 4", "line 5" })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    luxmotion = require('luxmotion')
  end)

  after_each(function()
    if luxmotion and luxmotion.reset then
      luxmotion.reset()
    end
  end)

  it('setup with trail enabled registers trail trait', function()
    luxmotion.setup({
      cursor = { trail = { enabled = true } },
    })

    local traits = require('luxmotion.registry.traits')
    assert.is_not_nil(traits.get('trail'))
    assert.is_type(traits.get('trail').apply, 'function')
    assert.is_type(traits.get('trail').on_start, 'function')
    assert.is_type(traits.get('trail').on_complete, 'function')
  end)

  it('cursor motions include trail trait when enabled', function()
    luxmotion.setup({
      cursor = { trail = { enabled = true } },
    })

    local motions = require('luxmotion.registry.motions')
    local basic_j = motions.get('basic_j')
    assert.contains(basic_j.traits, 'trail')
  end)

  it('scroll motions include trail trait when scroll trail enabled', function()
    luxmotion.setup({
      scroll = { trail = { enabled = true } },
    })

    local motions = require('luxmotion.registry.motions')
    local scroll_d = motions.get('scroll_ctrl_d')
    assert.contains(scroll_d.traits, 'trail')
  end)

  it('highlight groups created during setup', function()
    luxmotion.setup({
      cursor = { trail = { enabled = true, color = '#FF0000', segments = 4 } },
    })

    local hl_state = mocks.get_highlights()
    assert.is_not_nil(hl_state['LuxMotionTrail1'])
    assert.is_not_nil(hl_state['LuxMotionTrail4'])
    assert.is_nil(hl_state['LuxMotionTrail5'])
  end)

  it('reset cleans up trail state', function()
    luxmotion.setup({
      cursor = { trail = { enabled = true } },
    })

    luxmotion.reset()

    local traits = require('luxmotion.registry.traits')
    assert.is_nil(traits.get('trail'))
  end)

  it('multiple setup calls reinitialize trail correctly', function()
    luxmotion.setup({ cursor = { trail = { enabled = true } } })
    luxmotion.setup({ cursor = { trail = { enabled = false } }, scroll = { trail = { enabled = false } } })

    local traits = require('luxmotion.registry.traits')
    assert.is_nil(traits.get('trail'))
  end)
end)
