return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'saghen/blink.cmp',
    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- lazydev configures lua_ls for nvim Lua development (vim globals work properly)
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        },
      },
    },
    { 'ray-x/lsp_signature.nvim', opts = {} },
  },
  config = function()
    --    This function gets run when an LSP attaches to a particular buffer.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

        --  Useful when your language has ways of declaring types without an actual implementation.
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        map('<leader>cw', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[Code] [W]orkspace Symbols')

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('<leader>crn', vim.lsp.buf.rename, '[C]ode [R]e[n]ame')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'v' })

        -- Opens a popup that displays documentation about the word under your cursor
        map('K', vim.lsp.buf.hover, 'Hover Documentation')

        -- This is not Goto Definition, this is Goto Declaration.
        -- For example, in C this would take you to the header.
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
        ---@param client vim.lsp.Client
        ---@param method vim.lsp.protocol.Method
        ---@param bufnr? integer some lsp support methods only in specific files
        ---@return boolean
        local function client_supports_method(client, method, bufnr)
          if vim.fn.has 'nvim-0.11' == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end
        if client then
          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
          if client.name == 'vtsls' then
            vim.keymap.set('n', '<leader>oi', function()
              vim.cmd 'VtsExec remove_unused_imports'
              vim.defer_fn(function()
                require('conform').format { async = true }
              end, 100)
            end, { desc = '[O]rganize [I]mports' })
            map('<leader>crf', '<cmd>:VtsExec rename_file<cr>', '[C]ode [R]ename [F]ile')
          end
        end
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    -- delete me
    -- local capabilities = vim.lsp.protocol.make_client_capabilities()
    -- capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    --
    -- LSPs come from: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md which is a collection of LSP configs
    -- You can debug current buffer with :LspInfo
    -- You can debug an LSP with :LspLog
    local servers = {
      -- clangd = {},
      gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            experimentalPostfixCompletions = true,
            staticcheck = true,
            symbolScope = 'workspace',
            --
            -- Inlay hints will be supported in nvim 0.10.
            -- Turn them all on for now, but they don't show.
            -- After 0.10 you will probably want to have a toggle
            -- for these.
            --
            hints = {
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              assignVariableTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      },
      -- pyright = {},
      astro = {},
      biome = {},
      eslint = {},
      ruff = {},
      tailwindcss = {},
      ['jedi-language-server'] = {},
      ['kotlin_language_server'] = {},
      jsonls = {
        settings = {
          json = {
            validate = { enable = true },
            format = { enable = false },
          },
        },
      },
      -- rust_analyzer = {},
      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`tsserver`) will work just fine
      -- tsserver = {},
      --
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            telemetry = {
              enable = false,
            },
          },
        },
      },
      nixd = {
        -- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md#configuration-overview
        settings = {
          nixd = {
            nixpkgs = {
              expr = 'import (builtins.getFlake "' .. vim.fn.getcwd() .. '").inputs.nixpkgs { }',
            },
            formatting = {
              command = { 'nixfmt' },
            },
            options = {
              nixos = {
                expr = '(builtins.getFlake "' .. vim.fn.getcwd() .. '").nixosConfigurations.beelink-gk55.options',
              },
              home_manager = {
                expr = '(builtins.getFlake "' .. vim.fn.getcwd() .. '").nixosConfigurations.beelink-gk55.options.home-manager.users.type.getSubOptions []',
              },
            },
          },
        },
      },
    }

    -- Ensure the servers and tools above are installed
    --  To check the current status of installed tools and/or manually install
    --  other tools, you can run
    --    :Mason
    --
    --  You can press `g?` for help in this menu.
    require('mason').setup()

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    -- Remove nixd from mason installation (installed via nix)
    ensure_installed = vim.tbl_filter(function(name)
      return name ~= 'nixd'
    end, ensure_installed)
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
      'gofumpt', -- Used to format Go code
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    -- Configure all servers using the new vim.lsp.config API
    for server_name, server_config in pairs(servers) do
      local config = vim.tbl_deep_extend('force', {
        capabilities = capabilities,
      }, server_config)
      vim.lsp.config(server_name, config)
    end

    require('mason-lspconfig').setup()
  end,
}
