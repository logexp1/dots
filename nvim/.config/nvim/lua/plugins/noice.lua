return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  opts = {
    cmdline = {
      enabled = true,
    },
    lsp = {
      progress = { enabled = false },
      hover = { enabled = false },
      signature = { enabled = false },
    },
  },
  keys = {
    { '<leader>m', '<cmd>Noice<cr>', desc = 'Messages history' },
  },
}

-- vim: ts=2 sts=2 sw=2 et
