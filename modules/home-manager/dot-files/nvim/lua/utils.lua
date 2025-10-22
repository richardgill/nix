local M = {}

M.restart_lsp = function()
  vim.cmd 'LspRestart'
  if vim.fn.exists ':VtsExec' == 2 then
    vim.cmd 'VtsExec restart_tsserver'
  end
  vim.diagnostic.reset(nil, 0)
end

M.get_git_root = function()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if vim.v.shell_error == 0 and git_root and git_root ~= "" then
    return git_root
  end
  return vim.fn.getcwd()
end

M.get_buffer_absolute = function()
  return vim.fn.expand '%:p'
end

M.get_buffer_cwd_relative = function()
  return vim.fn.expand '%:.'
end

M.get_buffer_git_root_relative = function()
  local git_root = M.get_git_root()
  local abs_path = vim.fn.expand '%:p'
  return abs_path:sub(#git_root + 2)
end

M.get_visual_bounds = function()
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' then
    error('get_visual_bounds must be called in visual or visual-line mode (current mode: ' .. vim.inspect(mode) .. ')')
  end
  local is_visual_line_mode = mode == 'V'
  local start_pos = vim.fn.getpos 'v'
  local end_pos = vim.fn.getpos '.'

  return {
    start_line = math.min(start_pos[2], end_pos[2]),
    end_line = math.max(start_pos[2], end_pos[2]),
    start_col = is_visual_line_mode and 0 or math.min(start_pos[3], end_pos[3]) - 1,
    end_col = is_visual_line_mode and -1 or math.max(start_pos[3], end_pos[3]),
    mode = mode,
    start_pos = start_pos,
    end_pos = end_pos,
  }
end

-- Format line numbers for display (e.g., 42 -> "42", 10 to 15 -> "10-15")
M.format_line_range = function(start_line, end_line)
  return start_line == end_line and tostring(start_line) or start_line .. '-' .. end_line
end

M.simulate_yank_highlight = function()
  local bounds = M.get_visual_bounds()

  local ns = vim.api.nvim_create_namespace 'simulate_yank_highlight'
  vim.highlight.range(0, ns, 'IncSearch', { bounds.start_line - 1, bounds.start_col }, { bounds.end_line - 1, bounds.end_col }, { priority = 200 })
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end, 150)
end

M.exit_visual_mode = function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
end

return M
