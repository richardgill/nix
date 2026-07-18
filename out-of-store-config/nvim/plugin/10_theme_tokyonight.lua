vim.pack.add({ 'https://github.com/folke/tokyonight.nvim' })

require('tokyonight').setup {
  -- Debugging:
  -- `:InspectTree` or `:Inspect` with your cursor over an element
  on_colors = function(colors)
    local util = require 'tokyonight.util'
    colors.comment = util.lighten(colors.comment, 0.6)
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
    local diff_fg = util.blend('#ffffff', 0.35, colors.fg)
    hl['RemoteGitSignAdd'] = { fg = util.blend(hl['GitSignsAdd'].fg, 0.55, colors.bg) }
    hl['RemoteGitSignChange'] = { fg = util.blend(hl['GitSignsChange'].fg, 0.55, colors.bg) }
    hl['RemoteGitSignDelete'] = { fg = util.blend(hl['GitSignsDelete'].fg, 0.55, colors.bg) }
    -- Line backgrounds
    hl['DiffAdd'] = { bg = util.blend(gh_green, 0.13, colors.bg) }
    hl['DiffDelete'] = { bg = util.blend(colors.fg_gutter, 0.08, colors.bg) }
    hl['DiffChange'] = { bg = util.blend(gh_green, 0.13, colors.bg) }
    -- Word-level changes (fg + nocombine disables syntax highlighting)
    hl['DiffText'] = { bg = util.blend(gh_green, 0.32, colors.bg), fg = diff_fg, nocombine = true }
    hl['LeftPaneAdd'] = { bg = util.blend(gh_red, 0.12, colors.bg) }
    hl['LeftPaneText'] = { bg = util.blend(gh_red, 0.31, colors.bg), fg = diff_fg, nocombine = true }
    -- vscode-diff.nvim highlight groups (left pane = deletions/red, right pane = insertions/green)
    local codediff_filler_bg = util.blend(colors.fg_gutter, 0.11, colors.bg)
    hl['CodeDiffLineInsert'] = { bg = util.blend(gh_green, 0.13, colors.bg) }
    hl['CodeDiffLineChange'] = { bg = util.blend(gh_green, 0.13, colors.bg) }
    hl['CodeDiffLineDelete'] = { bg = util.blend(gh_red, 0.12, colors.bg) }
    hl['CodeDiffGutterInsert'] = { bg = util.blend(gh_green, 0.13, colors.bg), fg = diff_fg }
    hl['CodeDiffGutterDelete'] = { bg = util.blend(gh_red, 0.12, colors.bg), fg = diff_fg }
    hl['CodeDiffGutterInsertNumber'] = { bg = util.blend(gh_green, 0.32, colors.bg), fg = diff_fg }
    hl['CodeDiffGutterDeleteNumber'] = { bg = util.blend(gh_red, 0.31, colors.bg), fg = diff_fg }
    hl['CodeDiffCharInsert'] = { bg = util.blend(gh_green, 0.32, colors.bg), fg = diff_fg, nocombine = true }
    hl['CodeDiffCharDelete'] = { bg = util.blend(gh_red, 0.31, colors.bg), fg = diff_fg, nocombine = true }
    hl['CodeDiffFiller'] = { bg = codediff_filler_bg }

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
