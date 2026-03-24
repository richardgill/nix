vim.pack.add({ 'https://github.com/esmuellert/codediff.nvim' })

require('codediff').setup {
  highlights = {
    line_insert = 'DiffAdd',
    line_delete = 'LeftPaneAdd',
    char_insert = 'DiffText',
    char_delete = 'LeftPaneText',
  },
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
      close_on_open_in_prev_tab = true,
      toggle_stage = 's',
    },
    explorer = {
      select = '<CR>',
      refresh = 'R',
    },
  },
}
