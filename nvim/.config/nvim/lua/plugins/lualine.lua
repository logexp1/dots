return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        vim.o.statusline = ' '
      else
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      vim.o.laststatus = vim.g.lualine_laststatus

      -- Lazily initialize trouble statusline (trouble loads on demand)
      local trouble_symbols
      local function get_trouble()
        if not trouble_symbols and package.loaded['trouble'] then
          trouble_symbols = require('trouble').statusline {
            mode = 'symbols',
            groups = {},
            title = false,
            filter = { range = true },
            format = '{kind_icon}{symbol.name:Normal}',
            hl_group = 'lualine_c_normal',
          }
        end
        return trouble_symbols
      end

      return {
        options = {
          theme = 'auto',
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { 'snacks_dashboard' } },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = {
            { 'filename', path = 1, symbols = { modified = '  ', readonly = '', unnamed = '' } },
            {
              function() local t = get_trouble(); return t and t.get() or '' end,
              cond = function() local t = get_trouble(); return t ~= nil and t.has() end,
            },
          },
          lualine_x = {
            {
              function() return require('noice').api.status.command.get() end,
              cond = function() return package.loaded['noice'] and require('noice').api.status.command.has() end,
              color = function() return { fg = Snacks.util.color 'Statement' } end,
            },
            {
              function() return require('noice').api.status.mode.get() end,
              cond = function() return package.loaded['noice'] and require('noice').api.status.mode.has() end,
              color = function() return { fg = Snacks.util.color 'Constant' } end,
            },
            {
              require('lazy.status').updates,
              cond = require('lazy.status').has_updates,
              color = function() return { fg = Snacks.util.color 'Special' } end,
            },
            {
              'diagnostics',
              symbols = { error = '󰅚 ', warn = '󰀪 ', info = '󰋽 ', hint = '󰌶 ' },
            },
            {
              'diff',
              symbols = { added = ' ', modified = ' ', removed = ' ' },
              source = function()
                local gs = vim.b.gitsigns_status_dict
                if gs then
                  return { added = gs.added, modified = gs.changed, removed = gs.removed }
                end
              end,
            },
          },
          lualine_y = {
            { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
            { 'location', padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function() return ' ' .. os.date '%R' end,
          },
        },
        extensions = { 'lazy', 'trouble' },
      }
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
