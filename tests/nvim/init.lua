local dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h") .. "/"
local repo = vim.fn.fnamemodify(dir .. "../..", ":p")

vim.opt.runtimepath:prepend(repo)
vim.g.whisk_auto_setup = 0
vim.o.shada = ""
vim.o.swapfile = false
package.path = dir .. "?.lua;" .. package.path

local harness = require("harness")

local specs = vim.fn.globpath(dir .. "specs", "*_spec.lua", false, true)
table.sort(specs)

for _, spec in ipairs(specs) do
  local ok, err = pcall(dofile, spec)
  if not ok then
    harness.record_load_error(spec, err)
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(harness.run)
  end,
})
