local group = vim.api.nvim_create_augroup('prompt-filetype', { clear = true })

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = group,
  pattern = { '*.agent', '*.prompt', '/tmp/pi-editor-*.pi.md', '/tmp/claude-tmp/claude-prompt-*.md' },
  callback = function(event)
    vim.bo[event.buf].filetype = 'prompt'
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'yes:1'
    vim.opt_local.foldcolumn = '0'
    vim.opt_local.statuscolumn = ''
    vim.cmd 'normal! G$' -- go to end of file
    vim.cmd 'startinsert!'
    -- save and quit
    vim.keymap.set('n', '<C-g>', '<cmd>wq<cr>', { buffer = event.buf, silent = true, nowait = true })
    vim.keymap.set('i', '<C-g>', '<Esc><cmd>wq<cr>', { buffer = event.buf, silent = true, nowait = true })
  end,
})
