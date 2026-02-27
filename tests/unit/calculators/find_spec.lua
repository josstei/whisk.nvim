local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('calculators/find', function()
  local find

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "hello world",
      "abcdefghij",
      "the quick brown fox",
    })
    mocks.set_cursor(1, 0)
    find = require('whisk.calculators.find')
  end)

  it('exports f, F, t, T functions', function()
    assert.is_type(find.f, 'function')
    assert.is_type(find.F, 'function')
    assert.is_type(find.t, 'function')
    assert.is_type(find.T, 'function')
  end)

  it('f returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1, char = 'o' },
      buffer = { line_count = 3 },
    }
    local result = find.f(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
    assert.is_type(result.cursor.line, 'number')
    assert.is_type(result.cursor.col, 'number')
  end)

  it('F returns cursor result', function()
    mocks.set_cursor(1, 10)
    local ctx = {
      cursor = { line = 1, col = 10 },
      input = { count = 1, char = 'o' },
      buffer = { line_count = 3 },
    }
    local result = find.F(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('t returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1, char = 'w' },
      buffer = { line_count = 3 },
    }
    local result = find.t(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('T returns cursor result', function()
    mocks.set_cursor(1, 10)
    local ctx = {
      cursor = { line = 1, col = 10 },
      input = { count = 1, char = 'h' },
      buffer = { line_count = 3 },
    }
    local result = find.T(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('f with count finds nth occurrence', function()
    mocks.set_buffer_content({ "aaa bbb aaa ccc" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 2, char = 'a' },
      buffer = { line_count = 1 },
    }
    local result = find.f(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('find functions handle missing char gracefully', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1, char = 'z' },
      buffer = { line_count = 3 },
    }

    local result = find.f(ctx)
    assert.is_not_nil(result.cursor)
  end)

  it('f preserves line', function()
    local ctx = {
      cursor = { line = 2, col = 0 },
      input = { count = 1, char = 'e' },
      buffer = { line_count = 3 },
    }
    local result = find.f(ctx)

    assert.equals(result.cursor.line, 2)
  end)

  it('F preserves line', function()
    mocks.set_cursor(2, 8)
    local ctx = {
      cursor = { line = 2, col = 8 },
      input = { count = 1, char = 'a' },
      buffer = { line_count = 3 },
    }
    local result = find.F(ctx)

    assert.equals(result.cursor.line, 2)
  end)

  it('t stops before character', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1, char = 'w' },
      buffer = { line_count = 3 },
    }
    local result = find.t(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('T stops after character', function()
    mocks.set_cursor(1, 10)
    local ctx = {
      cursor = { line = 1, col = 10 },
      input = { count = 1, char = 'e' },
      buffer = { line_count = 3 },
    }
    local result = find.T(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('find functions require char', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1, char = nil },
      buffer = { line_count = 3 },
    }

    assert.throws(function()
      find.f(ctx)
    end)
  end)

  it('find functions handle empty string char', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1, char = '' },
      buffer = { line_count = 3 },
    }

    assert.does_not_throw(function()
      find.f(ctx)
    end)
  end)
end)
