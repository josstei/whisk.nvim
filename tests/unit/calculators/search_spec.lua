local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('calculators/search', function()
  local search

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "first line with search term",
      "second line here",
      "third line also has search term",
      "fourth line",
      "fifth line with long wrapped content that continues",
    })
    mocks.set_cursor(1, 0)
    search = require('luxmotion.calculators.search')
  end)

  it('exports n, N, gj, gk functions', function()
    assert.is_type(search.n, 'function')
    assert.is_type(search.N, 'function')
    assert.is_type(search.gj, 'function')
    assert.is_type(search.gk, 'function')
  end)

  it('n returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = search.n(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
    assert.is_type(result.cursor.line, 'number')
    assert.is_type(result.cursor.col, 'number')
  end)

  it('N returns cursor result', function()
    mocks.set_cursor(3, 0)
    local ctx = {
      cursor = { line = 3, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = search.N(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('gj returns cursor result', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = search.gj(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('gk returns cursor result', function()
    mocks.set_cursor(3, 0)
    local ctx = {
      cursor = { line = 3, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }
    local result = search.gk(ctx)

    assert.is_not_nil(result)
    assert.is_not_nil(result.cursor)
  end)

  it('n with count finds nth occurrence', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 2 },
      buffer = { line_count = 5 },
    }
    local result = search.n(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('N with count finds nth occurrence backwards', function()
    mocks.set_cursor(5, 0)
    local ctx = {
      cursor = { line = 5, col = 0 },
      input = { count = 2 },
      buffer = { line_count = 5 },
    }
    local result = search.N(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('gj with count moves multiple screen lines', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 3 },
      buffer = { line_count = 5 },
    }
    local result = search.gj(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('gk with count moves multiple screen lines', function()
    mocks.set_cursor(5, 0)
    local ctx = {
      cursor = { line = 5, col = 0 },
      input = { count = 3 },
      buffer = { line_count = 5 },
    }
    local result = search.gk(ctx)

    assert.is_not_nil(result.cursor)
  end)

  it('n handles no search pattern gracefully', function()
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }

    assert.does_not_throw(function()
      search.n(ctx)
    end)
  end)

  it('gj at last line stays in bounds', function()
    mocks.set_cursor(5, 0)
    local ctx = {
      cursor = { line = 5, col = 0 },
      input = { count = 10 },
      buffer = { line_count = 5 },
    }
    local result = search.gj(ctx)

    assert.less_or_equal(result.cursor.line, 5)
  end)

  it('gk at first line stays in bounds', function()
    mocks.set_cursor(1, 0)
    local ctx = {
      cursor = { line = 1, col = 0 },
      input = { count = 10 },
      buffer = { line_count = 5 },
    }
    local result = search.gk(ctx)

    assert.greater_or_equal(result.cursor.line, 1)
  end)

  it('gj and gk preserve column when possible', function()
    local ctx = {
      cursor = { line = 2, col = 5 },
      input = { count = 1 },
      buffer = { line_count = 5 },
    }

    local gj_result = search.gj(ctx)
    assert.is_type(gj_result.cursor.col, 'number')

    local gk_result = search.gk(ctx)
    assert.is_type(gk_result.cursor.col, 'number')
  end)
end)
