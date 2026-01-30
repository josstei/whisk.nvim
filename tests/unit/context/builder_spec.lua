local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('context/builder', function()
  local builder

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
    mocks.set_cursor(3, 2)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)
    builder = require('luxmotion.context.builder')
  end)

  it('exports build function', function()
    assert.is_not_nil(builder.build)
    assert.is_type(builder.build, 'function')
  end)

  it('build returns context with cursor position', function()
    local ctx = builder.build({})
    assert.is_not_nil(ctx.cursor)
    assert.equals(ctx.cursor.line, 3)
    assert.equals(ctx.cursor.col, 2)
  end)

  it('build returns context with viewport info', function()
    local ctx = builder.build({})
    assert.is_not_nil(ctx.viewport)
    assert.equals(ctx.viewport.topline, 1)
    assert.equals(ctx.viewport.height, 40)
    assert.equals(ctx.viewport.width, 120)
  end)

  it('build returns context with buffer info', function()
    local ctx = builder.build({})
    assert.is_not_nil(ctx.buffer)
    assert.equals(ctx.buffer.line_count, 5)
  end)

  it('build returns context with input', function()
    local input = { count = 5, char = 'f', direction = 'forward' }
    local ctx = builder.build(input)
    assert.is_not_nil(ctx.input)
    assert.equals(ctx.input.count, 5)
    assert.equals(ctx.input.char, 'f')
    assert.equals(ctx.input.direction, 'forward')
  end)

  it('build defaults count to 1', function()
    local ctx = builder.build({})
    assert.equals(ctx.input.count, 1)
  end)

  it('build preserves provided count', function()
    local ctx = builder.build({ count = 10 })
    assert.equals(ctx.input.count, 10)
  end)

  it('build requires input parameter', function()
    assert.throws(function()
      builder.build(nil)
    end)
  end)

  it('build with empty input returns valid context', function()
    local ctx = builder.build({})
    assert.is_not_nil(ctx)
    assert.is_not_nil(ctx.cursor)
    assert.is_not_nil(ctx.viewport)
    assert.is_not_nil(ctx.buffer)
    assert.is_not_nil(ctx.input)
  end)

  it('build reflects current cursor position', function()
    mocks.set_cursor(1, 0)
    local ctx1 = builder.build({})
    assert.equals(ctx1.cursor.line, 1)
    assert.equals(ctx1.cursor.col, 0)

    mocks.set_cursor(5, 4)
    local ctx2 = builder.build({})
    assert.equals(ctx2.cursor.line, 5)
    assert.equals(ctx2.cursor.col, 4)
  end)

  it('build reflects current window size', function()
    mocks.set_window_size(80, 200)
    require('luxmotion.core.viewport').invalidate_cache()
    local ctx = builder.build({})
    assert.equals(ctx.viewport.height, 80)
    assert.equals(ctx.viewport.width, 200)
  end)

  it('build reflects current topline', function()
    mocks.set_topline(10)
    require('luxmotion.core.viewport').invalidate_cache()
    local ctx = builder.build({})
    assert.equals(ctx.viewport.topline, 10)
  end)

  it('build reflects current buffer line count', function()
    mocks.set_buffer_content({ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" })
    require('luxmotion.core.viewport').invalidate_cache()
    local ctx = builder.build({})
    assert.equals(ctx.buffer.line_count, 10)
  end)

  it('build handles all input fields', function()
    local input = {
      count = 3,
      char = 'x',
      direction = 'backward',
      extra = 'ignored',
    }
    local ctx = builder.build(input)
    assert.equals(ctx.input.count, 3)
    assert.equals(ctx.input.char, 'x')
    assert.equals(ctx.input.direction, 'backward')
  end)
end)
