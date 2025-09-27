return {
  'luckasRanarison/tailwind-tools.nvim',
  commit = '999d314444073095494f5a36b90fdba3c432a457',
  name = 'tailwind-tools',
  build = ':UpdateRemotePlugins',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-telescope/telescope.nvim',
    'neovim/nvim-lspconfig',
  },
  opts = {
    smart_increment = {
      -- increment tailwindcss units using <C-a> and <C-x>
      -- Disabled because it clashes
      enabled = false,
    },
  },
}
