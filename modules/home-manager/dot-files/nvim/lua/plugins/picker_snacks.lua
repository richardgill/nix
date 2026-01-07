return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      ui_select = true,
      layouts = {
        custom_vertical = {
          reverse = true,
          layout = {
            backdrop = false,
            width = 0.95,
            min_width = 80,
            height = 0.95,
            min_height = 30,
            box = 'vertical',
            border = 'rounded',
            title = '{title} {live} {flags}',
            title_pos = 'center',
            { win = 'preview', title = '{preview}', height = 0.5, border = 'bottom' },
            { win = 'list', border = 'none' },
            { win = 'input', height = 1, border = 'top' },
          },
        },
      },
      layout = 'custom_vertical',
      formatters = {
        file = {
          truncate = 120,
        },
      },
      win = {
        input = {
          keys = {
            ['<C-Down>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
            ['<C-Up>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
          },
        },
      },
      sources = {
        files = {
          cmd = 'rg',
          hidden = true,
          follow = true,
        },
        grep = {
          cmd = 'rg',
        },
      },
    },
  },
  config = function(_, opts)
    local snacks = require 'snacks'
    snacks.setup(opts)

    local picker = snacks.picker

    vim.keymap.set('n', '<leader>fh', function()
      picker.help()
    end, { desc = '[F]ind [H]elp' })

    vim.keymap.set('n', '<leader>ff', function()
      picker.files()
    end, { desc = '[F]ind [F]iles' })

    vim.keymap.set('n', '<leader>fs', function()
      picker.grep {
        regex = false,
      }
    end, { desc = '[F]ind by [S]earch Livegrep' })

    vim.keymap.set('n', '<leader>fd', function()
      picker.diagnostics()
    end, { desc = '[F]ind [D]iagnostics' })

    vim.keymap.set('n', '<leader>fr', function()
      picker.resume()
    end, { desc = '[F]ind [R]esume' })

    local recentFiles = function()
      picker.recent {
        filter = { cwd = true },
      }
    end

    vim.keymap.set('n', '<leader>f.', recentFiles, { desc = '[F]ind Recent Files ("." for repeat)' })

    vim.keymap.set('n', '<leader>fb', function()
      picker.buffers {
        sort = { 'mru' },
        current = false,
      }
    end, { desc = '[F]ind [B]uffers' })

    vim.keymap.set('n', '<leader>/', function()
      picker.lines {
        preview = false,
      }
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>f/', function()
      picker.grep_buffers()
    end, { desc = '[F]ind [/] in Open Files' })

    local notes_path = vim.fn.expand '~/code/notes'

    vim.keymap.set('n', '<leader>fnf', function()
      picker.files { cwd = notes_path }
    end, { desc = '[F]ind [N]otes [F]iles' })

    vim.keymap.set('n', '<leader>fns', function()
      picker.grep { cwd = notes_path }
    end, { desc = '[F]ind [N]otes [S]earch' })

    vim.keymap.set('n', '<leader>fm', function()
      picker.files {
        cmd = 'fd',
        args = { '-t', 'f', '--exec-batch', 'ls', '-t' },
      }
    end, { desc = '[F]ind [M]odified files (recent)' })
  end,
}
