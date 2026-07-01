-- mdmath.nvim — inline LaTeX math ($...$ / $$...$$) rendered as real images
-- via the kitty graphics protocol. Emacs org-mode `preview-latex` equivalent.
-- Requires (all present on this machine): node, npm, rsvg-convert, ImageMagick
-- `magick`, kitty >= 0.28, nvim >= 0.10, treesitter `markdown_inline` parser.
return {
  'Thiago4532/mdmath.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = { 'markdown' },
  -- build is handled automatically by lazy.nvim; `:MdMath build` rebuilds the
  -- Node.js render server if it ever gets out of sync.
  opts = {
    filetypes = { 'markdown' }, -- auto-render math when a markdown buffer opens
    foreground = 'Normal',
    anticonceal = true, -- reveal raw source on the cursor line, like render-markdown
    hide_on_insert = true, -- show raw source while editing in insert mode
    dynamic = true,
    dynamic_scale = 1.0,
    update_interval = 400,
    internal_scale = 1.0,
  },
  keys = {
    {
      '<leader>tm',
      function()
        -- Buffer-level toggle. Default state is on (filetypes includes markdown),
        -- so the first press turns it off.
        if vim.b.mdmath_enabled == nil then
          vim.b.mdmath_enabled = true
        end
        vim.b.mdmath_enabled = not vim.b.mdmath_enabled
        if vim.b.mdmath_enabled then
          vim.cmd 'MdMath enable'
          vim.notify('mdmath: math preview ON', vim.log.levels.INFO)
        else
          vim.cmd 'MdMath disable'
          vim.notify('mdmath: math preview OFF', vim.log.levels.INFO)
        end
      end,
      ft = 'markdown',
      desc = 'Toggle LaTeX math preview (mdmath)',
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
