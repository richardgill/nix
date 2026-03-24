local picker = require('snacks').picker

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
