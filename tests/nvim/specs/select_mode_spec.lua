local harness = require("harness")
local helpers = require("helpers")
local describe, it, before_each = harness.describe, harness.it, harness.before_each
local assert = harness.assert

describe("Select mode", function()
  before_each(function()
    helpers.fresh_buffer({ "" })
    require("whisk").setup({})
  end)

  it("typing over a snippet placeholder replaces the placeholder", function()
    harness.input("i<Cmd>lua vim.snippet.expand('print(${1:value}, ${2:other})')<CR>")
    harness.wait_until(function()
      return vim.api.nvim_get_mode().mode == "s"
    end, 2000, "the snippet never selected its first placeholder")
    harness.input("hello<Esc>")
    harness.settle()
    assert.equals(vim.api.nvim_get_current_line(), "print(hello, other)")
  end)

  it("no motion key has a Select-mode mapping", function()
    local checked = 0
    for id, motion in pairs(require("whisk.registry.motions").all()) do
      for _, key in ipairs(motion.keys) do
        assert.equals(vim.fn.maparg(key, "s"), "", key .. " (" .. id .. ") is mapped in Select mode")
        checked = checked + 1
      end
    end
    assert.is_true(checked > 0, "no motion keys were registered")
  end)
end)

describe("Visual mode", function()
  before_each(function()
    helpers.fresh_buffer(helpers.numbered_lines(10))
    require("whisk").setup({})
  end)

  it("motions extend the selection", function()
    harness.input("vjj")
    harness.settle()
    assert.equals(vim.api.nvim_get_mode().mode, "v")
    assert.equals(vim.fn.line("v"), 1)
    assert.equals(vim.fn.line("."), 3)
    harness.input("<Esc>")
  end)
end)
