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
        filter = {
          transform = normalizeRelativeSearch,
        },
      },
      grep = {
        cmd = 'rg',
      },
    },
  },
}
