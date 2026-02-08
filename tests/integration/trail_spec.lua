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

  it('trail trait suppresses trail when distance policy rejects', function()
    luxmotion.setup({
      cursor = {
        trail = {
          enabled = true,
          policy = 'distance',
          distance = { min_lines = 3, min_cols = 5 },
        },
      },
    })

    local traits = require('luxmotion.registry.traits')
    local trail_trait = traits.get('trail')
    assert.is_not_nil(trail_trait)

    local context = {
      cursor = { line = 1, col = 0 },
      motion_id = 'basic_j',
      category = 'cursor',
      bufnr = 1,
    }
    local result = { cursor = { line = 2, col = 0 } }

    trail_trait.on_start(context, result)
    assert.is_false(context.trail_active)
  end)

  it('trail trait activates trail when distance policy accepts', function()
    luxmotion.setup({
      cursor = {
        trail = {
          enabled = true,
          policy = 'distance',
          distance = { min_lines = 2, min_cols = 5 },
        },
      },
    })

    local traits = require('luxmotion.registry.traits')
    local trail_trait = traits.get('trail')

    local context = {
      cursor = { line = 1, col = 0 },
      motion_id = 'basic_j',
      category = 'cursor',
      bufnr = 1,
    }
    local result = { cursor = { line = 5, col = 0 } }

    trail_trait.on_start(context, result)
    assert.is_true(context.trail_active)
  end)

  it('trail trait always activates for always-policy motion', function()
    luxmotion.setup({
      cursor = {
        trail = {
          enabled = true,
          policy = 'distance',
          distance = { min_lines = 10, min_cols = 10 },
        },
      },
    })

    local traits = require('luxmotion.registry.traits')
    local motions = require('luxmotion.registry.motions')
    local trail_trait = traits.get('trail')

    local word_w = motions.get('word_w')
    assert.equals(word_w.trail_policy, 'always')

    local context = {
      cursor = { line = 1, col = 0 },
      motion_id = 'word_w',
      category = 'cursor',
      bufnr = 1,
    }
    local result = { cursor = { line = 1, col = 3 } }

    trail_trait.on_start(context, result)
    assert.is_true(context.trail_active)
  end)

  it('trail trait respects user override', function()
    luxmotion.setup({
      cursor = {
        trail = {
          enabled = true,
          overrides = { word_w = 'never' },
        },
      },
    })

    local traits = require('luxmotion.registry.traits')
    local trail_trait = traits.get('trail')

    local context = {
      cursor = { line = 1, col = 0 },
      motion_id = 'word_w',
      category = 'cursor',
      bufnr = 1,
    }
    local result = { cursor = { line = 1, col = 20 } }

    trail_trait.on_start(context, result)
    assert.is_false(context.trail_active)
  end)
end)
