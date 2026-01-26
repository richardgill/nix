return {
  'fedepujol/move.nvim',
  version = '*',
  config = function()
    require('move').setup {
      line = {
        enable = true, -- Enables line movement
        indent = true, -- Toggles indentation
      },
      block = {
        enable = true, -- Enables block movement
        indent = true, -- Toggles indentation
      },
    }
    local opts = { noremap = true, silent = true }
    -- Normal-mode commands
    vim.keymap.set('n', '<A-j>', ':MoveLine(1)<CR>', opts)
    vim.keymap.set('n', '<A-Down>', ':MoveLine(1)<CR>', opts)
    vim.keymap.set('n', '<A-k>', ':MoveLine(-1)<CR>', opts)
    vim.keymap.set('n', '<A-Up>', ':MoveLine(-1)<CR>', opts)

    -- Visual-mode commands
    vim.keymap.set('v', '<A-j>', ':MoveBlock(1)<CR>', opts)
    vim.keymap.set('v', '<A-Down>', ':MoveBlock(1)<CR>', opts)
    vim.keymap.set('v', '<A-k>', ':MoveBlock(-1)<CR>', opts)
    vim.keymap.set('v', '<A-Up>', ':MoveBlock(-1)<CR>', opts)

    local function half_screen_distance()
      return math.floor(vim.api.nvim_win_get_height(0) / 2)
    end

    -- Move line half-screen down/up
    vim.keymap.set('n', '<A-d>', function()
      vim.cmd('MoveLine(' .. half_screen_distance() .. ')')
    end, opts)
    vim.keymap.set('n', '<A-PageDown>', function()
      vim.cmd('MoveLine(' .. half_screen_distance() .. ')')
    end, opts)
    vim.keymap.set('n', '<A-u>', function()
      vim.cmd('MoveLine(-' .. half_screen_distance() .. ')')
    end, opts)
    vim.keymap.set('n', '<A-PageUp>', function()
      vim.cmd('MoveLine(-' .. half_screen_distance() .. ')')
    end, opts)

    -- Move block half-screen down/up
    vim.keymap.set('v', '<A-d>', function()
      vim.cmd('MoveBlock(' .. half_screen_distance() .. ')')
    end, opts)
    vim.keymap.set('v', '<A-PageDown>', function()
      vim.cmd('MoveBlock(' .. half_screen_distance() .. ')')
    end, opts)
    vim.keymap.set('v', '<A-u>', function()
      vim.cmd('MoveBlock(-' .. half_screen_distance() .. ')')
    end, opts)
    vim.keymap.set('v', '<A-PageUp>', function()
      vim.cmd('MoveBlock(-' .. half_screen_distance() .. ')')
    end, opts)
  end,
}
