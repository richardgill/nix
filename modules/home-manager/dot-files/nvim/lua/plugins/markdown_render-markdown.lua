return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  config = function()
    require('render-markdown').setup {
      enabled = true,
      file_types = { 'markdown', 'codecompanion' },
      render_modes = {}, -- Empty list to disable automatic rendering in all modes
      code = {
        inline = false, -- Disable inline code rendering to remove background styling
      },
    }
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function()
        require('render-markdown').disable()
        vim.schedule(function()
          vim.keymap.set('n', '<leader>pm', function()
            require('render-markdown').toggle()
          end, { desc = '[P]review [M]arkdown', buffer = true })
        end)
      end,
    })
  end,
  ft = { 'markdown', 'codecompanion' },
}
