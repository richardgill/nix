return {
  'alexghergh/nvim-tmux-navigation',
  config = function()
    local nvim_tmux_nav = require 'nvim-tmux-navigation'

    --  Navigate splits using CTRL+<hjkl> to switch between windows
    vim.keymap.set('n', '<C-h>', nvim_tmux_nav.NvimTmuxNavigateLeft, { desc = 'Move focus to the left window' })
    vim.keymap.set('n', '<C-j>', nvim_tmux_nav.NvimTmuxNavigateDown, { desc = 'Move focus to the lower window' })
    vim.keymap.set('n', '<C-k>', nvim_tmux_nav.NvimTmuxNavigateUp, { desc = 'Move focus to the upper window' })
    vim.keymap.set('n', '<C-l>', nvim_tmux_nav.NvimTmuxNavigateRight, { desc = 'Move focus to the right window' })

    vim.keymap.set('n', '<C-S-Left>', nvim_tmux_nav.NvimTmuxNavigateLeft, { desc = 'Move focus to the left window' })
    vim.keymap.set('n', '<C-S-Down>', nvim_tmux_nav.NvimTmuxNavigateDown, { desc = 'Move focus to the lower window' })
    vim.keymap.set('n', '<C-S-Up>', nvim_tmux_nav.NvimTmuxNavigateUp, { desc = 'Move focus to the upper window' })
    vim.keymap.set('n', '<C-S-Right>', nvim_tmux_nav.NvimTmuxNavigateRight, { desc = 'Move focus to the right window' })
  end,
}
