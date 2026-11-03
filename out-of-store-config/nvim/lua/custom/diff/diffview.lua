-- The fork bundles its Lua dependencies; devicons is optional.
vim.pack.add {
  'https://github.com/nvim-tree/nvim-web-devicons',
  {
    src = 'https://github.com/richardgill/diffview-plus.nvim',
    name = 'diffview-plus.nvim',
    version = 'd8f03aa733bae9af6ad3b6b87b026cd86401eaab',
  },
}

local actions = require 'diffview.actions'
local async = require 'diffview.async'

-- Ephemeral decorations belong to the rendered window, not its shared working-tree buffer.
-- Reusing the namespace replaces the provider on config reload without retaining marks.
local raw_namespace = vim.api.nvim_create_namespace 'custom.diffview.raw'
vim.api.nvim_set_decoration_provider(raw_namespace, {
  on_win = function(_, win, buf, top, bottom)
    local view = require('diffview.lib').tabpage_to_view(vim.api.nvim_win_get_tabpage(win))
    local layout = view and view.cur_layout
    if not layout or layout.name ~= 'diff1_raw' or layout.b.id ~= win or layout.b.file.bufnr ~= buf then
      return false
    end

    local status = view.cur_entry and view.cur_entry.status
    local highlight = status == 'D' and 'LeftPaneAdd' or (status == 'A' or status == '?') and 'DiffAdd'
    if highlight then
      -- Ephemeral line_hl_group is not rendered; a background-only range preserves syntax.
      vim.api.nvim_buf_set_extmark(buf, raw_namespace, top, 0, {
        ephemeral = true,
        end_row = math.min(bottom + 1, vim.api.nvim_buf_line_count(buf)),
        end_col = 0,
        hl_group = highlight,
        hl_eol = true,
        priority = 0,
      })
    end
    return false
  end,
})

local hunk_lines = function(layout, win)
  if layout.name == 'diff1_raw' then
    return { 1 }, true
  end

  -- Whole-file additions/deletions have a null side, not native diff hunks.
  for _, pane in ipairs(layout.windows) do
    if pane.file and pane.file.nulled then
      return { 1 }, true
    end
  end

  return vim.api.nvim_win_call(win.id, function()
    if not vim.wo.diff then
      return {}
    end

    local saved = vim.fn.winsaveview()
    local lines = {}
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    if vim.fn.diff_hlID(1, 1) ~= 0 or vim.fn.diff_filler(1) > 0 then
      lines[1] = 1
    end
    -- Native ]c stops on the same line at the boundary; it never wraps.
    for _ = 1, vim.api.nvim_buf_line_count(0) do
      local before = vim.fn.line '.'
      vim.cmd 'silent! keepjumps normal! ]c'
      local line = vim.fn.line '.'
      if line <= before then
        break
      end
      lines[#lines + 1] = line
    end
    vim.fn.winrestview(saved)
    return lines
  end)
end

