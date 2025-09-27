-- This requires that vtsls is installed globally on your system. You can install it with npm.
return {
  'yioneko/nvim-vtsls',
  dependencies = { 'neovim/nvim-lspconfig' },
  opts = {},
  ft = { 'js', 'ts', 'jsx', 'tsx', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
  config = function()
    require('lspconfig.configs').vtsls = require('vtsls').lspconfig -- set default server config, optional but recommended
    require('lspconfig').vtsls.setup { --[[ your custom server config here ]]
    }

    require('vtsls').config {
      -- customize handlers for commands
      -- handlers = {
      --   source_definition = function(err, locations) end,
      --   file_references = function(err, locations) end,
      --   code_action = function(err, actions) end,
      -- },
      -- automatically trigger renaming of extracted symbol

      refactor_auto_rename = true,
      refactor_move_to_file = {
        -- If dressing.nvim is installed, telescope will be used for selection prompt. Use this to customize
        -- the opts for telescope picker.
        telescope_opts = function(items, default) end,
      },
    }
  end,
}
