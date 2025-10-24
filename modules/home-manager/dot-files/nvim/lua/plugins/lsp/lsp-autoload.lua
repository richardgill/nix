local lsp_path = vim.fn.stdpath 'config' .. '/after/lsp'

-- Finds all lsps in after/lsp/*.lua and enables the lsp.
-- Grab default configs: https://github.com/neovim/nvim-lspconfig/tree/master/lsp and copy them into nvim/lsp/
-- LSP and Formatters installed in lsp-formatters.nix
-- Health check with:  :checkhealth vim.lsp
-- LSP logs for current buffer:  :lua vim.cmd.edit(vim.lsp.log.get_filename())
for name, type in vim.fs.dir(lsp_path) do
  if type == 'file' and name:match '%.lua$' then
    local server = name:match '(.+)%.lua$'
    vim.lsp.enable(server)
  end
end

-- keep Lazy happy
return {}
