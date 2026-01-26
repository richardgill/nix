---@type vim.lsp.Config
return {
  cmd = { 'vtsls', '--stdio' },
  init_options = {
    hostInfo = 'neovim',
  },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_dir = function(bufnr, on_dir)
    local root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' }
    -- Give the root markers equal priority by wrapping them in a table
    root_markers = { root_markers, { '.git' } }
    -- We fallback to the current working directory if no project root is found
    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

    on_dir(project_root)
  end,
  on_attach = function(client, bufnr)
    vim.keymap.set('n', '<leader>oi', function()
      vim.cmd 'VtsExec remove_unused_imports'
      vim.defer_fn(function()
        require('conform').format { async = true }
      end, 100)
    end, { buffer = bufnr, desc = '[O]rganize [I]mports' })

    vim.keymap.set('n', '<leader>crf', '<cmd>:VtsExec rename_file<cr>', {
      buffer = bufnr,
      desc = '[C]ode [R]ename [F]ile',
    })
  end,
}
