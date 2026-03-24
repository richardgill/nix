-- when running `nvim my/folder` sets cwd to be my/folder
-- https://www.reddit.com/r/neovim/comments/t26htu/comment/hynjpru/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
IS_OPENED_TO_DIR = vim.fn.isdirectory(vim.v.argv[3]) == 1
if IS_OPENED_TO_DIR then
  vim.api.nvim_set_current_dir(vim.v.argv[3])
end
-- Watch directory for changes if opened to a directory
if IS_OPENED_TO_DIR then
  require('custom.directory-watcher').setup {
    path = vim.fn.getcwd(),
    debounce = 100,
  }
end

require 'config.keymap'
require 'config.options'
require 'config.autocommand'
require 'custom.hotreload'
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'tailwind-tools.nvim' and kind == 'update' then
      if not ev.data.active then
        vim.cmd.packadd('tailwind-tools.nvim')
      end
      vim.cmd('UpdateRemotePlugins')
    end
  end,
})
require 'custom.ai-prompt-completion-blink.prompt-file'
require 'config.spelling'

-- Defer blink-dependent setup until after plugin/ files load
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    require('custom.ai-prompt-completion-blink').setup()
  end,
})
