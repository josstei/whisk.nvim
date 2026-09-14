-- nvim --headless -u NONE -l tests/real_input.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.o.swapfile = false
local whisk = require('whisk')
local loop = require('whisk.engine.loop')
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'xt', false)
end
local function reset()
  whisk.reset()
  vim.cmd('enew!')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'first', 'middle', 'last' })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
end
local function state()
  return { vim.api.nvim_buf_get_lines(0, 0, -1, false), vim.api.nvim_win_get_cursor(0) }
end
for _, keys in ipairs({ 'Goafter<Esc>', 'ggIbefore<Esc>', 'Gdd', '2ggdd', 'GggIstart<Esc>' }) do
  reset()
  feed(keys)
  local expected = state()
  reset()
  whisk.setup({})
  feed(keys)
  vim.wait(250, function() return false end)
  assert(vim.deep_equal(expected, state()), keys .. ': ' .. vim.inspect(state()))
  assert(loop.get_active_count() == 0)
end
reset()
whisk.setup({})
feed('G')
assert(loop.get_active_count() == 1, 'idle motion should still animate')
feed('gg')
assert(loop.get_active_count() == 1, 'replacement motion should animate')
feed('Istart<Esc>')
local edited = state()
vim.wait(250, function() return false end)
assert(vim.deep_equal(edited, state()), 'stale timer changed edited position')

for _, setup in ipairs({
  function() vim.fn.setreg('a', 'Goafter\027'); return '@a' end,
  function() vim.keymap.set('n', '<F5>', 'Goafter<Esc>', { remap = true }); return '<F5>' end,
}) do
  reset()
  whisk.setup({})
  feed(setup())
  assert(vim.api.nvim_buf_get_lines(0, -2, -1, false)[1] == 'after')
end

reset()
whisk.setup({})
feed('G')
vim.cmd('enew!')
assert(loop.get_active_count() == 0)
assert(not require('whisk.registry.traits').is_animating('cursor'))
whisk.reset()
vim.wait(250, function() return false end)
print('Real input, macro, remap, stale frame and lifecycle checks PASS')
vim.cmd('qa!')
