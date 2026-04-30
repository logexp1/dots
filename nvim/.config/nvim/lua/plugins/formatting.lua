return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      '<localleader>f',
      function()
        require('conform').format { async = true }
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  -- This will provide type hinting with LuaLS
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_organize_imports', 'ruff_format' },
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettier' },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = 'fallback',
    },
    -- Set up format-on-save
    format_on_save = { timeout_ms = 500 },
    -- Customize formatters
    formatters = {
      prettier = {
        prepend_args = function(_, ctx)
          if vim.bo[ctx.buf].filetype == 'markdown' then
            return { '--prose-wrap', 'always', '--print-width', '80' }
          end
          return {}
        end,
      },
      stylelua = {
        prepend_args = {
          '--config-path',
          vim.fn.stdpath 'config' .. '/.stylua.toml',
        },
      },
      shfmt = {
        append_args = { '-i', '2' },
      },
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
