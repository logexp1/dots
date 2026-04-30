return {
  'folke/tokyonight.nvim',
  priority = 1000,
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('tokyonight').setup {
      transparent = true,
      styles = {
        comments = { italic = false },
        sidebars = 'transparent',
        floats = 'transparent',
      },
    }
    vim.cmd.colorscheme 'tokyonight-night'
  end,
}

-- vim: ts=2 sts=2 sw=2 et