local step_hunk = function(view, symbol, direction)
  local files = view.panel:ordered_file_list()
  if #files == 0 then
    return false
  end

  local index
  for i, file in ipairs(files) do
    if file == view.panel.cur_file then
      index = i
    end
  end
  local win = view.cur_layout[symbol] or view.cur_layout:get_main_win()
  local hunks, whole_file = hunk_lines(view.cur_layout, win)
  local line = whole_file and 1 or vim.api.nvim_win_get_cursor(win.id)[1]
  local on_change = vim.api.nvim_win_call(win.id, function()
    return vim.fn.diff_hlID(line, 1) ~= 0
  end)
  local target, prior
  for _, hunk in ipairs(index and hunks or {}) do
    if direction == 1 and hunk > line then
      target = hunk
      break
    elseif direction == -1 and hunk < line then
      prior, target = target, hunk
    end
  end
  -- Inside a changed block, H means the previous hunk, not this block's start.
  if direction == -1 and on_change and not vim.list_contains(hunks, line) then
    target = prior
  end

  if not target then
    index = index or (direction == 1 and 0 or 1)
    -- Visit each visible entry at most once, including when all diffs are empty.
    for offset = 1, #files do
      local file = files[(index + direction * offset - 1) % #files + 1]
      async.await(view:set_file(file, false, true))
      if require('diffview.lib').get_current_view() ~= view or view.cur_entry ~= file then
        return false
      end
      win = view.cur_layout[symbol] or view.cur_layout:get_main_win()
      hunks = hunk_lines(view.cur_layout, win)
      target = hunks[direction == 1 and 1 or #hunks]
      if target then
        break
      end
    end
  end

  if not target then
    return false
  end
  vim.api.nvim_win_call(win.id, function()
    vim.cmd('keepjumps normal! ' .. target .. 'Gzz')
  end)
  return true
end

local pending_hunk_jump
local jump_hunk = function(direction)
  local view = require('diffview.lib').get_current_view()
  if not view then
    return
  end
  -- History panels navigate commits, so leave their diff motions within-file.
  if not view.panel.ordered_file_list then
    vim.cmd.normal { vim.v.count1 .. (direction == 1 and ']c' or '[c'), bang = true }
    return
  end

  local symbol
  for _, name in ipairs(view.cur_layout.symbols) do
    if view.cur_layout[name].id == vim.api.nvim_get_current_win() then
      symbol = name
    end
  end
  local previous, count = pending_hunk_jump, vim.v.count1
  pending_hunk_jump = async.void(function()
    if previous then
      async.await(previous)
    end
    local opening = view:set_file_in_flight()
    if opening then
      async.await(opening)
    end
    for _ = 1, count do
      if require('diffview.lib').get_current_view() ~= view or not step_hunk(view, symbol, direction) then
        return
      end
    end
  end)()
end

local reset_displayed_hunk = function(view, origin)
  local layout = view.cur_layout
  local left, right = layout and layout.a, layout and layout.b
  if not left or not right or layout.name == 'diff1_raw' or left.file.nulled or right.file.nulled then
    vim.notify('No comparison hunk. Use an explicit file-level restore for added/deleted files.', vim.log.levels.WARN)
    return
  end
  if right.file.rev.type ~= require('diffview.vcs.rev').RevType.LOCAL then
    vim.notify('Hunk reset requires a right-hand working-tree pane.', vim.log.levels.WARN)
    return
  end
  if not left:is_valid() or not right:is_valid() then
    return
  end
  if not vim.wo[left.id].diff or not vim.wo[right.id].diff then
    vim.notify('No native comparison hunk. Use an explicit file-level restore for empty/one-sided files.', vim.log.levels.WARN)
    return
  end

  -- Native diffput maps left-side rows to the right, including inserted/deleted lines.
  -- From the sidebar, use the displayed working-tree cursor without moving focus.
  local source = origin == left.id and left or right
  if origin ~= left.id and origin ~= right.id and not view.panel:is_focused() then
    return
  end
  local ok, err = pcall(vim.api.nvim_win_call, source.id, function()
    vim.cmd 'diffupdate'
    vim.cmd((source == left and 'diffput ' .. right.file.bufnr or 'diffget ' .. left.file.bufnr))
  end)
  if not ok then
    vim.notify('Unable to reset displayed hunk: ' .. tostring(err), vim.log.levels.WARN)
  end
end

local reset_hunk = function()
  local view = require('diffview.lib').get_current_view()
  if not view then
    return
  end
  local origin, entry, layout = vim.api.nvim_get_current_win(), view.cur_entry, view.cur_layout
  local cursor = vim.api.nvim_win_get_cursor(origin)
  local right_cursor = layout.b and layout.b:is_valid() and vim.api.nvim_win_get_cursor(layout.b.id)
  local jumping = pending_hunk_jump
  async.void(function()
    if jumping then
      async.await(jumping)
    end
    local opening = view:set_file_in_flight()
    if opening then
      async.await(opening)
    end
    -- Never apply a delayed destructive action to a different file, focus, or row.
    if
      require('diffview.lib').get_current_view() ~= view
      or view.cur_entry ~= entry
      or view.cur_layout ~= layout
      or vim.api.nvim_get_current_win() ~= origin
      or not vim.deep_equal(vim.api.nvim_win_get_cursor(origin), cursor)
      or (right_cursor and (not layout.b:is_valid() or not vim.deep_equal(vim.api.nvim_win_get_cursor(layout.b.id), right_cursor)))
    then
      return
    end
    reset_displayed_hunk(view, origin)
  end)()
end

local common_keymaps = {
  { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close diff view' } },
  -- Diffview saves existing mappings by their expanded lhs, not the <leader> spelling.
  { 'n', vim.g.mapleader .. 'hr', reset_hunk, { desc = 'Reset displayed hunk to left version (buffer only)' } },
  { 'n', '<leader>b', actions.toggle_files, { desc = 'Toggle file tree' } },
  { 'n', '<leader>e', actions.focus_files, { desc = 'Focus file tree' } },
  { 'n', '<Tab>', actions.select_next_entry, { desc = 'Next file, wrapping' } },
  { 'n', '<S-Tab>', actions.select_prev_entry, { desc = 'Previous file, wrapping' } },
  { 'n', 's', actions.toggle_stage_entry, { desc = 'Stage / unstage file (or selection)' } },
  { 'n', 'R', actions.refresh_files, { desc = 'Refresh files' } },
  { 'n', 'gf', actions.goto_file_edit_close, { desc = 'Open file in previous editor and close diff' } },
}

local diff_keymaps = vim.list_extend(vim.deepcopy(common_keymaps), {
  {
    'n',
    'h',
    function()
      jump_hunk(1)
    end,
    { desc = 'Next hunk, cycling files' },
  },
  {
    'n',
    'H',
    function()
      jump_hunk(-1)
    end,
    { desc = 'Previous hunk, cycling files' },
  },
})

require('diffview').setup {
  show_root_path = false,
  show_help_hints = false,
  enhanced_diff_hl = true,
  wrap_entries = true,
  hooks = {
    diff_buf_win_enter = function(_, win, ctx)
      if ctx.symbol == 'a' and ctx.layout_name:match '^diff2_' then
        vim.opt_local.winhighlight:append {
          DiffAdd = 'LeftPaneAdd',
          DiffChange = 'LeftPaneAdd',
          DiffText = 'LeftPaneText',
        }
      end
      local view = require('diffview.lib').get_current_view()
      local layout = view.layouts[require('diffview.config').name_to_layout(ctx.layout_name)]
      for _, pane in ipairs(layout.windows) do
        if pane.id == win then
          pane:use_winopts { foldcolumn = '0', signcolumn = 'no', statuscolumn = '%=%l ' }
        end
      end
      vim.opt_local.fillchars:append { diff = ' ' }
      -- Avoid cursor-line underlines over diff backgrounds; keep line-number emphasis.
      -- https://github.com/sindrets/diffview.nvim/issues/113
      -- https://github.com/neovim/neovim/issues/9800
      vim.opt_local.cursorlineopt = 'number'
    end,
  },
  view = {
    one_sided_layout = 'raw',
    foldlevel = 99,
    default = { layout = 'diff2_horizontal', disable_diagnostics = true, focus_diff = false },
    file_history = { layout = 'diff2_horizontal', disable_diagnostics = true, focus_diff = false },
  },
  file_panel = {
    listing_style = 'tree',
    always_show_sections = true,
    win_config = { position = 'left', width = 40 },
  },
  keymaps = {
    view = diff_keymaps,
    file_panel = vim.list_extend(vim.deepcopy(diff_keymaps), {
      { 'n', '<CR>', actions.select_entry, { desc = 'Select file / toggle directory' } },
      { { 'n', 'x' }, 'm', actions.toggle_select_entry, { desc = 'Toggle reviewed selection' } },
      { 'n', 'gH', actions.toggle_hide_selected, { desc = 'Hide / show reviewed selections' } },
    }),
    file_history_panel = common_keymaps,
  },
}

local diff_against = function(target)
  local result = vim.system({ vim.fn.expand '~/Scripts/git-diff-base-ref', target }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify(vim.trim(result.stderr or 'Unable to resolve Git diff base'), vim.log.levels.ERROR)
    return
  end
  -- Triple-dot selects the common ancestor; --imply-local replaces HEAD with the working tree.
  vim.cmd('DiffviewOpen ' .. vim.trim(result.stdout) .. '...HEAD --imply-local')
end

vim.keymap.set('n', '<leader>dd', '<cmd>DiffviewOpen<CR>', { desc = 'Git [d]iff [d]irty changes' })
vim.keymap.set('n', '<leader>db', function()
  diff_against 'base'
end, { desc = 'Git [d]iff against PR [b]ase' })
vim.keymap.set('n', '<leader>dm', function()
  diff_against 'main'
end, { desc = 'Git [d]iff against [m]ain' })

local attach_hunk_reset = function(bufnr, original_reset)
  local files = package.loaded['diffview.vcs.file']
  local state = files and files.File.attached[bufnr]
  if not state then
    return
  end

  -- Gitsigns can finish attaching after Diffview. Preserve its late mapping for detach.
  local lhs = vim.g.mapleader .. 'hr'
  if not state.saved_keymaps['n ' .. lhs] then
    state.saved_keymaps['n ' .. lhs] = {
      mode = 'n',
      lhs = lhs,
      callback = original_reset,
      opts = { buffer = bufnr, desc = 'Reset hunk' },
    }
  end
  vim.keymap.set('n', lhs, reset_hunk, {
    buffer = bufnr,
    silent = true,
    nowait = true,
    desc = 'Reset displayed hunk to left version (buffer only)',
  })
end

return { attach_hunk_reset = attach_hunk_reset }
