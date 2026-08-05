local utils = require 'custom.utils'
local yank = require 'custom.yank'

-- Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('custom.move-lines').setup()

local xata_work_queue_path = vim.fn.expand '~/code/notes/content/projects/xata/work-queue.md'

local code_diff_against = function(target)
  local command = { vim.fn.expand '~/Scripts/git-diff-base-ref', target }
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify(vim.trim(result.stderr or 'Unable to resolve Git diff base'), vim.log.levels.ERROR)
    return
  end
  vim.cmd('CodeDiff ' .. vim.trim(result.stdout) .. '...')
end

vim.keymap.set('n', '<leader>nw', function()
  local was_open = vim.fn.bufloaded(xata_work_queue_path) == 1
  vim.cmd.edit(xata_work_queue_path)
  if not was_open then
    vim.fn.search('^## Today', 'cw')
  end
end, { desc = '[N]otes [W]ork queue' })

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<Esc><Esc>', function()
  vim.fn.clearmatches()
  require('custom.agent-events').clear_highlight()
end)

-- Close a tab
vim.keymap.set('n', '<A-q>', '<cmd>tabclose<CR>')
-- Close current buffer
vim.keymap.set('n', '<A-w>', '<cmd>:bd<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1 }
end, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1 }
end, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- half screen up and down zz: center cursor
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-Down>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', '<C-Up>', '<C-u>zz')
vim.keymap.set('v', '<C-d>', '<C-d>zz')
vim.keymap.set('v', '<C-Down>', '<C-d>zz')
vim.keymap.set('v', '<C-u>', '<C-u>zz')
vim.keymap.set('v', '<C-Up>', '<C-u>zz')
-- when searching n: go to next result; zz: to center the result/cursor; zv expand all folds
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Select all
vim.keymap.set('n', '<C-a>', 'ggVG', { noremap = true, silent = true })

-- Indent and keep selection
vim.api.nvim_set_keymap('v', '>', '>gv', { noremap = true, silent = true })

-- Unindent and keep selection
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true, silent = true })

-- Always use P instead of p in visual mode. P doesn't mess with registers.
vim.api.nvim_set_keymap('v', 'p', 'P', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>dd', '<cmd>:CodeDiff<cr>', { desc = 'Git [d]iff [d]irty changes' })
vim.keymap.set('n', '<leader>db', function()
  code_diff_against 'base'
end, { desc = 'Git [d]iff against PR [b]ase' })
vim.keymap.set('n', '<leader>dm', function()
  code_diff_against 'main'
end, { desc = 'Git [d]iff against [m]ain' })

-- stop ctrl-z from suspending
vim.api.nvim_set_keymap('n', '<c-z>', '<nop>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>wh', ':vsplit<CR>', { noremap = true, silent = true, desc = '[w]indow split [h]orizontal' })
vim.keymap.set('n', '<leader>wv', ':split<CR>', { noremap = true, silent = true, desc = '[w]indow split [v]ertical' })
vim.keymap.set('n', '<leader>wb', ':enew<CR>', { noremap = true, silent = true, desc = '[w]indow new [b]uffer' })

vim.keymap.set('n', '<leader>lr', function()
  utils.restart_lsp()
end, { desc = '[L]SP [R]estart' })

vim.keymap.set('n', '<leader>ya', function()
  yank.yank_path(yank.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank [A]bsolute path to clipboard' })

vim.keymap.set('n', '<leader>yr', function()
  yank.yank_path(yank.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank [R]elative path to clipboard' })

vim.keymap.set('v', '<leader>ya', function()
  yank.yank_visual_with_path(yank.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank selection with [A]bsolute path' })

vim.keymap.set('v', '<leader>yr', function()
  yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank selection with [R]elative path' })

vim.keymap.set({ 'n', 'v' }, '<leader>go', function()
  require('snacks').gitbrowse.open()
end, { desc = '[G]ithub [O]pen file (main)' })
