-- LSP root → git root → cwd (mirrors LazyVim.root priority)
local function get_root()
  local buf = vim.api.nvim_get_current_buf()
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    if client.root_dir then
      return client.root_dir
    end
  end
  local git = vim.fs.find('.git', { upward = true, path = vim.fn.expand '%:p:h' })[1]
  return git and vim.fn.fnamemodify(git, ':h') or vim.uv.cwd()
end

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
        '<C-f>',
        function()
          Snacks.picker.lines { pattern = vim.fn.expand '<cword>' }
        end,
        mode = { 'n', 'i', 'v' },
        desc = 'Search buffer for word under cursor',
      },
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
          Snacks.picker.grep { cwd = get_root() }
        end,
        desc = 'Live Grep (Root Dir)',
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
