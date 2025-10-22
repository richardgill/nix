local utils = require 'utils'

-- This is needed to allow using space as the leader whist in visual mode.
vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true })

-- Stop replace mode in visual mode. This is a workaround for some visual leader issues.
vim.api.nvim_set_keymap('v', 'r', '<Nop>', { noremap = true, silent = true })

-- Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- LEARNING - Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

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

-- Git diff
vim.keymap.set('n', '<leader>dd', '<cmd>:DiffviewOpen<cr>', { desc = 'Git [d]iff' })
vim.keymap.set('n', '<leader>do', function()
  local remotes_output = vim.fn.system 'git remote'
  local upstream_exists = remotes_output:find 'upstream' ~= nil
  local remote = upstream_exists and 'upstream' or 'origin'
  vim.cmd(':DiffviewOpen ' .. remote .. '/main...HEAD')
end, { desc = 'Git [d]iff against upstream/main or origin/main' })

-- stop ctrl-z from suspending
vim.api.nvim_set_keymap('n', '<c-z>', '<nop>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>wh', ':vsplit<CR>', { noremap = true, silent = true, desc = '[w]indow split [h]orizontal' })
vim.keymap.set('n', '<leader>wv', ':split<CR>', { noremap = true, silent = true, desc = '[w]indow split [v]ertical' })
vim.keymap.set('n', '<leader>wb', ':enew<CR>', { noremap = true, silent = true, desc = '[w]indow new [b]uffer' })

vim.keymap.set('n', '<leader>lr', function()
  utils.restart_lsp()
end, { desc = '[L]SP [R]estart' })

local function yank_path(path, label)
  vim.fn.setreg('+', path) -- Copy to system clipboard
  print('Yanked ' .. label .. ' path: ' .. path)
end

local function yank_visual_with_path(path, label)
  local bounds = utils.get_visual_bounds()

  local selected_lines = vim.fn.getregion(bounds.start_pos, bounds.end_pos, { type = bounds.mode })
  local selected_text = table.concat(selected_lines, '\n')

  local line_range = utils.format_line_range(bounds.start_line, bounds.end_line)
  local path_with_lines = path .. ':' .. line_range

  local result = path_with_lines .. '\n\n' .. selected_text
  vim.fn.setreg('+', result)

  utils.simulate_yank_highlight()

  utils.exit_visual_mode()

  print('Yanked ' .. label .. ' with lines ' .. line_range)
end

vim.keymap.set('n', '<leader>ya', function()
  yank_path(utils.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank [A]bsolute path to clipboard' })

vim.keymap.set('n', '<leader>yr', function()
  yank_path(utils.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank [R]elative path to clipboard' })

vim.keymap.set('v', '<leader>ya', function()
  yank_visual_with_path(utils.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank selection with [A]bsolute path' })

vim.keymap.set('v', '<leader>yr', function()
  yank_visual_with_path(utils.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank selection with [R]elative path' })

vim.keymap.set('n', '<leader>go', function()
  local file = utils.get_buffer_git_root_relative()
  vim.fn.system('git-browse ' .. file)
end, { desc = '[G]ithub [O]pen file (main)' })

vim.keymap.set('v', '<leader>go', function()
  local bounds = utils.get_visual_bounds()
  local file = utils.get_buffer_git_root_relative()
  local line_range = utils.format_line_range(bounds.start_line, bounds.end_line)
  vim.fn.system('git-browse ' .. file .. ':' .. line_range)
  utils.exit_visual_mode()
end, { desc = '[G]ithub [O]pen file at selection (main)' })
