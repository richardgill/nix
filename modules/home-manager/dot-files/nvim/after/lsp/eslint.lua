---@type vim.lsp.Config
return {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
    'vue',
    'svelte',
    'astro',
  },
  root_dir = function(bufnr, on_dir)
    local root_markers = {
      '.eslintrc',
      '.eslintrc.js',
      '.eslintrc.cjs',
      '.eslintrc.yaml',
      '.eslintrc.yml',
      '.eslintrc.json',
      'eslint.config.js',
      'eslint.config.mjs',
      'eslint.config.cjs',
      'eslint.config.ts',
      'eslint.config.mts',
      'eslint.config.cts',
    }
    local project_root = vim.fs.root(bufnr, root_markers)

    if not project_root then
      return
    end
    -- this loads the lsp
    on_dir(project_root)
  end,
}
