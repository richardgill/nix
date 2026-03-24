vim.pack.add({ 'https://github.com/ray-x/lsp_signature.nvim' })

vim.api.nvim_create_autocmd('InsertEnter', {
  once = true,
  callback = function()
    require('lsp_signature').setup {}
  end,
})
