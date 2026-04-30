return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  opts = {
    modes = {
      char = {
        enabled = false,
      },
    },
  },
  keys = {
    {
      'ra',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').jump()
      end,
      desc = 'Flash',
    },
    {
      'rs',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').remote()
      end,
      desc = 'Remote flash',
    },
    { 's', mode = { 'n', 'x', 'o' }, false },
    { 'S', mode = { 'n', 'x', 'o' }, false },
  },
}

-- vim: ts=2 sts=2 sw=2 et
