local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('context/Context', function()
  local Context

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content({
      "line 1",
      "line 2",
      "line 3",
      "line 4",
      "line 5",
    })
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    Context = require('luxmotion.context.Context')
  end)

  it('new() creates a Context with bufnr and winid', function()
    local ctx = Context.new(1, 1000)
    assert.equals(ctx.bufnr, 1)
    assert.equals(ctx.winid, 1000)
  end)

  it('new() captures starting state', function()
    mocks.set_cursor(3, 5)
    mocks.set_topline(2)
    local ctx = Context.new(1, 1000)
    assert.equals(ctx.start.cursor[1], 3)
    assert.equals(ctx.start.cursor[2], 5)
    assert.equals(ctx.start.topline, 2)
    assert.equals(ctx.start.line_count, 5)
  end)

  it('new() uses current buffer and window if not provided', function()
    local ctx = Context.new()
    assert.is_type(ctx.bufnr, 'number')
    assert.is_type(ctx.winid, 'number')
  end)
end)
