-- "gc" to comment visual regions/lines (neovim 0.10+ built-in)
-- ts_context_commentstring: picks the right comment style in mixed-language
-- files (e.g. {/* */} in JSX vs // in TS). Remove if you don't use TSX/Vue/Svelte.
vim.pack.add({
  'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
})

require('ts_context_commentstring').setup {
  enable_autocmd = false,
}

local get_option = vim.filetype.get_option
vim.filetype.get_option = function(filetype, option)
  return option == 'commentstring'
      and require('ts_context_commentstring.internal').calculate_commentstring()
    or get_option(filetype, option)
end
