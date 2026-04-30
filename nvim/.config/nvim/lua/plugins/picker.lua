return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      image = { enabled = false },
      dashboard = { example = 'doom' },
      picker = {
        enabled = true,
        layout = {
          preset = 'telescope',
        },
        matcher = {
          frecency = true,
        },
        win = {
          input = {
            keys = {
              ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
            },
          },
          list = {
            keys = {
              ['<Esc>'] = { 'close', mode = { 'n' } },
            },
          },
        },
        sources = {
          projects = {
            format = function(item, _)
              local name = vim.fn.fnamemodify(item.file, ':t')
              local parent = vim.fn.fnamemodify(item.file, ':~:h')
              return {
                { '  ', 'SnacksPickerDirectory' },
                { name, 'SnacksPickerDirectory' },
                { '  ' .. parent, 'SnacksPickerDir' },
              }
            end,
          },
        },
      },
      scroll = {
        -- conflicts with stay-centered.nvim
        enabled = true,
      },
    },
    keys = {
      {
        '<leader><space>',
        function()
          Snacks.picker.keymaps()
        end,
        desc = 'Keymaps',
      },
      {
        '<leader>s',
        function()
          Snacks.picker.buffers()
        end,
        desc = 'Switch Buffers',
      },
      {
        '<leader>/',
        function()
          Snacks.picker.grep()
        end,
        desc = 'Live Grep',
      },
      {
        '<leader>:',
        function()
          Snacks.picker.command_history()
        end,
        desc = 'Command History',
      },
      {
        '<leader>ff',
        function()
          Snacks.picker.smart()
        end,
        desc = 'Smart Find Files',
      },
      {
        '<leader>fb',
        function()
          Snacks.picker.lines()
        end,
        desc = 'Find in buffer',
      },
      {
        '<leader>p',
        function()
          Snacks.picker.git_files()
        end,
        desc = 'Find Git Files',
      },
      {
        '<leader>fr',
        function()
          Snacks.picker.recent()
        end,
        desc = 'Recent Files',
      },
      {
        '<leader>c',
        function()
          Snacks.picker.projects()
        end,
        desc = 'Change Project',
      },
      {
        '<leader>h',
        function()
          Snacks.picker.help()
        end,
        desc = 'Help',
      },
      {
        '<leader>:',
        function()
          Snacks.picker.command_history()
        end,
        desc = 'command history',
      },
    },
  },
}
