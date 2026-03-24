vim.pack.add({
  { src = 'https://github.com/luckasRanarison/tailwind-tools.nvim', version = 'abe7368392345c53174979c2cf033e832de80ef8' },
})

require('tailwind-tools').setup {
  smart_increment = {
    -- increment tailwindcss units using <C-a> and <C-x>
    -- Disabled because it clashes
    enabled = false,
  },
}
