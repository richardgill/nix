local M = {}

local opts = { noremap = true, silent = true }

local half_screen_distance = function()
  return math.floor(vim.api.nvim_win_get_height(0) / 2)
end

local move_line = function(distance)
  if distance == 0 then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(0)
  local current_line = vim.fn.line('.')
  local target_line = math.max(1, math.min(line_count, current_line + distance))
  if target_line == current_line then
    return
  end

  local move_address = target_line > current_line and target_line or target_line - 1
  vim.cmd('move ' .. move_address)
end

local move_block = function(distance)
  if distance == 0 then
    return
  end

  local visual_start = vim.fn.line('v')
  local visual_end = vim.fn.line('.')
  local start_line = math.min(visual_start, visual_end)
  local end_line = math.max(visual_start, visual_end)
  local line_count = vim.api.nvim_buf_line_count(0)
  local offset = distance > 0 and math.min(distance, line_count - end_line) or -math.min(math.abs(distance), start_line - 1)
  if offset == 0 then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local insert_at = start_line - 1 + offset
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, {})
  vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, lines)

  local new_start = insert_at + 1
  local new_end = insert_at + #lines
  vim.fn.setpos("'<", { 0, new_start, 1, 0 })
  vim.fn.setpos("'>", { 0, new_end, 1, 0 })
  vim.cmd('normal! gv')
end

M.setup = function()
  vim.keymap.set('n', '<A-j>', function()
    move_line(1)
  end, opts)
  vim.keymap.set('n', '<A-Down>', function()
    move_line(1)
  end, opts)
  vim.keymap.set('n', '<A-k>', function()
    move_line(-1)
  end, opts)
  vim.keymap.set('n', '<A-Up>', function()
    move_line(-1)
  end, opts)

  vim.keymap.set('v', '<A-j>', function()
    move_block(1)
  end, opts)
  vim.keymap.set('v', '<A-Down>', function()
    move_block(1)
  end, opts)
  vim.keymap.set('v', '<A-k>', function()
    move_block(-1)
  end, opts)
  vim.keymap.set('v', '<A-Up>', function()
    move_block(-1)
  end, opts)

  vim.keymap.set('n', '<C-A-d>', function()
    move_line(half_screen_distance())
  end, opts)
  vim.keymap.set('n', '<C-A-Down>', function()
    move_line(half_screen_distance())
  end, opts)
  vim.keymap.set('n', '<C-A-u>', function()
    move_line(-half_screen_distance())
  end, opts)
  vim.keymap.set('n', '<C-A-Up>', function()
    move_line(-half_screen_distance())
  end, opts)

  vim.keymap.set('v', '<C-A-d>', function()
    move_block(half_screen_distance())
  end, opts)
  vim.keymap.set('v', '<C-A-Down>', function()
    move_block(half_screen_distance())
  end, opts)
  vim.keymap.set('v', '<C-A-u>', function()
    move_block(-half_screen_distance())
  end, opts)
  vim.keymap.set('v', '<C-A-Up>', function()
    move_block(-half_screen_distance())
  end, opts)
end

return M
