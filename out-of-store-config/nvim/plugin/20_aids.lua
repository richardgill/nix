vim.pack.add {
  'https://github.com/m4xshen/hardtime.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/tris203/precognition.nvim',
}

require('hardtime').setup {
  disabled_keys = {
    ['<Up>'] = false,
    ['<Down>'] = false,
    ['<Left>'] = false,
    ['<Right>'] = false,
  },
}
require('precognition').setup()
