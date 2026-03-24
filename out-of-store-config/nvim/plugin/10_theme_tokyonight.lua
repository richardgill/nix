vim.pack.add({ 'https://github.com/folke/tokyonight.nvim' })

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

    -- GitHub-style diff colors (carefully matched to GitHub's diff UI)
    local gh_green = '#3fb950'
    local gh_red = '#f85149'
    local gh_blue = '#58a6ff'
    -- Line backgrounds
    hl['DiffAdd'] = { bg = util.blend(gh_green, 0.20, colors.bg) }
    hl['DiffDelete'] = { bg = util.blend(colors.fg_gutter, 0.08, colors.bg) }
    hl['DiffChange'] = { bg = util.blend(gh_blue, 0.12, colors.bg) }
    -- Word-level changes (fg + nocombine disables syntax highlighting)
    hl['DiffText'] = { bg = util.blend(gh_green, 0.50, colors.bg), fg = colors.fg, nocombine = true }
    -- vscode-diff.nvim highlight groups (left pane = deletions/red, right pane = insertions/green)
    local codediff_filler_bg = util.blend(colors.fg_gutter, 0.08, colors.bg)
    hl['CodeDiffLineInsert'] = { bg = util.blend(gh_green, 0.20, colors.bg) }
    hl['CodeDiffLineChange'] = { bg = util.blend(gh_blue, 0.12, colors.bg) }
    hl['CodeDiffLineDelete'] = { bg = util.blend(gh_red, 0.12, colors.bg) }
    hl['CodeDiffCharInsert'] = { bg = util.blend(gh_green, 0.50, colors.bg), fg = colors.fg, nocombine = true }
    hl['CodeDiffCharDelete'] = { bg = util.blend(gh_red, 0.42, colors.bg), fg = colors.fg, nocombine = true }
    hl['CodeDiffFiller'] = { fg = codediff_filler_bg, bg = codediff_filler_bg }

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
    all = true,
    -- add any plugins here that you want to enable
    -- for all possible plugins, see:
    --   * https://github.com/folke/tokyonight.nvim/tree/main/lua/tokyonight/groups

    copilot = false, -- suggestions were too dark
  },
}
vim.cmd.colorscheme 'tokyonight-night'
vim.cmd.hi 'Comment gui=none'
