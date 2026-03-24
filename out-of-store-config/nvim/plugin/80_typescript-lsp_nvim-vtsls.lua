vim.pack.add({ 'https://github.com/yioneko/nvim-vtsls' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  once = true,
  callback = function()
    require('vtsls').config {
      refactor_auto_rename = true,
      refactor_move_to_file = {
        -- If dressing.nvim is installed, telescope will be used for selection prompt. Use this to customize
        -- the opts for telescope picker.
        telescope_opts = function(items, default) end,
      },
    }
  end,
})
