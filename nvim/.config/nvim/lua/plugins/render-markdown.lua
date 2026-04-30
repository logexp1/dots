return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown' },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    completions = { lsp = { enabled = true } },
    heading = {
      width = 'block',
      border = true,
    },
    code = {
      width = 'block',
      border = 'thin',
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
