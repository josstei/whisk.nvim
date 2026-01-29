local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('calculators/word', function()
  local word

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "hello world foo bar",
      "second line here",
      "third_word another-word",
    })
    mocks.set_cursor(1, 0)
    word = require('luxmotion.calculators.word')
  end)

  it('exports w, b, e, W, B, E functions', function()
    assert.is_type(word.w, 'function')
    assert.is_type(word.b, 'function')
    assert.is_type(word.e, 'function')
    assert.is_type(word.W, 'function')
    assert.is_type(word.B, 'function')
    assert.is_type(word.E, 'function')
  end)

  it('w returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 3 },
    }
    local result = word.w(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
    assert.is_type(result.cursor.line, 'number')
    assert.is_type(result.cursor.col, 'number')
  end)

  it('b returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 10 },
      input = { count = 1 },
      buffer = { line_count = 3 },
    }
    local result = word.b(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('e returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 3 },
    }
    local result = word.e(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('W returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 3 },
    }
    local result = word.W(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('B returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 15 },
      input = { count = 1 },
      buffer = { line_count = 3 },
    }
    local result = word.B(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('E returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 3 },
    }
    local result = word.E(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('w with count moves multiple words', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 3 },
      buffer = { line_count = 3 },
    }
    local result = word.w(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('b with count moves multiple words back', function()
    mocks.set_cursor(1, 15)
    local ctx = {
      cursor = { line = 1, col = 15 },
      input = { count = 2 },
      buffer = { line_count = 3 },
    }
    local result = word.b(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('word motions handle edge cases gracefully', function()
    mocks.set_buffer_content({ "" })
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 1 },
    }

    assert.does_not_throw(function()
      word.w(ctx)
    end)

    assert.does_not_throw(function()
      word.b(ctx)
    end)

    assert.does_not_throw(function()
      word.e(ctx)
    end)
  end)

  it('w at end of buffer returns valid position', function()
    mocks.set_buffer_content({ "abc" })
    mocks.set_cursor(1, 2)
    local ctx = {
      cursor = { line = 1, col = 2 },
      input = { count = 10 },
      buffer = { line_count = 1 },
    }
    local result = word.w(ctx)

    assert.is_not_nil(result.cursor)
    assert.greater_or_equal(result.cursor.line, 1)
  end)

  it('b at start of buffer returns valid position', function()
    mocks.set_cursor(1, 0)
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 10 },
      buffer = { line_count = 3 },
    }
    local result = word.b(ctx)

    assert.is_not_nil(result.cursor)
    assert.greater_or_equal(result.cursor.line, 1)
  end)
end)
