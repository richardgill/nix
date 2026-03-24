vim.schedule(function()
  vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/mikavilpas/yazi.nvim',
  })

  ---@type YaziConfig
  require('yazi').setup {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    floating_window_scaling_factor = 1,
    keymaps = {
      show_help = '<f1>',
      open_file_in_vertical_split = '<c-v>',
      open_file_in_horizontal_split = '<c-h>',
      grep_in_directory = '<c-s>',
      replace_in_directory = '<c-g>',
      cycle_open_buffers = '<tab>',
      copy_relative_path_to_selected_files = '<c-y>',
      send_to_quickfix_list = '<c-q>',
    },
  }

  vim.keymap.set('n', '\\', '<cmd>Yazi<cr>', { desc = 'Open yazi at the current file' })
end)
