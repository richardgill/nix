return {
  'luckasRanarison/tailwind-tools.nvim',
  commit = 'abe7368392345c53174979c2cf033e832de80ef8',
  name = 'tailwind-tools',
  build = ':UpdateRemotePlugins',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    smart_increment = {
      -- increment tailwindcss units using <C-a> and <C-x>
      -- Disabled because it clashes
      enabled = false,
    },
  },
}
