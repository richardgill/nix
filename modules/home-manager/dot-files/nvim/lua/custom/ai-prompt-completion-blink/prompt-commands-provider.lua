local CompletionItemKind = require('blink.cmp.types').CompletionItemKind

local source = {}

local trigger_characters = { '/' }
local query_pattern = '[%w%-%._:]*'

local resolve_pi_path = function()
  local lines = vim.fn.systemlist({ 'which', 'pi' })
  local pi_path = lines[1]
  if not pi_path or pi_path == '' then
    return nil
  end
  if pi_path:match('/mise/shims/pi$') and vim.fn.executable('mise') == 1 then
    local resolved = vim.fn.systemlist({ 'mise', 'which', 'pi' })[1]
    if resolved and resolved ~= '' then
      return resolved
    end
  end
  return pi_path
end

local resolve_skills_module = function()
  local pi_path = resolve_pi_path()
  if not pi_path or pi_path == '' then
    return nil
  end
  local base_dir = vim.fn.fnamemodify(pi_path, ':h:h')
  local skills_module = base_dir .. '/lib/node_modules/@mariozechner/pi-coding-agent/dist/core/skills.js'
  if vim.fn.filereadable(skills_module) == 1 then
    return skills_module
  end
  return nil
end

local skills_module = resolve_skills_module()
local skill_state = { cache = nil, loading = false, waiters = {} }

local is_pi_prompt = function(bufnr)
  if not bufnr or type(bufnr) ~= 'number' then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then
    return false
  end
  return name:match('/tmp/pi%-editor%-.*%.pi%.md$') ~= nil
end

local get_query_data = function(line, cursor_col)
  local before = line:sub(1, cursor_col)
  local query = before:match('.*(/' .. query_pattern .. ')$')
  if not query then
    return nil
  end
  local start_col = before:match('.*()/' .. query_pattern .. '$')
  if not start_col then
    return nil
  end
  return { query = query, start_col = start_col }
end

local get_text_edit_range = function(ctx, start_col)
  local line = ctx.cursor[1] - 1
  local start_char = start_col - 1
  return {
    start = { line = line, character = start_char },
    ['end'] = { line = line, character = ctx.cursor[2] },
  }
end

local load_skills = function(callback)
  if skill_state.cache then
    callback(skill_state.cache)
    return function() end
  end

  if not skills_module then
    skill_state.cache = {}
    callback(skill_state.cache)
    return function() end
  end

  skill_state.waiters[#skill_state.waiters + 1] = callback
  if skill_state.loading then
    return function() end
  end

  skill_state.loading = true
  local script = [[
const { loadSkills } = await import(process.argv[1]);
const { skills } = loadSkills();
console.log(JSON.stringify(skills.map((skill) => skill.name)));
]]

  local handle
  handle = vim.system({ 'node', '--input-type=module', '-e', script, skills_module }, { text = true }, function(result)
    skill_state.loading = false
    local names = {}
    if result.code == 0 and result.stdout then
      local ok, decoded = pcall(vim.json.decode, result.stdout)
      if ok and type(decoded) == 'table' then
        for _, name in ipairs(decoded) do
          if type(name) == 'string' and name ~= '' then
            names[#names + 1] = name
          end
        end
      end
    end
    table.sort(names)
    skill_state.cache = names
    local waiters = skill_state.waiters
    skill_state.waiters = {}
    for _, cb in ipairs(waiters) do
      cb(skill_state.cache)
    end
  end)

  return function()
    if handle then
      handle:kill(9)
    end
  end
end

local build_commands = function(skills)
  local commands = {}
  for _, name in ipairs(skills) do
    commands[#commands + 1] = { label = '/skill:' .. name, detail = 'Run ' .. name }
  end
  return commands
end

local filter_commands = function(commands, query)
  if query == '' or query == '/' then
    return commands
  end
  local normalized = query:lower()
  local filtered = {}
  for _, command in ipairs(commands) do
    if command.label:lower():find(normalized, 1, true) then
      filtered[#filtered + 1] = command
    end
  end
  return filtered
end

local build_items = function(commands, range)
  local items = {}
  for _, command in ipairs(commands) do
    items[#items + 1] = {
      label = command.label,
      detail = command.detail,
      kind = CompletionItemKind.Keyword,
      filterText = command.label,
      textEdit = {
        newText = command.label,
        range = range,
      },
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
    }
  end
  return items
end

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

load_skills(function() end)

function source:get_trigger_characters()
  return trigger_characters
end

function source:get_completions(ctx, callback)
  callback = vim.schedule_wrap(callback)

  local cursor_col = ctx.cursor[2] + 1
  local query_data = get_query_data(ctx.line, cursor_col)
  if not query_data then
    callback { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }
    return
  end

  if not is_pi_prompt(ctx.bufnr) then
    callback { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }
    return
  end

  return load_skills(function(skills)
    local commands = build_commands(skills)
    local filtered = filter_commands(commands, query_data.query)
    local range = get_text_edit_range(ctx, query_data.start_col)
    local items = build_items(filtered, range)
    callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
  end)
end

return source
