local fuzzy = require('blink.cmp.fuzzy')
local pattern = require('custom.ai-prompt-completion-blink.pattern')

if not fuzzy._ai_prompt_original_get_keyword_range then
  fuzzy._ai_prompt_original_get_keyword_range = fuzzy.get_keyword_range
end

local original_get_keyword_range = fuzzy._ai_prompt_original_get_keyword_range

local is_prompt_filetype = function()
  return vim.bo.filetype == 'prompt'
end

local get_at_query_data = function(line, col)
  local before_cursor = line:sub(1, col)
  local at_pos = before_cursor:match('.*()@' .. pattern .. '$')
  if not at_pos then
    return nil
  end
  return { start_col = at_pos, end_col = col }
end

fuzzy.get_keyword_range = function(line, col, range)
  if not is_prompt_filetype() then
    return original_get_keyword_range(line, col, range)
  end

  local query_data = get_at_query_data(line, col)
  if query_data then
    return query_data.start_col, query_data.end_col
  end

  return original_get_keyword_range(line, col, range)
end

return {}
