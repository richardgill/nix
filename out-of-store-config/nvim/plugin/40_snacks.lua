vim.pack.add({ 'https://github.com/folke/snacks.nvim' })

local closeTabsAndSplits = function()
  vim.cmd 'silent! tabonly'
end

-- Make <leader>ff treat ./path and path as the same query.
local normalizeRelativeSearch = function(_, filter)
  local normalize = function(value)
    return value:gsub('^%./+', '')
  end

  local normalizedPattern = normalize(filter.pattern)
  local normalizedSearch = normalize(filter.search)
  if normalizedPattern == filter.pattern and normalizedSearch == filter.search then
    return
  end

  filter.pattern = normalizedPattern
  filter.search = normalizedSearch
  return true
end

local gitignoredByRoot = {}
local uv = vim.uv or vim.loop

local currentCwd = function(ctx)
  return ctx:cwd() or uv.cwd() or '.'
end

local normalizePath = function(path)
  return vim.fs.normalize(path):gsub('/$', '')
end

local getGitRoot = function(ctx)
  return Snacks.git.get_root(currentCwd(ctx))
end

local shellQuote = function(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

local loadGitignoredIndex = function(root)
  local ignored = { files = {}, dirs = {} }
  local handle = io.popen('git -C ' .. shellQuote(root) .. ' ls-files --others --ignored --exclude-standard -z --directory', 'r')
  if not handle then
    return ignored
  end

  local stdout = handle:read '*a'
  local ok = handle:close()
  if not ok then
    return ignored
  end

  for path in stdout:gmatch('[^%z]+') do
    if path:sub(-1) == '/' then
      ignored.dirs[path] = true
    else
      ignored.files[path] = true
    end
  end
  return ignored
end

local getGitignoredIndex = function(root)
  if not gitignoredByRoot[root] then
    gitignoredByRoot[root] = loadGitignoredIndex(root)
  end
  return gitignoredByRoot[root]
end

local relativeToRoot = function(path, root)
  if path == root then
    return ''
  end
  if path:sub(1, #root + 1) == root .. '/' then
    return path:sub(#root + 2)
  end
end

local itemRootPath = function(item, ctx, root)
  local base = normalizePath(item.cwd or currentCwd(ctx))
  local path = item.file:sub(1, 1) == '/'
      and normalizePath(item.file)
    or normalizePath(base .. '/' .. item.file)
  return relativeToRoot(path, root)
end

local isGitignored = function(ignored, path)
  if ignored.files[path] then
    return true
  end

  local parts = vim.split(path, '/', { plain = true, trimempty = true })
  for index = 1, #parts - 1 do
    local parent = table.concat(parts, '/', 1, index)
    if ignored.files[parent] or ignored.dirs[parent .. '/'] then
      return true
    end
  end
  return false
end

local tiltGitignoredFiles = function(item, ctx)
  if not (ctx.picker.opts.ignored and item.file) then
    return
  end

  local root = getGitRoot(ctx)
  if not root then
    return
  end

  root = normalizePath(root)
  local path = itemRootPath(item, ctx, root)
  if path and isGitignored(getGitignoredIndex(root), path) then
    item.ignored = true
    item.score_mul = (item.score_mul or 1) * 0.05
  end
end

local closeTabsBeforeConfirm = function(picker, item, action)
  if vim.api.nvim_win_is_valid(picker.main) then
    vim.api.nvim_win_call(picker.main, closeTabsAndSplits)
  end
  require('snacks.picker.actions').confirm(picker, item, action)
end

require('snacks').setup {
  bigfile = {},
  gitbrowse = {},
  image = {},
  input = {},
  notifier = {},
  quickfile = {},
  scope = {},
  picker = {
    ui_select = true,
    actions = {
      confirm = closeTabsBeforeConfirm,
    },
    layouts = {
      custom_vertical = {
        reverse = true,
        layout = {
          backdrop = false,
          width = 0.95,
          min_width = 80,
          height = 0.95,
          min_height = 30,
          box = 'vertical',
          border = 'rounded',
          title = '{title} {live} {flags}',
          title_pos = 'center',
          { win = 'preview', title = '{preview}', height = 0.5, border = 'bottom' },
          { win = 'list', border = 'none' },
          { win = 'input', height = 1, border = 'top' },
        },
      },
    },
    layout = 'custom_vertical',
    formatters = {
      file = {
        truncate = 120,
      },
    },
    win = {
      -- Override scrolloff for the list window. vim.opt.scrolloff is inherited
      -- and creates a tiny active zone with reverse layouts, causing cursor jumps.
      list = {
        wo = { scrolloff = 0 },
      },
      input = {
        keys = {
          ['<C-Down>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
          ['<C-Up>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
        },
      },
    },
    sources = {
      files = {
        cmd = 'rg',
        hidden = true,
        follow = true,
        transform = tiltGitignoredFiles,
        filter = {
          transform = normalizeRelativeSearch,
        },
      },
      grep = {
        cmd = 'rg',
        transform = tiltGitignoredFiles,
      },
    },
  },
}
