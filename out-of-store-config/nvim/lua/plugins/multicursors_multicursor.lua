-- Multi cursors is on the neovim roadmap for 0.12
return {
  'jake-stewart/multicursor.nvim',
  branch = '1.0',
  config = function()
    local mc = require 'multicursor-nvim'
    mc.setup()

    local set = vim.keymap.set

    -- x represents all Visual modes collectively (Visual, Visual Line, and Visual Block)
    -- Add or skip adding a new cursor by matching word/selection
    set({ 'n', 'x' }, '<leader>mu', function()
      mc.matchAddCursor(1)
    end, { desc = '[M]ulti cursor [U]nder' })

    -- Add and remove cursors with control + left click.
    set('n', '<c-leftmouse>', mc.handleMouse)
    set('n', '<c-leftdrag>', mc.handleMouseDrag)
    set('n', '<c-leftrelease>', mc.handleMouseRelease)

    -- Disable and enable cursors.

    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings.
    mc.addKeymapLayer(function(layerSet)
      layerSet({ 'n', 'x' }, 'n', function()
        mc.matchAddCursor(1)
      end)
      layerSet({ 'n', 'x' }, 's', function()
        mc.matchSkipCursor(1)
      end)
      set({ 'n', 'x' }, 'N', function()
        mc.matchAddCursor(-1)
      end)
      layerSet({ 'n', 'x' }, 'S', function()
        mc.matchSkipCursor(-1)
      end)

      -- Enable and clear cursors using escape.
      layerSet('n', '<esc>', function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- Customize how cursors look.
    local hl = vim.api.nvim_set_hl
    hl(0, 'MultiCursorCursor', { reverse = true })
    hl(0, 'MultiCursorVisual', { link = 'Visual' })
    hl(0, 'MultiCursorSign', { link = 'SignColumn' })
    hl(0, 'MultiCursorMatchPreview', { link = 'Search' })
    hl(0, 'MultiCursorDisabledCursor', { reverse = true })
    hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
  end,
}
