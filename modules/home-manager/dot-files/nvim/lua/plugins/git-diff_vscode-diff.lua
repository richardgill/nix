return {
  'esmuellert/vscode-diff.nvim',
  branch = 'next',
  dependencies = { 'MunifTanjim/nui.nvim' },
  config = function()
    require('vscode-diff').setup {
      diff = {
        disable_inlay_hints = true,
      },
      explorer = {
        view_mode = 'tree',
      },
      keymaps = {
        view = {
          quit = 'q',
          toggle_explorer = '<leader>b',
          next_hunk = ']c',
          prev_hunk = '[c',
          next_file = '<Tab>',
          prev_file = '<S-Tab>',
        },
        explorer = {
          select = '<CR>',
          refresh = 'R',
        },
      },
    }
  end,
}
