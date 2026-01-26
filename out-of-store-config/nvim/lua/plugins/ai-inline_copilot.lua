return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {

      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = '[[',
          jump_next = ']]',
          accept = '<CR>',
          refresh = 'gr',
          open = '<M-CR>',
        },
        layout = {
          position = 'bottom', -- | top | left | right
          ratio = 0.4,
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = false,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = '<M-l>',
          accept_word = false,
          accept_line = false,
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
      },
      filetypes = {
        yaml = false,
        markdown = true,
        help = false,
        gitcommit = true,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
      },
      copilot_node_command = 'node', -- Node.js version must be > 18.x
      server_opts_overrides = {},
    }
    local timer
    -- Turn on copilot auto suggest for 30 seconds
    vim.keymap.set('i', '<M-s>', function()
      vim.b.copilot_suggestion_auto_trigger = true
      -- make a suggestion immediately
      require('copilot.suggestion').next()
      if timer then
        timer:stop()
        timer:close()
      end
      timer = vim.loop.new_timer()
      timer:start(30000, 0, function()
        vim.schedule(function()
          vim.b.copilot_suggestion_auto_trigger = false
          require('copilot.suggestion').dismiss()
        end)
      end)
    end, { noremap = true, silent = true })
  end,
}
