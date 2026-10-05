-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  desc = 'Hide line numbers in quickfix and location lists',
  group = vim.api.nvim_create_augroup('quickfix-window-options', { clear = true }),
  callback = function()
    if vim.bo.buftype ~= 'quickfix' then
      return
    end

    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.statuscolumn = ''
  end,
})
