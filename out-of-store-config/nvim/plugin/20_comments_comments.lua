-- "gc" to comment visual regions/lines
vim.pack.add({
  'https://github.com/numToStr/Comment.nvim',
  'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
})

require('ts_context_commentstring').setup {
  enable_autocmd = false,
}
require('Comment').setup {
  pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
}
