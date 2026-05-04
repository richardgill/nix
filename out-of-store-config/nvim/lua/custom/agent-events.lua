local M = {}

local ns = vim.api.nvim_create_namespace 'custom.agent-events'

local sign_hl = 'AgentEventSign'
local sign_text = '▌'
local valid_kinds = { bash = true, edit = true, read = true, write = true, assistant_citation = true }
local kind_highlights = {
  bash = 'Function',
  write = 'Statement',
  edit = 'Statement',
  read = 'Type',
  assistant_citation = 'Comment',
}

local get_color = function(group, key)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  return hl[key]
end

local blend_color = function(fg, bg, alpha)
  local red = math.floor((math.floor(fg / 65536) % 256) * alpha + (math.floor(bg / 65536) % 256) * (1 - alpha))
  local green = math.floor((math.floor(fg / 256) % 256) * alpha + (math.floor(bg / 256) % 256) * (1 - alpha))
  local blue = math.floor((fg % 256) * alpha + (bg % 256) * (1 - alpha))
  return string.format('#%02x%02x%02x', red, green, blue)
end

local setup_highlights = function()
  local normal_bg = get_color('Normal', 'bg') or get_color('NormalFloat', 'bg') or 0x1f2335
  local accent = get_color('DiagnosticInfo', 'fg') or get_color('Function', 'fg') or 0x7aa2f7
  vim.api.nvim_set_hl(0, sign_hl, { fg = blend_color(accent, normal_bg, 0.78) })
end

setup_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('custom-agent-events-highlight', { clear = true }),
  callback = setup_highlights,
})

local get_session_dir = function(cwd)
  local normalized = vim.fn.fnamemodify(cwd, ':p'):gsub('/$', ''):gsub('^/', '')
  local session_name = '--' .. normalized:gsub('/', '-') .. '--'
  return vim.fs.joinpath(vim.fn.expand '~/.pi/agent/sessions', session_name)
end

local line_suffix = function(event)
  local start_line = tonumber(event.startLine)
  local end_line = tonumber(event.endLine)
  if not start_line then
    return ''
  end
  if not end_line or end_line == start_line then
    return ':' .. start_line
  end
  return ':' .. start_line .. '-' .. end_line
end

local shorten = function(value, max_length)
  value = tostring(value or ''):gsub('%s+', ' ')
  if #value <= max_length then
    return value
  end
  return value:sub(1, max_length - 1) .. '…'
end

