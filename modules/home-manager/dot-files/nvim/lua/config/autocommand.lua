-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Auto-check for file changes on focus, idle, etc.
-- lazyvim has a lesser version of this https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/config/autocmds.lua#L7
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI', 'TermLeave', 'WinEnter' }, {
  group = vim.api.nvim_create_augroup('auto_checktime', { clear = true }),
  callback = function()
    local mode = vim.api.nvim_get_mode().mode
    if mode:match '[cR!s]' or vim.fn.getcmdwintype() ~= '' or vim.o.buftype ~= '' then
      return
    end
    vim.cmd 'checktime'
  end,
  desc = 'Reload buffer if file changed externally',
})
