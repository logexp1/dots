return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'folke/snacks.nvim',
    },
    cmd = 'Neogit',
    keys = {
      { 'S', mode = { 'n' }, '<cmd>Neogit<cr>', desc = 'show neogit UI' },
    },
    config = function()
      require('neogit').setup {
        mappings = {
          popup = {
            p = 'PushPopup',
            F = 'PullPopup',
          },
        },
      }
    end,
  },
}
