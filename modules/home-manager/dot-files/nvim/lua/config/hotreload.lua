-- Auto-reload visible buffers when files change on disk
-- This is very helpful when using agentic coding
-- Timer-based (500ms) + event-based checking

local function should_check()
  local mode = vim.api.nvim_get_mode().mode
  return not (
    mode:match '[cR!s]' -- Skip: command-line, replace, ex, select modes
    or vim.fn.getcmdwintype() ~= '' -- Skip: command-line window is open
  )
end

local function should_reload_buffer(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf })
  local modified = vim.api.nvim_get_option_value('modified', { buf = buf })
  local is_real_file = name ~= '' and not name:match '^%w+://' -- Skip URIs like diffview://, fugitive://, etc

  return is_real_file and buftype == '' and not modified
end

local function get_visible_buffers()
  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  return visible
end

local function reload_visible_buffers()
  if not should_check() then
    return
  end

  for buf, _ in pairs(get_visible_buffers()) do
    if should_reload_buffer(buf) then
      vim.cmd('checktime ' .. buf)
    end
  end
end

-- Timer: check visible buffers every 500ms
local timer = vim.uv.new_timer()
vim.uv.timer_start(timer, 500, 500, vim.schedule_wrap(reload_visible_buffers))

-- Events: immediate reload on focus/buffer switch
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermLeave', 'BufEnter', 'WinEnter', 'CursorHold', 'CursorHoldI' }, {
  group = vim.api.nvim_create_augroup('hotreload', { clear = true }),
  callback = function()
    if should_check() then
      vim.cmd 'checktime'
    end
  end,
})
