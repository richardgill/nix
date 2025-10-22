-- This requires that vtsls is installed globally on your system. You can install it with npm.
return {
  'yioneko/nvim-vtsls',
  opts = {},
  ft = { 'js', 'ts', 'jsx', 'tsx', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
  config = function()
    vim.lsp.config('vtsls', {
      cmd = { 'bunx', '@vtsls/language-server@0.2.9', '--stdio' },
    })

    vim.lsp.enable('vtsls')

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
