return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = 'lazy.nvim', words = { 'LazyVim' } },
        { path = 'nvim-lspconfig', words = { 'lspconfig.settings' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      { 'mason-org/mason-lspconfig.nvim', config = function() end },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      -- Global capabilities: blink.cmp completions + workspace file rename support
      vim.lsp.config('*', {
        capabilities = vim.tbl_deep_extend('force', require('blink.cmp').get_lsp_capabilities(), {
          workspace = {
            fileOperations = { didRename = true, willRename = true },
          },
        }),
      })

      -- Auto-enable inlay hints on any buffer whose LSP supports them
      Snacks.util.lsp.on({ method = 'textDocument/inlayHint' }, function(buf)
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == '' then
          vim.lsp.inlay_hint.enable(true, { bufnr = buf })
        end
      end)

      -- LSP-based folding when the server supports foldingRange
      Snacks.util.lsp.on({ method = 'textDocument/foldingRange' }, function()
        local win = vim.api.nvim_get_current_win()
        if vim.wo[win].foldmethod ~= 'expr' then
          vim.wo[win].foldmethod = 'expr'
          vim.wo[win].foldexpr = 'v:lua.vim.lsp.foldexpr()'
        end
      end)

      vim.diagnostic.config {
        severity_sort = true,
        update_in_insert = false,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = { source = 'if_many', spacing = 2 },
      }

      -- ── Server settings ─────────────────────────────────────────────────

      vim.lsp.config('pyright', {
        -- Force UTF-8 to match ruff; prevents offset issues with non-ASCII (e.g. Korean)
        capabilities = {
          general = { positionEncodings = { 'utf-8' } },
        },
        settings = {
          python = {
            venvPath = '.',
            venv = '.venv',
            analysis = {
              -- Ruff handles import linting; pyright is for type checking only
              diagnosticSeverityOverrides = {
                reportMissingImports = 'none',
                reportMissingModuleSource = 'none',
              },
            },
          },
        },
      })

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
            codeLens = { enable = true },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = 'Disable',
              semicolon = 'Disable',
              arrayIndex = 'Disable',
            },
          },
        },
      })

      -- ── Mason ────────────────────────────────────────────────────────────

      require('mason-tool-installer').setup {
        ensure_installed = {
          'pyright',
          'ruff',
          'lua-language-server',
          'stylua',
        },
      }

      -- automatic_enable: mason-lspconfig calls vim.lsp.enable() for each
      -- installed server except those in the exclude list
      require('mason-lspconfig').setup {
        ensure_installed = {},
        automatic_enable = { exclude = { 'stylua' } },
      }

      -- markdown-oxide: installed via cargo, not managed by mason
      vim.lsp.enable 'markdown_oxide'
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
