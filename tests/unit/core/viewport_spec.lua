local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('core/viewport', function()
  local viewport

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "line 1",
      "line 2",
      "line 3",
      "line 4",
      "line 5",
      "line 6",
      "line 7",
      "line 8",
      "line 9",
      "line 10",
    })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    viewport = require('luxmotion.core.viewport')
    viewport.invalidate_cache()
  end)

  it('exports all required functions', function()
    assert.is_type(viewport.get_height, 'function')
    assert.is_type(viewport.get_width, 'function')
    assert.is_type(viewport.get_topline, 'function')
    assert.is_type(viewport.get_cursor_position, 'function')
    assert.is_type(viewport.set_cursor_position, 'function')
    assert.is_type(viewport.restore_view, 'function')
    assert.is_type(viewport.get_line_count, 'function')
    assert.is_type(viewport.get_line_length, 'function')
    assert.is_type(viewport.clamp_line, 'function')
    assert.is_type(viewport.clamp_column, 'function')
    assert.is_type(viewport.invalidate_cache, 'function')
  end)

  it('get_height returns window height', function()
    assert.equals(viewport.get_height(), 40)
  end)

  it('get_width returns window width', function()
    assert.equals(viewport.get_width(), 120)
  end)

  it('get_topline returns first visible line', function()
    assert.equals(viewport.get_topline(), 1)
    mocks.set_topline(5)
    viewport.invalidate_cache()
    assert.equals(viewport.get_topline(), 5)
  end)

  it('get_cursor_position returns current cursor', function()
    mocks.set_cursor(3, 5)
    local pos = viewport.get_cursor_position()
    assert.equals(pos[1], 3)
    assert.equals(pos[2], 5)
  end)

  it('set_cursor_position updates cursor', function()
    viewport.set_cursor_position(5, 2)
    local cursor = mocks.get_cursor()
    assert.equals(cursor[1], 5)
    assert.equals(cursor[2], 2)
  end)

  it('set_cursor_position clamps line to valid range', function()
    viewport.set_cursor_position(100, 0)
    local cursor = mocks.get_cursor()
    assert.equals(cursor[1], 10)
  end)

  it('set_cursor_position clamps line to minimum 1', function()
    viewport.set_cursor_position(0, 0)
    local cursor = mocks.get_cursor()
    assert.equals(cursor[1], 1)
  end)

  it('set_cursor_position clamps column to line length', function()
    mocks.set_buffer_content({ "abc", "defgh", "ij" })
    viewport.set_cursor_position(1, 100)
    local cursor = mocks.get_cursor()
    assert.equals(cursor[2], 2)
  end)

  it('set_cursor_position clamps column to minimum 0', function()
    viewport.set_cursor_position(1, -5)
    local cursor = mocks.get_cursor()
    assert.equals(cursor[2], 0)
  end)

  it('get_line_count returns buffer line count', function()
    assert.equals(viewport.get_line_count(), 10)
  end)

  it('get_line_length returns length of specified line', function()
    mocks.set_buffer_content({ "abc", "defgh", "ij" })
    assert.equals(viewport.get_line_length(1), 3)
    assert.equals(viewport.get_line_length(2), 5)
    assert.equals(viewport.get_line_length(3), 2)
  end)

  it('get_line_length returns 0 for empty line', function()
    mocks.set_buffer_content({ "", "abc", "" })
    assert.equals(viewport.get_line_length(1), 0)
    assert.equals(viewport.get_line_length(3), 0)
  end)

  it('clamp_line clamps to valid range', function()
    assert.equals(viewport.clamp_line(1), 1)
    assert.equals(viewport.clamp_line(5), 5)
    assert.equals(viewport.clamp_line(10), 10)
    assert.equals(viewport.clamp_line(0), 1)
    assert.equals(viewport.clamp_line(-5), 1)
    assert.equals(viewport.clamp_line(15), 10)
    assert.equals(viewport.clamp_line(100), 10)
  end)

  it('clamp_column clamps to valid range', function()
    mocks.set_buffer_content({ "abcdef" })
    assert.equals(viewport.clamp_column(0, 1), 0)
    assert.equals(viewport.clamp_column(3, 1), 3)
    assert.equals(viewport.clamp_column(5, 1), 5)
    assert.equals(viewport.clamp_column(-1, 1), 0)
    assert.equals(viewport.clamp_column(100, 1), 5)
  end)

  it('clamp_column handles empty line', function()
    mocks.set_buffer_content({ "" })
    assert.equals(viewport.clamp_column(0, 1), 0)
    assert.equals(viewport.clamp_column(5, 1), 0)
  end)

  it('invalidate_cache allows cache refresh', function()
    local height1 = viewport.get_height()
    assert.is_type(height1, 'number')
    viewport.invalidate_cache()
    local height2 = viewport.get_height()
    assert.is_type(height2, 'number')
  end)

  it('restore_view sets topline and cursor', function()
    viewport.restore_view(5, 10, 3)
    local fn_state = mocks.get_fn_state()
    assert.equals(fn_state.topline, 5)
  end)
end)
