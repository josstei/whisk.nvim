local harness = require("harness")
local helpers = require("helpers")
local describe, it, before_each = harness.describe, harness.it, harness.before_each
local assert = harness.assert

describe("integration harness", function()
  before_each(function()
    helpers.fresh_buffer(helpers.numbered_lines(20))
    require("whisk").setup({})
  end)

  it("typed 5j lands on line 6 through the installed keymap", function()
    harness.input("5j")
    harness.settle()
    assert.equals(vim.api.nvim_win_get_cursor(0)[1], 6)
  end)
end)
