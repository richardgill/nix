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

local function get_git_root()
  local handle = io.popen 'git rev-parse --show-toplevel 2>/dev/null'
  if handle then
    local result = handle:read '*l'
    handle:close()
    return result
  end
  return vim.fn.getcwd()
end

local function is_diffview_open()
  local ok, lib = pcall(require, 'diffview.lib')
  if ok and lib and lib.views then
    return next(lib.views) ~= nil
  end
  return false
end

local function refresh_diffview()
  if is_diffview_open() then
    vim.schedule(function()
      vim.cmd 'DiffviewRefresh'
    end)
  end
end

local function on_fs_event()
  -- Cancel existing timer if any
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
  end

  -- Create new timer for debouncing
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
      local git_root = get_git_root()
      if git_root then
        watcher = vim.loop.new_fs_event()
        watcher:start(git_root, { recursive = true }, on_fs_event)
      end
    end)
  end,
}
