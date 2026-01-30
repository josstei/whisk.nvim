local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('calculators/scroll', function()
  local scroll

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()

    local lines = {}
    for i = 1, 100 do
      table.insert(lines, "line " .. i)
    end
    mocks.set_buffer_content(lines)
    mocks.set_cursor(50, 0)
    mocks.set_window_size(20, 80)
    mocks.set_topline(40)

    scroll = require('luxmotion.calculators.scroll')
  end)

  it('exports scroll functions', function()
    assert.is_type(scroll.ctrl_d, 'function')
    assert.is_type(scroll.ctrl_u, 'function')
    assert.is_type(scroll.ctrl_f, 'function')
    assert.is_type(scroll.ctrl_b, 'function')
    assert.is_type(scroll.zz, 'function')
    assert.is_type(scroll.zt, 'function')
    assert.is_type(scroll.zb, 'function')
  end)

  it('ctrl_d scrolls down half page', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_d(ctx)

    assert.is_not_nil(result.cursor)
    assert.is_not_nil(result.viewport)
    assert.greater_than(result.cursor.line, 50)
    assert.greater_than(result.viewport.topline, 40)
  end)

  it('ctrl_d with count scrolls', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      viewport = { topline = 40, height = 20 },
      input = { count = 5 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_d(ctx)

    assert.greater_than(result.cursor.line, 50)
  end)

  it('ctrl_d clamps to last line', function()
    local ctx = {
      cursor = { line = 95, col = 0 },
      viewport = { topline = 85, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_d(ctx)

    assert.less_or_equal(result.cursor.line, 100)
  end)

  it('ctrl_u scrolls up half page', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_u(ctx)

    assert.is_not_nil(result.cursor)
    assert.is_not_nil(result.viewport)
    assert.less_than(result.cursor.line, 50)
    assert.less_than(result.viewport.topline, 40)
  end)

  it('ctrl_u with count scrolls', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      viewport = { topline = 40, height = 20 },
      input = { count = 5 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_u(ctx)

    assert.less_than(result.cursor.line, 50)
  end)

  it('ctrl_u clamps to line 1', function()
    local ctx = {
      cursor = { line = 5, col = 0 },
      viewport = { topline = 1, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_u(ctx)

    assert.greater_or_equal(result.cursor.line, 1)
    assert.greater_or_equal(result.viewport.topline, 1)
  end)

  it('ctrl_f scrolls down full page', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_f(ctx)

    assert.greater_than(result.cursor.line, 50)
    local scroll_amount = result.cursor.line - 50
    assert.greater_or_equal(scroll_amount, 10)
  end)

  it('ctrl_b scrolls up full page', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.ctrl_b(ctx)

    assert.less_than(result.cursor.line, 50)
    local scroll_amount = 50 - result.cursor.line
    assert.greater_or_equal(scroll_amount, 10)
  end)

  it('zz centers cursor in viewport', function()
    local ctx = {
      cursor = { line = 50, col = 5 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.zz(ctx)

    assert.is_not_nil(result.viewport)
    assert.is_not_nil(result.viewport.topline)
    assert.equals(result.cursor.line, 50)
    assert.equals(result.cursor.col, 5)
  end)

  it('zt moves cursor to top of viewport', function()
    local ctx = {
      cursor = { line = 50, col = 5 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.zt(ctx)

    assert.is_not_nil(result.viewport)
    assert.equals(result.cursor.line, 50)
  end)

  it('zb moves cursor to bottom of viewport', function()
    local ctx = {
      cursor = { line = 50, col = 5 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local result = scroll.zb(ctx)

    assert.is_not_nil(result.viewport)
    assert.equals(result.cursor.line, 50)
  end)

  it('scroll functions preserve column', function()
    local ctx = {
      cursor = { line = 50, col = 7 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }

    local d_result = scroll.ctrl_d(ctx)
    assert.equals(d_result.cursor.col, 7)

    local u_result = scroll.ctrl_u(ctx)
    assert.equals(u_result.cursor.col, 7)
  end)

  it('position functions preserve column', function()
    local ctx = {
      cursor = { line = 50, col = 3 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }

    local zz_result = scroll.zz(ctx)
    assert.equals(zz_result.cursor.col, 3)

    local zt_result = scroll.zt(ctx)
    assert.equals(zt_result.cursor.col, 3)

    local zb_result = scroll.zb(ctx)
    assert.equals(zb_result.cursor.col, 3)
  end)

  it('ctrl_f and ctrl_b are complementary', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      viewport = { topline = 40, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }

    local f_result = scroll.ctrl_f(ctx)
    local new_ctx = {
      cursor = { line = f_result.cursor.line, col = 0 },
      viewport = { topline = f_result.viewport.topline, height = 20 },
      input = { count = 1 },
      buffer = { line_count = 100 },
    }
    local b_result = scroll.ctrl_b(new_ctx)

    local diff = math.abs(b_result.cursor.line - 50)
    assert.less_or_equal(diff, 5)
  end)
end)
