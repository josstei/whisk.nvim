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

  it("a view change made right after a scripted motion survives the replay", function()
    vim.cmd("normal G")
    vim.fn.winrestview({ topline = 990 })
    harness.settle()
    assert.equals(vim.fn.line("w0"), 990)
    assert.equals(vim.fn.line("."), LINES)
  end)
end)

describe("input that follows a motion whose animation is disabled", function()
  before_each(function()
    helpers.fresh_buffer(helpers.numbered_lines(LINES))
    require("whisk").setup({ cursor = { enabled = false }, scroll = { enabled = false } })
  end)

  it("typed keys after the motion run after it", function()
    harness.input("5Gdd")
    harness.settle()
    assert.equals(helpers.missing_numbered_lines(LINES), "line 5")
  end)

  it("a replayed macro runs its keys in order", function()
    vim.fn.setreg("q", "5Gdd")
    harness.input("@q")
    harness.settle()
    assert.equals(helpers.missing_numbered_lines(LINES), "line 5")
  end)

  it(":normal runs its keys in order", function()
    harness.input(":normal 5Gdd<CR>")
    harness.settle()
    assert.equals(helpers.missing_numbered_lines(LINES), "line 5")
  end)

  it("an Insert-mode <C-o> motion returns to Insert mode", function()
    helpers.fresh_buffer({ "hello" })
    require("whisk").setup({ cursor = { enabled = false }, scroll = { enabled = false } })
    harness.input("i<C-o>$X<Esc>")
    harness.settle()
    assert.equals(vim.api.nvim_get_current_line(), "helloX")
  end)
end)

describe("a trait that fails while landing", function()
  before_each(function()
    helpers.fresh_buffer(helpers.numbered_lines(LINES))
    require("whisk").setup({ cursor = { duration = 1000 } })
    vim.g.whisk_spec_fail_landing = false
    require("whisk.registry.traits").register({
      id = "spec_fails_on_landing",
      apply = function(_, _, progress)
        if progress == 1.0 and vim.g.whisk_spec_fail_landing then
          error("spec trait failed while landing")
        end
      end,
    })
    require("whisk.registry.motions").register({
      id = "spec_far_down",
      keys = { "<F7>" },
      traits = { "cursor", "spec_fails_on_landing" },
      category = "cursor",
      calculator = function()
        return { cursor = { line = 500, col = 0 } }
      end,
    })
    vim.keymap.set("n", "<F7>", function()
      require("whisk.engine.orchestrator").execute("spec_far_down", { count = 1 })
    end)
  end)

  it("the key that interrupts the replay still runs and the error is reported", function()
    harness.input("<F7>")
    harness.wait_until(function()
      local line = vim.fn.line(".")
      return line > 1 and line < 500
    end, 900, "the replay never passed through an intermediate line")
    vim.g.whisk_spec_fail_landing = true
    harness.input("k")
    harness.settle()
    vim.g.whisk_spec_fail_landing = false
    assert.equals(vim.fn.line("."), 499)
    assert.is_true(vim.fn.execute("messages"):find("spec trait failed while landing", 1, true) ~= nil,
      "the landing error was not reported")
  end)
end)
