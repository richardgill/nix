return {
  'esmuellert/codediff.nvim',
  dependencies = { 'MunifTanjim/nui.nvim' },
  cmd = 'CodeDiff',
  config = function()
    require('codediff').setup {
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
          toggle_stage = 's',
        },
      },
    }
  end,
}
