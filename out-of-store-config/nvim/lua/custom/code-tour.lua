local M = {}
local api, fn = vim.api, vim.fn
local namespace = api.nvim_create_namespace 'CodeTour'
local active
local shortcuts = { l = ']l', L = '[l', q = '<Cmd>CodeTourClear<CR>' }

local restore_shortcuts = function(state)
  if not state.mappings then
    return
  end
  for key in pairs(shortcuts) do
    pcall(api.nvim_del_keymap, 'n', key)
  end
  for _, mapping in ipairs(state.mappings) do
    fn.mapset('n', false, mapping)
  end
  state.mappings = nil
end

local install_shortcuts = function(state)
  if state.mappings then
    return
  end
  state.mappings = {}
  for _, mapping in ipairs(api.nvim_get_keymap 'n') do
    if shortcuts[mapping.lhs] then
      state.mappings[#state.mappings + 1] = mapping
    end
  end
  for key, rhs in pairs(shortcuts) do
    vim.keymap.set('n', key, rhs, { remap = key ~= 'q' })
  end
end

local fail = function(field, message)
  error('Code tour: ' .. field .. ': ' .. message, 0)
end

local check_fields = function(value, allowed, field)
  if type(value) ~= 'table' or vim.islist(value) then
    fail(field, 'expected an object')
  end
  for key in pairs(value) do
    if not allowed[key] then
      fail(field .. '.' .. tostring(key), 'unknown field')
    end
  end
end

local check_string = function(value, field)
  if type(value) ~= 'string' then
    fail(field, 'expected a string')
  end
end

local is_integer = function(value)
  return type(value) == 'number' and value == math.floor(value) and value < math.huge
end

local absolute_path = function(path, cwd)
  return fn.simplify(path:sub(1, 1) == '/' and path or cwd .. '/' .. path)
end

local source_lines = function(path, field)
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) and api.nvim_buf_get_name(buf) == path then
      return api.nvim_buf_get_lines(buf, 0, -1, false)
    end
  end
  local ok, lines = pcall(fn.readfile, path)
  if not ok then
    fail(field, path .. ': ' .. tostring(lines))
  end
  return #lines == 0 and { '' } or lines
end

