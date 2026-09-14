local harness = require("harness")
local helpers = require("helpers")
local describe, it, before_each = harness.describe, harness.it, harness.before_each
local assert = harness.assert

local LINES = 1000

local function on_intermediate_line()
  local line = vim.fn.line(".")
  return line > 1 and line < LINES
end

describe("input that follows a motion", function()
  before_each(function()
    helpers.fresh_buffer(helpers.numbered_lines(LINES))
    require("whisk").setup({ cursor = { duration = 1000 }, scroll = { duration = 1000 } })
  end)

  it("a replayed macro edits at the motion target", function()
    vim.fn.setreg("q", "jdd")
    harness.input("@q")
    harness.settle()
    assert.equals(helpers.missing_numbered_lines(LINES), "line 2")
  end)

  it(":normal with a trailing edit edits at the motion target", function()
    harness.input(":normal jdd<CR>")
    harness.settle()
    assert.equals(helpers.missing_numbered_lines(LINES), "line 2")
  end)

  it("a feedkeys chain edits at the motion target", function()
    vim.api.nvim_feedkeys("Gdd", "mx", false)
    harness.settle()
    assert.equals(helpers.missing_numbered_lines(LINES), "line " .. LINES)
  end)

  it("code reading the cursor right after :normal sees the motion target", function()
    vim.cmd("normal G")
    assert.equals(vim.api.nvim_win_get_cursor(0)[1], LINES)
    harness.settle()
  end)

  it("a typed motion still animates through intermediate lines", function()
    harness.input("G")
    harness.wait_until(on_intermediate_line, 900, "G never passed through an intermediate line")
    harness.settle()
    assert.equals(vim.fn.line("."), LINES)
  end)

  it("a key typed during the animation edits at the motion target", function()
    harness.input("G")
    harness.wait_until(on_intermediate_line, 900, "G never passed through an intermediate line")
    harness.input("dd")
    harness.settle()
    assert.equals(helpers.missing_numbered_lines(LINES), "line " .. LINES)
  end)
end)
