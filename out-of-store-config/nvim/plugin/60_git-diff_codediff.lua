vim.pack.add { 'https://github.com/esmuellert/codediff.nvim' }

-- START HACK Remove when https://github.com/esmuellert/codediff.nvim/issues/322 is fixed upstream.
local get_explorer_target_file = function(explorer)
  local node = explorer.tree and explorer.tree:get_node()
  local rel_path = node and node.data and node.data.path or explorer.current_file_path
  local git_root = explorer.git_root

  if not rel_path or not git_root then
    return nil
  end

  if rel_path:sub(1, 1) == '/' then
    return rel_path
  end

  return git_root .. '/' .. rel_path
end

local open_explorer_file_in_prev_tab = function(tabpage)
  local lifecycle = require 'codediff.ui.lifecycle'
  local config = require('codediff.config').options
  local explorer = lifecycle.get_explorer(tabpage)
  local target_file = explorer and get_explorer_target_file(explorer)

  if not target_file then
    return
  end

  local current_tab = vim.api.nvim_get_current_tabpage()
  local current_index = nil
  local tabs = vim.api.nvim_list_tabpages()

  for i, tab in ipairs(tabs) do
    if tab == current_tab then
      current_index = i
    end
  end

  if current_index and current_index > 1 then
    vim.api.nvim_set_current_tabpage(tabs[current_index - 1])
  else
    vim.cmd 'tabnew'
    vim.cmd 'tabmove 0'
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(target_file))

  if config.keymaps.view.close_on_open_in_prev_tab and vim.api.nvim_tabpage_is_valid(current_tab) then
    vim.api.nvim_set_current_tabpage(current_tab)
    vim.cmd 'tabclose'
  end
end

local apply_explorer_gf_workaround = function(tabpage)
  local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
  if not ok then
    return
  end

  local explorer = lifecycle.get_explorer(tabpage)
  if not explorer or not explorer.bufnr or not vim.api.nvim_buf_is_valid(explorer.bufnr) then
    return
  end

  local config = require('codediff.config').options
  local key = config.keymaps.view.open_in_prev_tab or 'gf'

  vim.keymap.set('n', key, function()
    open_explorer_file_in_prev_tab(tabpage)
  end, { buffer = explorer.bufnr, desc = 'Open explorer file in previous tab', noremap = true, silent = true, nowait = true })
end

local schedule_explorer_gf_workaround = function(tabpage)
  vim.schedule(function()
    apply_explorer_gf_workaround(tabpage)
  end)
  vim.defer_fn(function()
    apply_explorer_gf_workaround(tabpage)
  end, 100)
end
-- END HACK

-- START HACK Remove when CodeDiff treats added/untracked files as hunk-navigation targets.
local next_hunk_or_file = function()
  local codediff = require 'codediff'

  if not codediff.next_hunk() then
    codediff.next_file()
  end
end

local prev_hunk_or_file = function()
  local codediff = require 'codediff'

  if not codediff.prev_hunk() then
    codediff.prev_file()
  end
end

local apply_hunk_file_fallback_workaround = function(tabpage)
  local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
  if not ok or not lifecycle.get_session(tabpage) then
    return
  end

  local keymaps = require('codediff.config').options.keymaps.view

  lifecycle.set_tab_keymap(tabpage, 'n', keymaps.next_hunk, next_hunk_or_file, { desc = 'Next hunk or file' })
  lifecycle.set_tab_keymap(tabpage, 'n', keymaps.prev_hunk, prev_hunk_or_file, { desc = 'Previous hunk or file' })
  lifecycle.set_tab_keymap(tabpage, 'n', ']h', next_hunk_or_file, { desc = 'Next hunk or file' })
  lifecycle.set_tab_keymap(tabpage, 'n', '[h', prev_hunk_or_file, { desc = 'Previous hunk or file' })
  lifecycle.set_tab_keymap(tabpage, 'n', 'h', next_hunk_or_file, { desc = 'Next hunk or file' })
  lifecycle.set_tab_keymap(tabpage, 'n', 'H', prev_hunk_or_file, { desc = 'Previous hunk or file' })
end

local schedule_hunk_file_fallback_workaround = function(tabpage)
  vim.schedule(function()
    apply_hunk_file_fallback_workaround(tabpage)
  end)
  vim.defer_fn(function()
    apply_hunk_file_fallback_workaround(tabpage)
  end, 100)
end
-- END HACK

-- START HACK Remove when https://github.com/esmuellert/codediff.nvim/issues/50 is fixed upstream.
-- Wrapping can desynchronize side-by-side filler lines and scrollbind; inline diffs are less affected.
local apply_diff_pane_wrap_workaround = function(tabpage)
  local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
  local session = ok and lifecycle.get_session(tabpage)
  if not session then
    return
  end

  for _, field in ipairs { 'original_win', 'modified_win', 'result_win' } do
    local win = session[field]
    if win and vim.api.nvim_win_is_valid(win) then
      vim.wo[win].wrap = true
    end
  end
end

local schedule_diff_pane_wrap_workaround = function(tabpage)
  vim.schedule(function()
    apply_diff_pane_wrap_workaround(tabpage)
  end)
  vim.defer_fn(function()
    apply_diff_pane_wrap_workaround(tabpage)
  end, 100)
end
-- END HACK

