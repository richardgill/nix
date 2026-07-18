local default_formatters = require 'codediff.ui.explorer.formatters'

local M = {}
local marked = {}

local entry_key = function(entry)
  return entry.group .. ':' .. entry.path
end

local is_marked = function(entry)
  local key = entry_key(entry)
  local snapshot = marked[key]
  if not snapshot then
    return false
  end
  if vim.deep_equal(snapshot.stats, entry.stats) then
    return true
  end
  marked[key] = nil
  return false
end

local dim_file_layout = function(layout)
  for side_name, regions in pairs { left = layout.left, right = layout.right } do
    for region_index, region in ipairs(regions) do
      for segment_index, segment in ipairs(region.segments) do
        local is_indent = side_name == 'left' and region_index == 1 and segment_index == 1
        if not is_indent and segment.text:find '%S' then
          segment.hl = 'Comment'
        end
      end
    end
  end
end

local review_summary = function(ctx)
  local summary = { reviewed = 0, insertions = 0, deletions = 0 }
  for _, file in ipairs(ctx.files) do
    if is_marked(file) then
      summary.reviewed = summary.reviewed + 1
    elseif file.stats and not file.stats.binary then
      summary.insertions = summary.insertions + (file.stats.insertions or 0)
      summary.deletions = summary.deletions + (file.stats.deletions or 0)
    end
  end
  return summary
end

local group_summary_segments = function(ctx)
  local review = review_summary(ctx)
  local segments = {
    { text = ' (', hl = 'CodeDiffExplorerTreeGroup' },
    { text = review.reviewed .. '/' .. ctx.file_count, hl = 'CodeDiffExplorerStatFiles' },
  }
  if ctx.stats and ctx.stats.insertions > 0 then
    local insertions = review.reviewed > 0 and review.insertions .. '/' .. ctx.stats.insertions or ctx.stats.insertions
    segments[#segments + 1] = { text = ' · ', hl = 'CodeDiffExplorerTreeGroup' }
    segments[#segments + 1] = { text = '+' .. insertions, hl = 'CodeDiffExplorerStatInsertions' }
  end
  if ctx.stats and ctx.stats.deletions > 0 then
    local deletions = review.reviewed > 0 and review.deletions .. '/' .. ctx.stats.deletions or ctx.stats.deletions
    segments[#segments + 1] = { text = ctx.stats.insertions > 0 and ' ' or ' · ', hl = 'CodeDiffExplorerTreeGroup' }
    segments[#segments + 1] = { text = '-' .. deletions, hl = 'CodeDiffExplorerStatDeletions' }
  end
  segments[#segments + 1] = { text = ')', hl = 'CodeDiffExplorerTreeGroup' }
  return segments
end

M.file = function(ctx)
  local layout = default_formatters.file(ctx)
  if not is_marked(ctx) then
    return layout
  end
  dim_file_layout(layout)
  table.insert(layout.left[1].segments, 2, { text = '✓ ', hl = 'DiagnosticOk' })
  return layout
end

M.group = function(ctx)
  local layout = default_formatters.group(ctx)
  layout.left[3].segments = group_summary_segments(ctx)
  return layout
end

M.toggle_marked = function(context)
  local entry = context.entry
  if entry.kind ~= 'file' then
    return
  end
  local key = entry_key(entry)
  if is_marked(entry) then
    marked[key] = nil
  else
    marked[key] = { stats = vim.deepcopy(entry.stats) }
  end
  context.redraw()
end

return M
