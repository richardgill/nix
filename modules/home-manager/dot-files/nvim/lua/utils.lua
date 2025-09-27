local M = {}

M.restart_lsp = function()
  vim.cmd 'LspRestart'
  if vim.fn.exists ':VtsExec' == 2 then
    vim.cmd 'VtsExec restart_tsserver'
  end
  vim.diagnostic.reset(nil, 0)
end

return M
