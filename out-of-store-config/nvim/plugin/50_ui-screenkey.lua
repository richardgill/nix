if vim.env.NVIM_SCREENKEY ~= '1' then
  return
end

vim.pack.add { { src = 'https://github.com/NStefan002/screenkey.nvim', version = 'v2.4.2' } }

require('screenkey').setup {
  clear_after = 5,
  group_mappings = true,
}

vim.cmd 'Screenkey'
