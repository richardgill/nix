vim.pack.add({
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
})

local nix_parser_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'nix-treesitter')
if vim.uv.fs_stat(nix_parser_dir) then
  vim.opt.runtimepath:prepend(nix_parser_dir)
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo[ev.buf].indentexpr = ''
    end
  end,
})

-- textobjects
require('nvim-treesitter-textobjects').setup {
  select = {
    lookahead = true,
    selection_modes = {
      ['@function.outer'] = 'v',
    },
    include_surrounding_whitespace = true,
  },
  move = {
    set_jumps = true,
  },
}

local ts_select = require('nvim-treesitter-textobjects.select')
local ts_move = require('nvim-treesitter-textobjects.move')

-- textobject select keymaps
vim.keymap.set({ 'x', 'o' }, 'af', function() ts_select.select_textobject('@function.outer') end)
vim.keymap.set({ 'x', 'o' }, 'if', function() ts_select.select_textobject('@function.inner') end)
vim.keymap.set({ 'x', 'o' }, 'aa', function() ts_select.select_textobject('@parameter.outer') end)
vim.keymap.set({ 'x', 'o' }, 'ia', function() ts_select.select_textobject('@parameter.inner') end)

-- textobject move keymaps
vim.keymap.set({ 'n', 'x', 'o' }, ']m', function() ts_move.goto_next_start('@function.outer') end)
vim.keymap.set({ 'n', 'x', 'o' }, ']M', function() ts_move.goto_next_end('@function.outer') end)
vim.keymap.set({ 'n', 'x', 'o' }, '[m', function() ts_move.goto_previous_start('@function.outer') end)
vim.keymap.set({ 'n', 'x', 'o' }, '[M', function() ts_move.goto_previous_end('@function.outer') end)

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    if pcall(vim.treesitter.get_parser) then
      vim.opt_local.foldmethod = 'expr'
      vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end
  end,
})
