return {
  'saghen/blink.cmp',

  -- use a release tag to download pre-built binaries
  version = '1.*',
  config = function()
    require('blink.cmp').setup {
      -- If <C-Space> isn't working on mac, check your preferences
      -- System Preferences > Keyboard > Keyboard Shortcuts > Input Sources > (remove Ctrl+Space and Ctrl+Shift+Space).
      keymap = { preset = 'enter' },

      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release
        nerd_font_variant = 'mono',
      },

      snippets = { preset = 'default' },
      -- Remove 'buffer' if you don't want text completions, by default it's only enabled when LSP returns no items
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        per_filetype = {
          codecompanion = { 'codecompanion' },
        },
      },

      enabled = function()
        return not vim.tbl_contains({ 'markdown' }, vim.bo.filetype)
      end,
      -- experimental signature help support
      signature = { enabled = false },
      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
        -- Display a preview of the selected item on the current line
        ghost_text = { enabled = false },
      },
    }
  end,
  -- allows extending the providers array elsewhere in your config
  -- without having to redefine it
  opts_extend = { 'sources.default' },
}
