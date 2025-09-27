return {
  'stevearc/conform.nvim',
  lazy = false,
  config = function()
    -- Debug issues using :ConformInfo
    require('conform').setup {
      log_level = vim.log.levels.DEBUG,
      notify_on_error = true,
      format_on_save = function()
        return {
          timeout_ms = 700,
          lsp_fallback = true,
          stop_after_first = true,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        go = { lsp_format = 'prefer' },
        typescript = { 'biome', 'prettierd' },
        typescriptreact = { 'biome', 'prettierd' },
        javascriptreact = { 'biome', 'prettierd' },
        json = { 'biome', 'prettierd' },
        jsonc = { 'biome', 'prettierd' },
        mdx = { lsp_format = 'never' },
        markdown = { lsp_format = 'never' },
        nix = { lsp_format = 'prefer' },
        -- fallback to prettierd for any unspecified filetypes
        ['_'] = {},
      },
    }

    vim.keymap.set('', '<leader>cf', function()
      require('conform').format { async = true, lsp_fallback = true }
    end, { desc = '[F]ormat buffer' })

    -- FocusLost event to run format first and then save all buffers
    vim.api.nvim_create_autocmd('FocusLost', {
      callback = function()
        -- Format using conform with async and lsp_fallback
        -- Save all open buffers
        vim.cmd 'silent! wall'
      end,
    })
  end,
}
