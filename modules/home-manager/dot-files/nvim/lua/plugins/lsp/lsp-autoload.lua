local lsp_path = vim.fn.stdpath 'config' .. '/after/lsp'

-- LSP and Formatters installed in lsp-formatters.nix
-- Installing a new lsp:
--   Grab a default config https://github.com/neovim/nvim-lspconfig/tree/master/lsp
--   Copy it into after/lsp/<new-lsp>.lua

-- Finds all lsps in after/lsp/*.lua and enables each lsp.
for name, type in vim.fs.dir(lsp_path) do
  if type == 'file' and name:match '%.lua$' then
    local server = name:match '(.+)%.lua$'
    vim.lsp.enable(server)
  end
end

-- Debugging:
--   Health check with:  :checkhealth vim.lsp
--   LSP logs for current buffer:  :lua vim.cmd.edit(vim.lsp.log.get_filename())

-- keep Lazy happy
return {}
