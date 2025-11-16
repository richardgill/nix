vim.api.nvim_create_autocmd('User', {
  pattern = 'DiffviewViewLeave',
  callback = function()
    vim.cmd ':DiffviewClose'
  end,
})

-- Timer for auto-refresh
local refresh_timer

vim.api.nvim_create_autocmd('User', {
  pattern = 'DiffviewViewOpened',
  callback = function()
    -- Clean up existing timer if any
    if refresh_timer then
      refresh_timer:stop()
      refresh_timer:close()
      refresh_timer = nil
    end

    -- Start repeating timer for refresh (1000ms interval)
    refresh_timer = vim.loop.new_timer()
    refresh_timer:start(
      1000,
      1000,
      vim.schedule_wrap(function()
        pcall(function()
          local lib = require 'diffview.lib'
          local view = lib.get_current_view()
          if view then
            -- This updates the left panel with all the files, but doesn't update the buffers
            view:update_files()
          end
        end)
      end)
    )
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'DiffviewViewClosed',
  callback = function()
    -- Stop and clean up timer
    if refresh_timer then
      refresh_timer:stop()
      refresh_timer:close()
      refresh_timer = nil
    end
  end,
})

return {
  'sindrets/diffview.nvim',
  version = '*',
  config = function()
    require('diffview').setup {
      default_args = {
        DiffviewOpen = { '--imply-local' },
      },
      keymaps = {
        view = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
        file_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
      },
    }
  end,
}
