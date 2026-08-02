local M = {}

local file_command = { 'rg', '--files' }
local file_query_pattern = '[%w%./_\\%-~,]*'
local command_query_pattern = '[%w%-%._:]*'
local max_items = 200
local file_state = { cache = nil, loading = false, waiters = {} }
local skill_state = { cache = nil, loading = false, waiters = {} }
local trigger_generation = 0

local feed = function(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, 'n', false)
end

local close_completion = function()
  if vim.fn.pumvisible() == 1 then
    feed '<C-e>'
  end
end

local get_cwd = function()
  local uv = vim.uv or vim.loop
  return uv.cwd() or vim.fn.getcwd()
end

local has_upper = function(value)
  return value:find '%u' ~= nil
end

local normalize_case = function(value, case_sensitive)
  return case_sensitive and value or value:lower()
end

local parse_stdout = function(stdout)
  if not stdout or stdout == '' then
    return {}
  end
  return vim.split(stdout, '\n', { plain = true, trimempty = true })
end

local add_path = function(paths, path)
  if not path or path == '' then
    return
  end
  paths[#paths + 1] = path
end

local resolve_pi_path = function()
  if vim.fn.executable 'mise' == 1 then
    local mise_path = vim.fn.systemlist({ 'mise', 'which', 'pi' })[1]
    if mise_path and mise_path ~= '' then
      return mise_path
    end
  end
  return vim.fn.systemlist({ 'which', 'pi' })[1]
end

local pi_path = resolve_pi_path()

local parse_token = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local cursor_col = cursor[2]
  local before = line:sub(1, cursor_col)

  local file_query = before:match('.*@(' .. file_query_pattern .. ')$')
  if file_query then
    local at_pos = before:match('.*()@' .. file_query_pattern .. '$')
    if at_pos then
      return { kind = 'file', query = file_query, start_col = at_pos }
    end
  end

  local command_query = before:match('^(/' .. command_query_pattern .. ')$')
  if command_query then
    return { kind = 'command', query = command_query, start_col = 1 }
  end

  command_query = before:match('.*%s(/' .. command_query_pattern .. ')$')
  if command_query then
    local space_start = before:match('.*()%s/' .. command_query_pattern .. '$')
    if space_start then
      return { kind = 'command', query = command_query, start_col = space_start + 1 }
    end
  end

  return nil
end

local token_still_current = function(token)
  local current = parse_token()
  return current and current.kind == token.kind and current.query == token.query and current.start_col == token.start_col
end

local list_files = function(cwd, callback)
  if file_state.cache and file_state.cache.cwd == cwd then
    callback(file_state.cache.files)
    return
  end

  file_state.waiters[#file_state.waiters + 1] = callback
  if file_state.loading then
    return
  end

  file_state.loading = true
  vim.system(file_command, { text = true, cwd = cwd }, function(result)
    local files = result.code == 0 and parse_stdout(result.stdout) or {}
    file_state.cache = { cwd = cwd, files = files }
    file_state.loading = false
    local waiters = file_state.waiters
    file_state.waiters = {}
    vim.schedule(function()
      for _, waiter in ipairs(waiters) do
        waiter(files)
      end
    end)
  end)
end

local boundary_bonus = function(value, index)
  if index == 1 then
    return -12
  end
  local previous = value:sub(index - 1, index - 1)
  if previous:match '[/_%-%.]' then
    return -8
  end
  return 0
end

local fuzzy_score = function(query, value)
  if query == '' then
    return 0
  end

  local query_index = 1
  local score = 0
  local previous_match = 0
  for value_index = 1, #value do
    if value:sub(value_index, value_index) == query:sub(query_index, query_index) then
      local gap = previous_match == 0 and value_index - 1 or value_index - previous_match - 1
      score = score + gap + boundary_bonus(value, value_index)
      previous_match = value_index
      query_index = query_index + 1
      if query_index > #query then
        return score
      end
    end
  end
  return nil
end

local overlay_score_offset = function(path)
  return path:match '^overlay/' and 7 or 0
end

local normalized_path_parts = function(path, query)
  local basename = vim.fn.fnamemodify(path, ':t')
  local case_sensitive = has_upper(query)
  return {
    query = normalize_case(query, case_sensitive),
    path = normalize_case(path, case_sensitive),
    basename = normalize_case(basename, case_sensitive),
  }
end

local substring_candidate_score = function(path, query, index)
  if query == '' then
    return index / 10000 + overlay_score_offset(path)
  end
  local parts = normalized_path_parts(path, query)
  local target = query:find('/', 1, true) and parts.path or parts.basename
  local pos = target:find(parts.query, 1, true)
  if not pos then
    return nil
  end
  return pos - 100 + index / 10000 + overlay_score_offset(path)
end

local fuzzy_candidate_score = function(path, query, index)
  local parts = normalized_path_parts(path, query)
  local target = query:find('/', 1, true) and parts.path or parts.basename
  local fuzzy = fuzzy_score(parts.query, target) or fuzzy_score(parts.query, parts.path)
  if not fuzzy then
    return nil
  end
  return fuzzy + index / 10000 + overlay_score_offset(path)
end

local collect_path_matches = function(paths, scorer, query)
  local matches = {}
  for index, path in ipairs(paths) do
    local score = scorer(path, query, index)
    if score then
      matches[#matches + 1] = { path = path, score = score }
    end
  end
  return matches
end

local sort_path_matches = function(matches)
  table.sort(matches, function(left, right)
    if left.score == right.score then
      return left.path < right.path
    end
    return left.score < right.score
  end)
  return matches
end

local paths_from_matches = function(matches)
  return vim.tbl_map(function(match)
    return match.path
  end, matches)
end

local filter_paths = function(paths, query)
  local substring_matches = sort_path_matches(collect_path_matches(paths, substring_candidate_score, query))
  if #substring_matches > 0 then
    return paths_from_matches(substring_matches)
  end
  return paths_from_matches(sort_path_matches(collect_path_matches(paths, fuzzy_candidate_score, query)))
end

local build_file_items = function(paths)
  local items = {}
  for _, path in ipairs(paths) do
    items[#items + 1] = {
      word = '@' .. path,
      abbr = path,
      equal = 1,
      preselect = #items == 0 and 1 or nil,
    }
    if #items >= max_items then
      return items
    end
  end
  return items
end

local parse_skill_names = function(stdout)
  local names = {}
  for line in (stdout or ''):gmatch '[^\n]+' do
    local ok, message = pcall(vim.json.decode, line)
    if ok and message.command == 'get_commands' and message.success then
      for _, command in ipairs(message.data.commands) do
        local name = command.source == 'skill' and command.name:match '^skill:(.+)$' or nil
        if name then
          names[#names + 1] = name
        end
      end
    end
  end
  table.sort(names)
  return names
end

local finish_loading_skills = function(names)
  skill_state.cache = names
  skill_state.loading = false
  local waiters = skill_state.waiters
  skill_state.waiters = {}
  vim.schedule(function()
    for _, waiter in ipairs(waiters) do
      waiter(skill_state.cache)
    end
  end)
end

local load_skills = function(callback)
  if skill_state.cache then
    callback(skill_state.cache)
    return
  end

  skill_state.waiters[#skill_state.waiters + 1] = callback
  if skill_state.loading then
    return
  end

  skill_state.loading = true
  if not pi_path or pi_path == '' then
    finish_loading_skills {}
    return
  end

  local command = { pi_path, '--mode', 'rpc', '--no-session', '--offline' }
  local options = { text = true, cwd = get_cwd(), stdin = '{"type":"get_commands"}\n' }
  vim.system(command, options, function(result)
    finish_loading_skills(result.code == 0 and parse_skill_names(result.stdout) or {})
  end)
end

local fuzzy_match = function(query, value)
  if query == '' or query == '/' then
    return true
  end
  local query_index = 1
  local normalized_query = query:lower()
  local normalized_value = value:lower()
  for value_index = 1, #normalized_value do
    if normalized_value:sub(value_index, value_index) == normalized_query:sub(query_index, query_index) then
      query_index = query_index + 1
      if query_index > #normalized_query then
        return true
      end
    end
  end
  return false
end

local build_command_items = function(skills, query)
  local items = {}
  for _, skill in ipairs(skills) do
    local label = '/skill:' .. skill
    if fuzzy_match(query, label) then
      items[#items + 1] = {
        word = label,
        abbr = label,
        equal = 1,
        preselect = #items == 0 and 1 or nil,
      }
    end
  end
  return items
end

local complete = function(token, items)
  if vim.api.nvim_get_mode().mode:sub(1, 1) ~= 'i' or not token_still_current(token) then
    return
  end
  if #items == 0 then
    close_completion()
    return
  end
  vim.fn.complete(token.start_col, items)
end

local complete_files = function(token)
  list_files(get_cwd(), function(files)
    local paths = filter_paths(files, token.query)
    complete(token, build_file_items(paths))
  end)
end

local complete_commands = function(token)
  load_skills(function(skills)
    complete(token, build_command_items(skills, token.query))
  end)
end

M.trigger = function()
  local token = parse_token()
  if not token then
    close_completion()
    return
  end
  if token.kind == 'file' then
    complete_files(token)
    return
  end
  complete_commands(token)
end

M.trigger_deferred = function()
  trigger_generation = trigger_generation + 1
  local generation = trigger_generation
  vim.defer_fn(function()
    if generation == trigger_generation then
      M.trigger()
    end
  end, 25)
end

M.select_next = function()
  if vim.fn.pumvisible() == 1 then
    return vim.api.nvim_replace_termcodes('<C-n>', true, false, true)
  end
  return vim.api.nvim_replace_termcodes('<Tab>', true, false, true)
end

M.select_prev = function()
  if vim.fn.pumvisible() == 1 then
    return vim.api.nvim_replace_termcodes('<C-p>', true, false, true)
  end
  return vim.api.nvim_replace_termcodes('<S-Tab>', true, false, true)
end

M.accept_or_newline = function()
  if vim.fn.pumvisible() == 1 then
    return vim.api.nvim_replace_termcodes('<C-y> ', true, false, true)
  end
  return vim.api.nvim_replace_termcodes('<CR>', true, false, true)
end

M.setup_buffer = function(bufnr)
  list_files(get_cwd(), function() end)
  load_skills(function() end)
  vim.opt_local.completeopt = { 'menuone', 'noselect', 'noinsert', 'preselect' }
  local group = vim.api.nvim_create_augroup('ai-prompt-native-completion', { clear = false })
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, {
    group = group,
    buffer = bufnr,
    callback = M.trigger_deferred,
  })
  vim.keymap.set('i', '<C-Space>', M.trigger, { buffer = bufnr, silent = true })
  vim.keymap.set('i', '<Tab>', M.select_next, { buffer = bufnr, expr = true, silent = true })
  vim.keymap.set('i', '<S-Tab>', M.select_prev, { buffer = bufnr, expr = true, silent = true })
  vim.keymap.set('i', '<CR>', M.accept_or_newline, { buffer = bufnr, expr = true, silent = true })
end

return M
