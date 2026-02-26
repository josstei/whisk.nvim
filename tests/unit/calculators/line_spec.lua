local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('calculators/line', function()
  local line

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "  indented line",
      "no indent",
      "    more indent",
      "line 4",
      "line 5",
      "line 6",
      "line 7",
      "line 8",
      "line 9",
      "line 10",
    })
    mocks.set_cursor(5, 3)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    line = require('whisk.calculators.line')
  end)

  it('exports gg, G, | functions', function()
    assert.is_type(line.gg, 'function')
    assert.is_type(line.G, 'function')
    assert.is_type(line['|'], 'function')
  end)

  it('gg without count goes to line 1', function()
    local ctx = {
      cursor = { line = 5, col = 3 },
      input = { count = 1 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 10 },
    }
    local result = line.gg(ctx)
    assert.equals(result.cursor.line, 1)
  end)

  it('gg with count goes to specified line', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 7 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 10 },
    }
    local result = line.gg(ctx)
    assert.equals(result.cursor.line, 7)
  end)

  it('gg clamps to last line', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 100 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 10 },
    }
    local result = line.gg(ctx)
    assert.equals(result.cursor.line, 10)
  end)

  it('gg returns viewport adjustment', function()
    local ctx = {
      cursor = { line = 50, col = 0 },
      input = { count = 1 },
      viewport = { height = 40, topline = 40 },
      buffer = { line_count = 100 },
    }
    local result = line.gg(ctx)
    assert.is_not_nil(result.viewport)
    assert.is_not_nil(result.viewport.topline)
  end)

  it('G without explicit count goes to last line', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 10 },
    }
    _G.vim.v.count = 0
    local result = line.G(ctx)
    assert.equals(result.cursor.line, 10)
  end)

  it('G with count goes to specified line', function()
    local ctx = {
      cursor = { line = 10, col = 0 },
      input = { count = 3 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 10 },
    }
    _G.vim.v.count = 3
    local result = line.G(ctx)
    assert.equals(result.cursor.line, 3)
  end)

  it('G clamps to last line', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 500 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 10 },
    }
    _G.vim.v.count = 500
    local result = line.G(ctx)
    assert.equals(result.cursor.line, 10)
  end)

  it('G returns viewport adjustment', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 100 },
    }
    _G.vim.v.count = 0
    local result = line.G(ctx)
    assert.is_not_nil(result.viewport)
  end)

  it('| goes to column specified by count', function()
    mocks.set_buffer_content({ "hello world this is a test" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 10 },
      buffer = { line_count = 1 },
    }
    local result = line['|'](ctx)
    assert.equals(result.cursor.col, 9)
  end)

  it('| with count 1 goes to column 0', function()
    local ctx = {
      cursor = { line = 1, col = 5 },
      input = { count = 1 },
      buffer = { line_count = 10 },
    }
    local result = line['|'](ctx)
    assert.equals(result.cursor.col, 0)
  end)

  it('| goes to high column', function()
    mocks.set_buffer_content({ "abc" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 100 },
      buffer = { line_count = 1 },
    }
    local result = line['|'](ctx)
    assert.equals(result.cursor.col, 99)
  end)

  it('| preserves line number', function()
    local ctx = {
      cursor = { line = 5, col = 0 },
      input = { count = 3 },
      buffer = { line_count = 10 },
    }
    local result = line['|'](ctx)
    assert.equals(result.cursor.line, 5)
  end)

  it('gg and G preserve column appropriately', function()
    local ctx = {
      cursor = { line = 5, col = 10 },
      input = { count = 1 },
      viewport = { height = 40, topline = 1 },
      buffer = { line_count = 10 },
    }

    local gg_result = line.gg(ctx)
    assert.is_type(gg_result.cursor.col, 'number')

    _G.vim.v.count = 0
    local g_result = line.G(ctx)
    assert.is_type(g_result.cursor.col, 'number')
  end)
end)
