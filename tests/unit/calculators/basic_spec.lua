local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('calculators/basic', function()
  local basic

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "hello world",
      "second line",
      "third line",
      "fourth line",
      "fifth line",
    })
    mocks.set_cursor(3, 5)
    basic = require('whisk.calculators.basic')
  end)

  it('exports h, j, k, l, 0, $ functions', function()
    assert.is_type(basic.h, 'function')
    assert.is_type(basic.j, 'function')
    assert.is_type(basic.k, 'function')
    assert.is_type(basic.l, 'function')
    assert.is_type(basic['0'], 'function')
    assert.is_type(basic['$'], 'function')
  end)

  it('h moves cursor left by count', function()
    local ctx = {
      cursor = { line = 3, col = 5 },
      input = { count = 2 },
      buffer = { line_count = 5 },
    }
    local result = basic.h(ctx)
    assert.equals(result.cursor.line, 3)
    assert.equals(result.cursor.col, 3)
  end)

  it('h clamps to column 0', function()
    local ctx = {
      cursor = { line = 3, col = 2 },
      input = { count = 10 },
      buffer = { line_count = 5 },
    }
    local result = basic.h(ctx)
    assert.equals(result.cursor.col, 0)
  end)

  it('h with count 1', function()
    local ctx = {
      cursor = { line = 1, col = 5 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = basic.h(ctx)
    assert.equals(result.cursor.col, 4)
  end)

  it('j moves cursor down by count', function()
    local ctx = {
      cursor = { line = 2, col = 0 },
      input = { count = 2 },
      buffer = { line_count = 5 },
    }
    local result = basic.j(ctx)
    assert.equals(result.cursor.line, 4)
    assert.equals(result.cursor.col, 0)
  end)

  it('j clamps to last line', function()
    local ctx = {
      cursor = { line = 4, col = 0 },
      input = { count = 10 },
      buffer = { line_count = 5 },
    }
    local result = basic.j(ctx)
    assert.equals(result.cursor.line, 5)
  end)

  it('j with count 1', function()
    local ctx = {
      cursor = { line = 1, col = 3 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = basic.j(ctx)
    assert.equals(result.cursor.line, 2)
  end)

  it('k moves cursor up by count', function()
    local ctx = {
      cursor = { line = 4, col = 0 },
      input = { count = 2 },
      buffer = { line_count = 5 },
    }
    local result = basic.k(ctx)
    assert.equals(result.cursor.line, 2)
    assert.equals(result.cursor.col, 0)
  end)

  it('k clamps to line 1', function()
    local ctx = {
      cursor = { line = 2, col = 0 },
      input = { count = 10 },
      buffer = { line_count = 5 },
    }
    local result = basic.k(ctx)
    assert.equals(result.cursor.line, 1)
  end)

  it('k with count 1', function()
    local ctx = {
      cursor = { line = 5, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = basic.k(ctx)
    assert.equals(result.cursor.line, 4)
  end)

  it('l moves cursor right by count', function()
    mocks.set_buffer_content({ "hello world" })
    local ctx = {
      cursor = { line = 1, col = 2 },
      input = { count = 3 },
      buffer = { line_count = 1 },
    }
    local result = basic.l(ctx)
    assert.equals(result.cursor.line, 1)
    assert.equals(result.cursor.col, 5)
  end)

  it('l clamps to line length - 1', function()
    mocks.set_buffer_content({ "abc" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 100 },
      buffer = { line_count = 1 },
    }
    local result = basic.l(ctx)
    assert.equals(result.cursor.col, 2)
  end)

  it('l with count 1', function()
    mocks.set_buffer_content({ "hello" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 1 },
    }
    local result = basic.l(ctx)
    assert.equals(result.cursor.col, 1)
  end)

  it('0 moves to start of line', function()
    local ctx = {
      cursor = { line = 2, col = 8 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = basic['0'](ctx)
    assert.equals(result.cursor.line, 2)
    assert.equals(result.cursor.col, 0)
  end)

  it('0 from column 0 stays at 0', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = basic['0'](ctx)
    assert.equals(result.cursor.col, 0)
  end)

  it('$ moves to end of line', function()
    mocks.set_buffer_content({ "hello world" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 1 },
    }
    local result = basic['$'](ctx)
    assert.equals(result.cursor.line, 1)
    assert.equals(result.cursor.col, 10)
  end)

  it('$ on empty line returns col 0', function()
    mocks.set_buffer_content({ "" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 1 },
    }
    local result = basic['$'](ctx)
    assert.equals(result.cursor.col, 0)
  end)

  it('$ from end stays at end', function()
    mocks.set_buffer_content({ "abc" })
    local ctx = {
      cursor = { line = 1, col = 2 },
      input = { count = 1 },
      buffer = { line_count = 1 },
    }
    local result = basic['$'](ctx)
    assert.equals(result.cursor.col, 2)
  end)

  it('preserves line for horizontal movements', function()
    mocks.set_buffer_content({ "hello", "world" })
    local ctx = {
      cursor = { line = 2, col = 3 },
      input = { count = 1 },
      buffer = { line_count = 2 },
    }

    local h_result = basic.h(ctx)
    assert.equals(h_result.cursor.line, 2)

    local l_result = basic.l(ctx)
    assert.equals(l_result.cursor.line, 2)
  end)

  it('preserves column for vertical movements', function()
    mocks.set_buffer_content({ "hello", "world", "foo" })
    local ctx = {
      cursor = { line = 2, col = 3 },
      input = { count = 1 },
      buffer = { line_count = 3 },
    }

    local j_result = basic.j(ctx)
    assert.equals(j_result.cursor.col, 3)

    local k_result = basic.k(ctx)
    assert.equals(k_result.cursor.col, 3)
  end)
end)