local event_path = function(event, cwd)
  local absolute_path = event.absolutePath
  if type(event.path) == 'string' and event.path ~= '' and event.path ~= absolute_path then
    return event.path
  end
  if absolute_path:sub(1, #cwd + 1) == cwd .. '/' then
    return './' .. absolute_path:sub(#cwd + 2)
  end
  return vim.fn.fnamemodify(absolute_path, ':~')
end

local utc_offset = function(seconds)
  local sign, hours, minutes = os.date('%z', seconds):match '^([+-])(%d%d)(%d%d)$'
  if not sign then
    return 0
  end
  local offset = tonumber(hours) * 3600 + tonumber(minutes) * 60
  return sign == '-' and -offset or offset
end

local timestamp_seconds = function(timestamp)
  if type(timestamp) ~= 'string' then
    return nil
  end
  local year, month, day, hour, min, sec, zone = timestamp:match '^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)[%.%d]*(Z?)'
  if not year then
    return nil
  end
  local seconds = os.time { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
  if zone == 'Z' then
    return seconds + utc_offset(seconds)
  end
  return seconds
end

local age = function(timestamp)
  local seconds = timestamp_seconds(timestamp)
  if not seconds then
    return ''
  end
  local diff = math.max(0, os.difftime(os.time(), seconds))
  if diff < 60 then
    return string.format('%ds', diff)
  end
  if diff < 3600 then
    return string.format('%dm', math.floor(diff / 60))
  end
  if diff < 86400 then
    return string.format('%dh', math.floor(diff / 3600))
  end
  return string.format('%dd', math.floor(diff / 86400))
end

local action = function(event)
  return event.action
end

local location = function(event, cwd)
  return event_path(event, cwd) .. line_suffix(event)
end

local center_truncate = function(value, max_length)
  if #value <= max_length then
    return value
  end
  local left = math.floor((max_length - 1) / 2)
  local right = max_length - 1 - left
  return value:sub(1, left) .. '…' .. value:sub(#value - right + 1)
end

local stat_file = function(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == 'file'
end

local event_kind = function(event)
  return valid_kinds[event.kind] and event.kind or nil
end

local is_file_event = function(event)
  return type(event) == 'table'
    and type(event.action) == 'string'
    and type(event.absolutePath) == 'string'
    and event_kind(event)
    and stat_file(event.absolutePath)
end

local event_files = function(session_dir)
  local files = vim.fn.glob(vim.fs.joinpath(session_dir, '*-file-line-events.jsonl'), false, true)
  table.sort(files)
  return files
end

local decode_line = function(line)
  local ok, event = pcall(vim.json.decode, line)
  if ok then
    return event
  end
end

local read_events_file = function(file)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return {}
  end
  return vim.tbl_filter(is_file_event, vim.tbl_map(decode_line, lines))
end

local sort_events = function(events)
  table.sort(events, function(a, b)
    return tostring(a.timestamp or '') > tostring(b.timestamp or '')
  end)
  return events
end

local event_detail = function(event)
  if event.source == 'bash_output' then
    return ''
  end
  return shorten(event.detail or '', 90)
end

local to_item = function(event, index, cwd)
  local item_location = location(event, cwd)
  local item_action = action(event)
  local detail = event_detail(event)
  local item_display = event.display or (item_action .. ' ' .. item_location)
  return {
    idx = index,
    text = table.concat({ item_display, event.rawCommand or '', detail }, ' '),
    file = event.absolutePath,
    kind = event_kind(event),
    action = item_action,
    location = item_location,
    detail = detail,
    display = item_display,
    preview_title = event.previewTitle or item_display,
    age = age(event.timestamp),
    start_line = tonumber(event.startLine),
    end_line = tonumber(event.endLine) or tonumber(event.startLine),
    pos = tonumber(event.startLine) and { tonumber(event.startLine), 0 } or nil,
  }
end

M.collect = function(cwd)
  cwd = vim.fn.fnamemodify(cwd or vim.fn.getcwd(), ':p'):gsub('/$', '')
  local session_dir = get_session_dir(cwd)
  local events = {}
  local items = {}
  for _, file in ipairs(event_files(session_dir)) do
    vim.list_extend(events, read_events_file(file))
  end
  for index, event in ipairs(sort_events(events)) do
    items[#items + 1] = to_item(event, index, cwd)
  end
  return items, session_dir
end

local action_hl = function(kind)
  return kind_highlights[kind] or 'Identifier'
end

local format_event = function(item)
  local action_text = string.format('%-12s', item.action)
  local detail_text = item.detail ~= '' and (' — ' .. item.detail) or ''
  local age_text = item.age ~= '' and ('  ' .. item.age) or ''
  return {
    { action_text, action_hl(item.kind) },
    {
      '',
      resolve = function(max_width)
        local width = math.max(20, max_width - #action_text - #detail_text - #age_text)
        return { { center_truncate(item.location, width), 'SnacksPickerFile' } }
      end,
    },
    { detail_text, 'String' },
    { age_text, 'Comment' },
  }
end

local highlight_range = function(buf, item)
  if not (buf and vim.api.nvim_buf_is_valid(buf) and item.start_line) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local end_line = math.min(item.end_line or item.start_line, vim.api.nvim_buf_line_count(buf))
  for line = item.start_line, end_line do
    vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
      sign_text = sign_text,
      sign_hl_group = sign_hl,
      priority = 200,
    })
  end
end

local preview_topline = function(item, height)
  local start_line = item.start_line
  local end_line = item.end_line or item.start_line
  local range_height = end_line - start_line + 1
  local context = range_height >= height and 0 or math.floor((height - range_height) / 2)
  return math.max(1, start_line - math.min(context, 5))
end

local position_preview = function(ctx)
  if not ctx.item.start_line then
    return
  end
  vim.api.nvim_win_call(ctx.win, function()
    vim.wo.scrolloff = 0
    vim.fn.winrestview {
      topline = preview_topline(ctx.item, vim.api.nvim_win_get_height(ctx.win)),
      lnum = ctx.item.start_line,
      col = 0,
    }
  end)
end

local preview_event = function(ctx)
  ctx.item.preview_title = ctx.item.preview_title or ctx.item.display
  require('snacks').picker.preview.file(ctx)
  ctx.preview:wo { cursorline = false }
  highlight_range(ctx.buf, ctx.item)
  position_preview(ctx)
end

local jump_to_item = function(item)
  if not item.start_line then
    return
  end
  local line = math.min(item.start_line, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.cmd 'normal! zz'
end

M.clear_highlight = function()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

local open_event = function(picker, item)
  if not item then
    return
  end
  picker:close()
  vim.schedule(function()
    vim.cmd.edit(vim.fn.fnameescape(item.file))
    jump_to_item(item)
    highlight_range(vim.api.nvim_get_current_buf(), item)
  end)
end

M.pick = function()
  local cwd = vim.fn.getcwd()
  local items, session_dir = M.collect(cwd)
  if #items == 0 then
    require('snacks').notify.warn('No agent file events found in ' .. session_dir)
    return
  end
  require('snacks').picker.pick {
    source = 'agent_events',
    title = 'Agent file events',
    items = items,
    format = format_event,
    preview = preview_event,
    confirm = open_event,
  }
end

return M
