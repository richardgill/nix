return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- Makes telescope search faster
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    -- Sets core nvim picker to be telescope
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    {
      'mollerhoj/telescope-recent-files.nvim',
    },
  },
  config = function()
    local actions = require 'telescope.actions'
    require('telescope').setup {
      defaults = {
        path_display = { 'truncate' },
        layout_strategy = 'vertical',
        mappings = {
          i = { ['<C-Down>'] = actions.results_scrolling_down, ['<C-Up>'] = actions.results_scrolling_up },
          n = { ['<C-Down>'] = actions.results_scrolling_down, ['<C-Up>'] = actions.results_scrolling_up },
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
    pcall(require('telescope').load_extension, 'recent-files')

    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
    vim.keymap.set('n', '<leader>ft', builtin.builtin, { desc = '[F]ind [S]elect Telescope' })
    vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
    vim.keymap.set('n', '<leader>fr', builtin.live_grep, { desc = '[F]ind by grep [R]egex' })
    vim.keymap.set('n', '<leader>fs', function()
      builtin.live_grep {
        additional_args = {
          '--fixed-strings', -- stops ripgrep from using regexes
        },
      }
    end, { desc = '[F]ind by [S]earch Livegrep' })
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
    vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
    local recentFiles = function()
      require('telescope').extensions['recent-files'].recent_files {}
    end
    vim.keymap.set('n', '<leader>f.', recentFiles, { desc = '[F]ind Recent Files ("." for repeat)' })

    local bufferFunc = function()
      builtin.buffers {
        sort_mru = true,
        ignore_current_buffer = true,
      }
    end
    vim.keymap.set('n', '<leader>fb', bufferFunc, { desc = '[F]ind [B]uffers' })

    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>f/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[F]ind [/] in Open Files' })

    local notes_path = vim.fn.expand '~/code/notes'

    vim.keymap.set('n', '<leader>fnf', function()
      require('telescope.builtin').find_files { cwd = notes_path }
    end, { desc = '[F]ind [N]otes [F]iles' })

    vim.keymap.set('n', '<leader>fns', function()
      require('telescope.builtin').live_grep { cwd = notes_path }
    end, { desc = '[F]ind [N]otes [S]earch' })

    -- Open telescope when entering nvim
    local ts_group = vim.api.nvim_create_augroup('TelescopeOnEnter', { clear = true })
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        if IS_OPENED_TO_DIR then
          -- close the open buffer
          vim.cmd ':bd 1'
          recentFiles()
        end
      end,
      group = ts_group,
    })
  end,
}
