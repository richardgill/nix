-- when running `nvim my/folder` sets cwd to be my/folder
-- https://www.reddit.com/r/neovim/comments/t26htu/comment/hynjpru/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
IS_OPENED_TO_DIR = vim.fn.isdirectory(vim.v.argv[3]) == 1
if IS_OPENED_TO_DIR then
  vim.api.nvim_set_current_dir(vim.v.argv[3])
end

require 'config.keymap'
require 'config.options'
require 'config.autocommand'
require 'config.lazy'
require 'config.spelling'