-- START HACK Remove when https://github.com/esmuellert/codediff.nvim/issues/428 is fixed upstream.
local close_codediff_without_qall = function(tabpage)
  local lifecycle = require 'codediff.ui.lifecycle'

  if not lifecycle.confirm_close_with_unsaved(tabpage) then
    return
  end

  if #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd 'tabclose'
    return
  end

  vim.cmd 'tabnew'
  vim.api.nvim_set_current_tabpage(tabpage)
  vim.cmd 'tabclose'
end

local apply_no_qall_quit_workaround = function(tabpage)
  local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
  if not ok or not lifecycle.get_session(tabpage) then
    return
  end

  local keymaps = require('codediff.config').options.keymaps.view

  lifecycle.set_tab_keymap(tabpage, 'n', keymaps.quit, function()
    close_codediff_without_qall(tabpage)
  end, { desc = 'Close codediff tab without qall' })
end

local schedule_no_qall_quit_workaround = function(tabpage)
  vim.schedule(function()
    apply_no_qall_quit_workaround(tabpage)
  end)
  vim.defer_fn(function()
    apply_no_qall_quit_workaround(tabpage)
  end, 100)
end
-- END HACK

-- START HACK Remove when https://github.com/esmuellert/codediff.nvim/issues/429 is fixed upstream.
local special_file_tint_ns = vim.api.nvim_create_namespace 'CodeDiffSpecialFileTint'
local tinted_special_file_buffers = {}

local special_file_highlights = {
  A = { side = 'modified', highlight = 'CodeDiffLineInsert' },
  ['??'] = { side = 'modified', highlight = 'CodeDiffLineInsert' },
  D = { side = 'original', highlight = 'CodeDiffLineDelete' },
}

local clear_special_file_tints = function()
  for bufnr in pairs(tinted_special_file_buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, special_file_tint_ns, 0, -1)
    end
  end

  tinted_special_file_buffers = {}
end

local apply_special_file_tint = function(tabpage, status)
  clear_special_file_tints()

  local tint = special_file_highlights[status]
  if not tint then
    return
  end

  local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
  if not ok or not lifecycle.get_session(tabpage) then
    return
  end

  local original_bufnr, modified_bufnr = lifecycle.get_buffers(tabpage)
  local bufnr = tint.side == 'original' and original_bufnr or modified_bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local config = require('codediff.config').options
  local priority = (config.diff.highlight_priority or 100) + 1

  for line = 0, vim.api.nvim_buf_line_count(bufnr) - 1 do
    vim.api.nvim_buf_set_extmark(bufnr, special_file_tint_ns, line, 0, {
      line_hl_group = tint.highlight,
      priority = priority,
    })
  end

  tinted_special_file_buffers[bufnr] = true
end

local schedule_special_file_tint = function(tabpage, status)
  vim.defer_fn(function()
    apply_special_file_tint(tabpage, status)
  end, 100)
end
-- END HACK

require('codediff').setup {
  highlights = {
    line_insert = 'DiffAdd',
    line_delete = 'LeftPaneAdd',
    char_insert = 'DiffText',
    char_delete = 'LeftPaneText',
  },
  diff = {
    disable_inlay_hints = true,
    cycle_hunks_across_files = true,
  },
  explorer = {
    view_mode = 'tree',
  },
  keymaps = {
    view = {
      quit = 'q',
      toggle_explorer = '<leader>b',
      next_hunk = ']h',
      prev_hunk = '[h',
      next_file = '<Tab>',
      prev_file = '<S-Tab>',
      close_on_open_in_prev_tab = true,
      toggle_stage = 's',
    },
    explorer = {
      select = '<CR>',
      refresh = 'R',
    },
  },
}

local explorer_gf_workaround_group = vim.api.nvim_create_augroup('CodeDiffExplorerGfWorkaround', { clear = true })

vim.api.nvim_create_autocmd('User', {
  group = explorer_gf_workaround_group,
  pattern = { 'CodeDiffOpen', 'CodeDiffFileSelect' },
  callback = function(event)
    local tabpage = event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()
    schedule_explorer_gf_workaround(tabpage)
    schedule_hunk_file_fallback_workaround(tabpage)
    schedule_diff_pane_wrap_workaround(tabpage)
    schedule_no_qall_quit_workaround(tabpage)
  end,
})

vim.api.nvim_create_autocmd('TabEnter', {
  group = explorer_gf_workaround_group,
  callback = function()
    local tabpage = vim.api.nvim_get_current_tabpage()
    schedule_explorer_gf_workaround(tabpage)
    schedule_hunk_file_fallback_workaround(tabpage)
    schedule_diff_pane_wrap_workaround(tabpage)
    schedule_no_qall_quit_workaround(tabpage)
  end,
})

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter', 'WinEnter', 'FileType' }, {
  group = explorer_gf_workaround_group,
  callback = function()
    schedule_diff_pane_wrap_workaround(vim.api.nvim_get_current_tabpage())
  end,
})

vim.api.nvim_create_autocmd('User', {
  group = explorer_gf_workaround_group,
  pattern = 'CodeDiffFileSelect',
  callback = function(event)
    local tabpage = event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()
    schedule_special_file_tint(tabpage, event.data and event.data.status)
  end,
})

vim.api.nvim_create_autocmd('User', {
  group = explorer_gf_workaround_group,
  pattern = 'CodeDiffClose',
  callback = clear_special_file_tints,
})
