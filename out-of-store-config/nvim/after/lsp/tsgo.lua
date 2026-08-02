local get_typescript_major_version = function(command)
  local result = vim.system({ command, '--version' }, { text = true }):wait(2000)
  if result.code ~= 0 then
    return
  end

  return tonumber(result.stdout:match 'Version (%d+)')
end

local resolve_command = function(root_dir)
  if not root_dir then
    return 'tsgo'
  end

  local local_tsc = vim.fs.joinpath(root_dir, 'node_modules', '.bin', 'tsc')
  local major_version = vim.fn.executable(local_tsc) == 1 and get_typescript_major_version(local_tsc) or nil
  return major_version and major_version >= 7 and local_tsc or 'tsgo'
end

---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start({ resolve_command(config.root_dir), '--lsp', '--stdio' }, dispatchers)
  end,
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
  settings = {
    typescript = {
      inlayHints = {
        parameterNames = {
          enabled = 'literals',
          suppressWhenArgumentMatchesName = true,
        },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
  on_attach = function(_, bufnr)
    vim.keymap.set('n', '<leader>oi', function()
      vim.lsp.buf.code_action {
        apply = true,
        context = { only = { 'source.removeUnusedImports' } },
      }
      vim.defer_fn(function()
        require('conform').format { async = true }
      end, 100)
    end, { buffer = bufnr, desc = '[O]rganize [I]mports' })

    vim.keymap.set('n', '<leader>crf', function()
      require('snacks').rename.rename_file()
    end, { buffer = bufnr, desc = '[C]ode [R]ename [F]ile' })
  end,
}
