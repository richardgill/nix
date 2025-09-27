-- shows pending keybinds
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  config = function()
    require('which-key').setup()

    -- Document existing key chains
    require('which-key').add {
      { '<leader>c', group = '[C]ode' },
      { '<leader>d', group = '[D]ocument' },
      { '<leader>f', group = '[F]ind' },
      { '<leader>h', group = 'Git [H]unk' },
      { '<leader>r', group = '[R]eplace' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>w', group = '[W]indows' },
      {
        -- visual mode
        mode = { 'v' },
        { '<leader>h', desc = 'Git [H]unk' },
        { '<leader>r', group = '[R]eplace' },
      },
    }
  end,
}
