local use_official = vim.env.CODEDIFF_OFFICIAL == '1'
local line_matcher_strategy = vim.env.CODEDIFF_LINE_MATCHER or 'similarity'

if use_official then
  vim.pack.add { 'https://github.com/esmuellert/codediff.nvim' }
else
  local codediff_path = vim.env.CODEDIFF_PATH or vim.fn.expand '~/code/codediff/runtime'
  -- local codediff_path = vim.env.CODEDIFF_PATH or vim.fn.expand '~/code/codediff/pi-code-annotations'

  vim.opt.runtimepath:prepend(codediff_path)
  vim.cmd.runtime 'plugin/codediff.lua'
  vim.cmd.runtime 'plugin/vscode-diff.lua'
end

local review = use_official and {} or require 'custom.codediff-review'

local official_config = {
  highlights = {
    line_insert = 'DiffAdd',
    line_delete = 'LeftPaneAdd',
    char_insert = 'DiffText',
    char_delete = 'LeftPaneText',
    char_brightness = 1.5,
  },
  diff = {
    disable_inlay_hints = true,
    cycle_hunks_across_files = true,
  },
  explorer = {
    view_mode = 'tree',
  },
  keymaps = {
    view = {
      quit = 'q',
      toggle_explorer = '<leader>b',
      next_hunk = 'h',
      prev_hunk = 'H',
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

local fork_config = {
  highlights = {
    line_insert = 'DiffAdd',
    line_delete = 'LeftPaneAdd',
    char_insert = 'DiffText',
    char_delete = 'LeftPaneText',
    char_brightness = 1.5,
  },
  diff = {
    disable_inlay_hints = true,
    cycle_hunks_across_files = true,
    highlight_added_deleted_files = true,
    filler_text = ' ',
    wrap = true,
    line_matcher = {
      strategy = line_matcher_strategy,
    },
    gutter_signs = {
      insert_text = ' ',
      delete_text = ' ',
      changed_priority = 100,
      unchanged_priority = 99,
    },
  },
  explorer = {
    view_mode = 'tree',
    line_stats = {
      enabled = true,
    },
    formatters = {
      file = review.file,
      group = review.group,
    },
  },
  keymaps = {
    view = {
      quit = 'q',
      toggle_explorer = '<leader>b',
      next_hunk = 'h',
      prev_hunk = 'H',
      next_file = '<Tab>',
      prev_file = '<S-Tab>',
      close_on_open_in_prev_tab = true,
      toggle_stage = 's',
    },
    explorer = {
      select = '<CR>',
      refresh = 'R',
      custom = {
        {
          key = 'm',
          desc = 'Toggle marked',
          callback = review.toggle_marked,
        },
      },
    },
  },
}

require('codediff').setup(use_official and official_config or fork_config)
