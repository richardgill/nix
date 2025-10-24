-- LEARNING: turn off mouse whilst
-- vim.opt.mouse = ''
-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Tab related settings
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Enable auto indentation
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Regular absolute line number
vim.opt.number = true

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- the folder defaults to: ~/.local/share/nvim/{undo,swp,backup}
local data_path = vim.fn.stdpath 'data'
local undo_dir = data_path .. '/undo'
local backup_dir = data_path .. '/backup'
local swap_dir = data_path .. '/swp'

-- neovim doesn't automatically create these folder, and the features don't work if the folders aren't
for _, dir in ipairs { undo_dir, backup_dir, swap_dir } do
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

-- double slash // stores the files in a flat file instead of nested folders
vim.opt.undodir = undo_dir .. '//'
vim.opt.backupdir = backup_dir .. '//'
vim.opt.directory = swap_dir .. '//'

-- Save undo history
vim.opt.undofile = true
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.swapfile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- The session things to persist (used in autosession plugin)
vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 8

-- Blinking cursor
vim.opt.guicursor = {
  'n-v-c:block-Cursor/lCursor-blinkwait1000-blinkon100-blinkoff100',
  'i-ci:ver25-Cursor/lCursor-blinkwait1000-blinkon100-blinkoff100',
  'r:hor50-Cursor/lCursor-blinkwait100-blinkon100-blinkoff100',
}

-- Disable netrw
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- Highlight search results
vim.opt.hlsearch = true

-- Automatically reload files when changed outside of Neovim (if buffer not modified)
vim.opt.autoread = true

-- folds are defaulted to 'indent' mode. Treesitter will take over if loaded for filetype
vim.opt.foldmethod = 'indent'

-- Adds an extra column on the left for seeing fold information
vim.opt.foldcolumn = '0'

-- Unfolded by default
vim.opt.foldenable = true

-- Which level is folded when a buffer is opened (very high numbers, mean not folded by default)
vim.opt.foldlevelstart = 99

-- Enable syntax highlighting on the first line
vim.opt.foldtext = ''

-- Max level to allow folds to.
vim.opt.foldnestmax = 4

vim.o.updatetime = 250
vim.diagnostic.config {
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = false,
}

vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = {
    source = 'if_many',
    spacing = 2,
    format = function(diagnostic)
      local diagnostic_message = {
        [vim.diagnostic.severity.ERROR] = diagnostic.message,
        [vim.diagnostic.severity.WARN] = diagnostic.message,
        [vim.diagnostic.severity.INFO] = diagnostic.message,
        [vim.diagnostic.severity.HINT] = diagnostic.message,
      }
      return diagnostic_message[diagnostic.severity]
    end,
  },
}

vim.g.node_host_prog = vim.fn.system('mise x -C ~/.config/nvim -- which node'):gsub('\n', '')
