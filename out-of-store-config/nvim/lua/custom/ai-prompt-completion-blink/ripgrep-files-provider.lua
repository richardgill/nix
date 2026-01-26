local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
local query_pattern = require('custom.ai-prompt-completion-blink.pattern')

local source = {}

local command = { 'rg', '--files' }
local trigger_characters = { '@', '/', '.', '_', '-', '\\', '~', ',' }

local has_upper = function(value)
  return value:find '%u' ~= nil
end

local normalize_case = function(value, case_sensitive)
  return case_sensitive and value or value:lower()
end

local get_cwd = function()
  local uv = vim.uv or vim.loop
  return uv.cwd() or vim.fn.getcwd()
end

local get_query_data = function(line, cursor_col)
  local before_cursor = line:sub(1, cursor_col)
  local query = before_cursor:match('.*@(' .. query_pattern .. ')$')
  if not query then
    return nil
  end
  local at_pos = before_cursor:match('.*()@' .. query_pattern .. '$')
  if not at_pos then
    return nil
  end
  return { query = query, start_col = at_pos + 1 }
end

local get_text_edit_range = function(ctx, start_col)
  local line = ctx.cursor[1] - 1
  local start_char = start_col - 1
  return {
    start = { line = line, character = start_char },
    ['end'] = { line = line, character = ctx.cursor[2] },
  }
end

local parse_stdout = function(stdout)
  if not stdout or stdout == '' then
    return {}
  end
  return vim.split(stdout, '\n', { plain = true, trimempty = true })
end

local filter_paths = function(paths, query)
  local case_sensitive = has_upper(query)
  local normalized_query = normalize_case(query, case_sensitive)
  local filtered = {}
  for _, path in ipairs(paths) do
    local normalized_path = normalize_case(path, case_sensitive)
    if normalized_path:find(normalized_query, 1, true) then
      filtered[#filtered + 1] = path
    end
  end
  return filtered
end

local build_items = function(paths, range)
  local items = {}
  for _, path in ipairs(paths) do
    items[#items + 1] = {
      label = path,
      kind = CompletionItemKind.File,
      filterText = path,
      textEdit = {
        newText = path,
        range = range,
      },
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
    }
  end
  return items
end

local list_files = function(self, cwd, callback)
  if self.cache and self.cache.cwd == cwd then
    callback(self.cache.files)
    return function() end
  end

  local handle
  handle = vim.system(command, { text = true, cwd = cwd }, function(result)
    local files = result.code == 0 and parse_stdout(result.stdout) or {}
    self.cache = { cwd = cwd, files = files }
    callback(files)
  end)

  return function()
    if handle then
      handle:kill(9)
    end
  end
end

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.cache = nil
  return self
end

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

  local cwd = get_cwd()
  local range = get_text_edit_range(ctx, query_data.start_col)

  return list_files(self, cwd, function(files)
    local filtered = filter_paths(files, query_data.query)
    local items = build_items(filtered, range)
    callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
  end)
end

return source
