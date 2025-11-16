return {
  'folke/tokyonight.nvim',
  priority = 1000, -- Make sure to load this before all the other start plugins.
  init = function()
    vim.cmd.colorscheme 'tokyonight-night'

    -- You can configure highlights by doing something like:
    vim.cmd.hi 'Comment gui=none'
  end,
  config = function()
    require('tokyonight').setup {
      -- Debugging:
      -- `:InspectTree` or `:Inspect` with your cursor over an element
      on_colors = function(colors)
        local util = require 'tokyonight.util'
        colors.comment = util.lighten(colors.comment, 0.7)
        colors.bg_visual = util.lighten(colors.bg_visual, 0.8)
        colors.fg_gutter = util.lighten(colors.fg_gutter, 0.7)
        colors.git.add = '#9ece6a'
      end,
      on_highlights = function(hl, colors)
        local util = require 'tokyonight.util'
        -- builtin variables like console
        hl['@variable.builtin'] = { fg = '#7aa2f7' }
        -- unused variables
        hl['DiagnosticUnnecessary'].fg = util.lighten(hl['DiagnosticUnnecessary'].fg, 0.7)
        -- tsx tags <WasRed>
        hl['@tag.tsx'] = { fg = colors.blue1 }
        -- Diff brighter
        hl['DiffAdd'].bg = util.darken('#9ece6a', 0.3)
        hl['DiffDelete'].bg = util.darken(colors.red, 0.5)

        -- highlighting for multi cursor plugin
        hl['MultiCursor'] = hl['IncSearch']
        hl['MultiCursorMain'] = hl['IncSearch']

        -- Better inline code highlighting
        hl['@markup.raw.markdown_inline'] = { bg = util.darken(colors.bg_highlight, 0.3), fg = colors.blue }

        -- Snacks picker directories - use same color as files
        hl['SnacksPickerDirectory'] = { fg = colors.fg }
        hl['SnacksPickerDir'] = { fg = colors.fg }
      end,
      plugins = {
        -- enable all plugins when not using lazy.nvim
        -- set to false to manually enable/disable plugins
        all = package.loaded.lazy == nil,
        -- uses your plugin manager to automatically enable needed plugins
        -- currently only lazy.nvim is supported
        auto = true,
        -- add any plugins here that you want to enable
        -- for all possible plugins, see:
        --   * https://github.com/folke/tokyonight.nvim/tree/main/lua/tokyonight/groups

        copilot = false, -- suggestions were too dark
      },
    }
  end,
}
