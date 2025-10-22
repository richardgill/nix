local utils = require 'utils'

vim.api.nvim_create_autocmd('User', {
  pattern = 'DiffviewViewLeave',
  callback = function()
    vim.cmd ':DiffviewClose'
  end,
})

-- File watcher for auto-refresh
local watcher
local debounce_timer
local debounce_delay = 100 -- milliseconds

local function is_diffview_open()
  local ok, lib = pcall(require, 'diffview.lib')
  return ok and lib and lib.views and next(lib.views) ~= nil
end

local function get_diffview_buffers_to_reload()
  local focused_bufnr = vim.api.nvim_get_current_buf()
  local buffers_to_reload = {}

  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local buftype = vim.bo[bufnr].buftype
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    local is_real_file = buftype == '' and bufname ~= '' and not bufname:match '^diffview://'
    local is_focused = bufnr == focused_bufnr

    if is_real_file and not is_focused then
      buffers_to_reload[bufnr] = true
    end
  end

  return buffers_to_reload
end

local function refresh_diffview()
  if not is_diffview_open() then
    return
  end

  vim.schedule(function()
    pcall(function()
      local buffers = get_diffview_buffers_to_reload()

      for bufnr, _ in pairs(buffers) do
        vim.cmd('checktime ' .. bufnr)
      end

      vim.cmd 'DiffviewRefresh'
    end)
  end)
end

local function on_fs_event(err, filename, events)
  if err then
    return
  end

  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
  end

  debounce_timer = vim.loop.new_timer()
  debounce_timer:start(debounce_delay, 0, vim.schedule_wrap(refresh_diffview))
end

return {
  'sindrets/diffview.nvim',
  version = '*',
  config = function()
    require('diffview').setup {
      default_args = {
        DiffviewOpen = { '--imply-local' },
      },
    }

    -- Set up file watcher
    vim.schedule(function()
      local git_root = utils.get_git_root()
      if git_root then
        watcher = vim.loop.new_fs_event()
        watcher:start(git_root, { recursive = true }, on_fs_event)
      end
    end)
  end,
}
