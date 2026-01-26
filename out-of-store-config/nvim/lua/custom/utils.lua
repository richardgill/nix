local M = {}

M.restart_lsp = function()
  local client_names = vim.tbl_map(function(client)
    return client.name
  end, vim.lsp.get_clients())

  vim.lsp.enable(client_names, false)
  vim.lsp.enable(client_names, true)

  if vim.fn.exists ':VtsExec' == 2 then
    vim.cmd 'VtsExec restart_tsserver'
  end
  vim.diagnostic.reset(nil, 0)
  vim.notify('LSP servers restarted', vim.log.levels.INFO)
end

return M