local validate = function(json_path, cwd, source_cwd)
  check_string(json_path, 'json_path')
  if json_path == '' then
    fail('json_path', 'must not be empty')
  end
  local path = absolute_path(json_path, cwd)
  local read_ok, contents = pcall(fn.readfile, path)
  if not read_ok then
    fail('json_path', path .. ': ' .. tostring(contents))
  end
  local decode_ok, tour = pcall(vim.json.decode, table.concat(contents, '\n'))
  if not decode_ok then
    fail('json_path', path .. ': invalid JSON: ' .. tostring(tour))
  end
  check_fields(tour, { title = true, entries = true }, path)
  check_string(tour.title, 'title')
  if type(tour.entries) ~= 'table' or not vim.islist(tour.entries) or #tour.entries == 0 then
    fail('entries', 'expected a nonempty array')
  end

  local entries, files = {}, {}
  for index, entry in ipairs(tour.entries) do
    local field = 'entry ' .. index
    check_fields(entry, { filename = true, line = true, end_line = true, location_list_text = true, buffer_annotation = true }, field)
    check_string(entry.filename, field .. '.filename')
    if entry.filename == '' then
      fail(field .. '.filename', 'must not be empty')
    end
    check_string(entry.location_list_text, field .. '.location_list_text')
    if entry.buffer_annotation ~= nil then
      check_string(entry.buffer_annotation, field .. '.buffer_annotation')
    end
    if not is_integer(entry.line) or entry.line < 1 then
      fail(field .. '.line', 'expected a positive 1-based integer')
    end
    local last = entry.end_line == nil and entry.line or entry.end_line
    if not is_integer(last) or last < entry.line then
      fail(field .. '.end_line', 'expected an inclusive integer >= line')
    end
    local filename = absolute_path(entry.filename, source_cwd)
    local lines = files[filename] or source_lines(filename, field .. '.filename')
    files[filename] = lines
    if last > #lines then
      fail(field .. (entry.end_line == nil and '.line' or '.end_line'), filename .. ': range exceeds ' .. #lines .. ' lines')
    end
    entries[index] = {
      filename = filename,
      lnum = entry.line,
      end_lnum = last,
      col = lines[entry.line]:find '%S' or 1,
      text = entry.location_list_text,
      annotation = entry.buffer_annotation,
    }
  end
  return { title = tour.title, entries = entries }
end

local original_window = function(state)
  if api.nvim_win_is_valid(state.original_win) then
    return state.original_win
  end
  if api.nvim_tabpage_is_valid(state.original_tab) then
    return api.nvim_tabpage_get_win(state.original_tab)
  end
  for _, tab in ipairs(api.nvim_list_tabpages()) do
    if tab ~= state.tab then
      return api.nvim_tabpage_get_win(tab)
    end
  end
end

local snapshot_buffers = function()
  local before = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    before[buf] = { loaded = api.nvim_buf_is_loaded(buf), listed = vim.bo[buf].buflisted }
  end
  return before
end

local snapshot_views = function()
  local views = {}
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    views[win] = { buffer = api.nvim_win_get_buf(win), view = api.nvim_win_call(win, fn.winsaveview) }
  end
  return views
end

M.format = function(info)
  local entries = fn.getloclist(info.winid, { id = info.id, items = 1 }).items
  local lines = {}
  for index = info.start_idx, info.end_idx do
    local entry = entries[index]
    lines[#lines + 1] = entry.text .. '  [' .. fn.fnamemodify(api.nvim_buf_get_name(entry.bufnr), ':t') .. ':' .. entry.lnum .. ']'
  end
  return lines
end

local close_tour_tab = function(tab)
  local hidden = {}
  for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
    local buf = api.nvim_win_get_buf(win)
    if vim.bo[buf].modified and hidden[buf] == nil then
      hidden[buf] = vim.bo[buf].bufhidden
      vim.bo[buf].bufhidden = 'hide'
    end
  end
  api.nvim_set_current_tabpage(tab)
  local ok, err = pcall(vim.cmd, 'hide tabclose')
  for buf, option in pairs(hidden) do
    if api.nvim_buf_is_valid(buf) then
      vim.bo[buf].bufhidden = option
    end
  end
  if not ok then
    error(err, 0)
  end
end

M.clear = function()
  if not active then
    return
  end
  local state = active
  active = nil
  restore_shortcuts(state)
  for buf in pairs(state.managed) do
    if api.nvim_buf_is_valid(buf) then
      api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
    end
  end
  local restore = original_window(state)
  if state.tab and api.nvim_tabpage_is_valid(state.tab) then
    if not restore then
      vim.cmd 'noautocmd tabnew'
      restore = api.nvim_get_current_win()
    end
    close_tour_tab(state.tab)
  end
  if restore and api.nvim_win_is_valid(restore) then
    api.nvim_set_current_win(restore)
  end
  for buf in pairs(state.managed) do
    if api.nvim_buf_is_valid(buf) then
      local old = state.before[buf]
      if not vim.bo[buf].modified and #fn.win_findbuf(buf) == 0 then
        if not old then
          api.nvim_buf_delete(buf, { force = false })
        elseif not old.loaded then
          api.nvim_buf_delete(buf, { unload = true, force = false })
        end
      end
      if old and api.nvim_buf_is_valid(buf) then
        vim.bo[buf].buflisted = old.listed
      end
    end
  end
  for win, saved in pairs(state.views) do
    if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == saved.buffer then
      api.nvim_win_call(win, function()
        fn.winrestview(saved.view)
      end)
    end
  end
end

local show = function(tour, state)
  vim.cmd 'noautocmd tabnew'
  state.tab = api.nvim_get_current_tabpage()
  state.owner = api.nvim_get_current_win()
  state.managed[api.nvim_get_current_buf()] = true
  local buffers, items = {}, {}
  for _, entry in ipairs(tour.entries) do
    local buf = buffers[entry.filename]
    if not buf then
      -- Display before marking: offscreen bufload can spuriously mark files modified on first display.
      vim.cmd('keepalt hide edit ' .. fn.fnameescape(entry.filename))
      buf = api.nvim_get_current_buf()
      buffers[entry.filename] = buf
      state.managed[buf] = true
    end
    api.nvim_buf_set_extmark(buf, namespace, entry.lnum - 1, 0, {
      end_row = entry.end_lnum,
      end_col = 0,
      hl_group = 'Search',
      hl_eol = true,
      virt_text = entry.annotation and { { '  ' .. entry.annotation, 'DiagnosticInfo' } } or nil,
      virt_text_pos = 'eol',
      priority = 150,
    })
    items[#items + 1] = { filename = entry.filename, lnum = entry.lnum, col = entry.col, text = entry.text }
  end
  fn.setloclist(state.owner, {}, ' ', {
    title = tour.title,
    items = items,
    idx = 1,
    quickfixtextfunc = "v:lua.require'custom.code-tour'.format",
  })
  local first = tour.entries[1]
  -- Jump here explicitly so 'switchbuf' cannot redirect the initial jump into the original tab.
  vim.cmd('keepalt hide buffer ' .. buffers[first.filename])
  api.nvim_win_set_cursor(state.owner, { first.lnum, first.col - 1 })
  vim.cmd 'normal! zz'
  vim.cmd 'botright lopen 12'
  state.managed[api.nvim_get_current_buf()] = true
  api.nvim_set_current_win(state.owner)
  install_shortcuts(state)
end

M.open = function(json_path)
  local cwd = fn.getcwd()
  local origin = active and original_window(active) or api.nvim_get_current_win()
  local source_cwd = origin and fn.getcwd(api.nvim_win_get_number(origin), api.nvim_tabpage_get_number(api.nvim_win_get_tabpage(origin))) or cwd
  local tour = validate(json_path, cwd, source_cwd)

  M.clear()
  local state = {
    original_win = api.nvim_get_current_win(),
    original_tab = api.nvim_get_current_tabpage(),
    before = snapshot_buffers(),
    views = snapshot_views(),
    managed = {},
  }
  active = state
  local ok, err = xpcall(function()
    show(tour, state)
  end, debug.traceback)
  if not ok then
    M.clear()
    error(err, 0)
  end
  return #tour.entries
end

local group = api.nvim_create_augroup('CodeTourShortcuts', { clear = true })
api.nvim_create_autocmd('TabLeave', {
  group = group,
  callback = function()
    if active and active.tab == api.nvim_get_current_tabpage() then
      restore_shortcuts(active)
    end
  end,
})
api.nvim_create_autocmd('TabEnter', {
  group = group,
  callback = function()
    if active and active.tab == api.nvim_get_current_tabpage() then
      install_shortcuts(active)
    end
  end,
})
api.nvim_create_autocmd('TabClosed', {
  group = group,
  callback = function()
    if active and active.tab and not api.nvim_tabpage_is_valid(active.tab) then
      restore_shortcuts(active)
    end
  end,
})

api.nvim_create_user_command('CodeTourClear', M.clear, { desc = 'Clear the code tour and restore the original workspace' })

return M
