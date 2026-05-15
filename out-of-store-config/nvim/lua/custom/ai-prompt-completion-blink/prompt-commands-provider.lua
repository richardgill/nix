local CompletionItemKind = require('blink.cmp.types').CompletionItemKind

local source = {}

local trigger_characters = { '/' }
local query_pattern = '[%w%-%._:]*'

local add_path = function(paths, path)
  if not path or path == '' then
    return
  end
  paths[#paths + 1] = path
end

local resolve_pi_paths = function()
  local paths = {}
  if vim.fn.executable('mise') == 1 then
    add_path(paths, vim.fn.systemlist({ 'mise', 'which', 'pi' })[1])
  end
  add_path(paths, vim.fn.systemlist({ 'which', 'pi' })[1])
  return paths
end

local package_scopes = { '@earendil-works', '@mariozechner' }

local resolve_skills_module = function()
  for _, pi_path in ipairs(resolve_pi_paths()) do
    local base_dir = vim.fn.fnamemodify(pi_path, ':h:h')
    for _, scope in ipairs(package_scopes) do
      local skills_module = base_dir .. '/lib/node_modules/' .. scope .. '/pi-coding-agent/dist/core/skills.js'
      if vim.fn.filereadable(skills_module) == 1 then
        return skills_module
      end
    end
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
  -- // Only match slash commands at line start or after whitespace to avoid @path segments.
  local query = before:match('^(/' .. query_pattern .. ')$')
  if query then
    return { start_col = 1 }
  end

  query = before:match('.*%s(/' .. query_pattern .. ')$')
  if not query then
    return nil
  end

  local space_start = before:match('.*()%s/' .. query_pattern .. '$')
  if not space_start then
    return nil
  end

  return { start_col = space_start + 1 }
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
let result;
try {
  result = loadSkills({ cwd: process.cwd(), skillPaths: [], includeDefaults: true });
} catch (_error) {
  result = loadSkills();
}
console.log(JSON.stringify(result.skills.map((skill) => skill.name)));
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
    local range = get_text_edit_range(ctx, query_data.start_col)
    local items = build_items(commands, range)
    callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
  end)
end

return source
