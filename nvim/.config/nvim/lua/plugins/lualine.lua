local function get_root()
  local buf = vim.api.nvim_get_current_buf()
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    if client.root_dir then
      return vim.uv.fs_realpath(client.root_dir) or client.root_dir
    end
  end
  local git = vim.fs.find('.git', { upward = true, path = vim.fn.expand '%:p:h' })[1]
  return git and vim.fn.fnamemodify(git, ':h') or (vim.uv.fs_realpath(vim.uv.cwd()) or vim.uv.cwd())
end

-- Shows project root name with icon when root differs from cwd
local function root_dir()
  local function get()
    local root = get_root()
    local cwd = vim.uv.fs_realpath(vim.uv.cwd()) or vim.uv.cwd()
    if root == cwd then
      return nil
    end
    return vim.fs.basename(root)
  end
  return {
    function()
      return '󱉭 ' .. (get() or '')
    end,
    cond = function()
      return get() ~= nil
    end,
    color = function()
      return { fg = Snacks.util.color 'Special' }
    end,
  }
end

-- Shows file path relative to root/cwd, truncated to 3 parts, with modified indicator
local function pretty_path()
  return function()
    local path = vim.fn.expand '%:p'
    if path == '' then
      return ''
    end

    local root = get_root()
    if path:find(root, 1, true) == 1 then
      path = path:sub(#root + 2)
    end

    local parts = vim.split(path, '/', { plain = true })
    if #parts > 3 then
      parts = { parts[1], '…', unpack(parts, #parts - 1, #parts) }
    end
    if vim.bo.modified then
      parts[#parts] = parts[#parts] .. ''
    end
    return table.concat(parts, '/')
  end
end

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
            root_dir(),
            {
              'diagnostics',
              symbols = { error = '󰅚 ', warn = '󰀪 ', info = '󰋽 ', hint = '󰌶 ' },
            },
            { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
            { pretty_path() },
            {
              function()
                local t = get_trouble()
                return t and t.get() or ''
              end,
              cond = function()
                local t = get_trouble()
                return t ~= nil and t.has()
              end,
            },
          },
          lualine_x = {
            {
              function()
                return require('noice').api.status.command.get()
              end,
              cond = function()
                return package.loaded['noice'] and require('noice').api.status.command.has()
              end,
              color = function()
                return { fg = Snacks.util.color 'Statement' }
              end,
            },
            {
              function()
                return require('noice').api.status.mode.get()
              end,
              cond = function()
                return package.loaded['noice'] and require('noice').api.status.mode.has()
              end,
              color = function()
                return { fg = Snacks.util.color 'Constant' }
              end,
            },
            {
              require('lazy.status').updates,
              cond = require('lazy.status').has_updates,
              color = function()
                return { fg = Snacks.util.color 'Special' }
              end,
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
            function()
              return ' ' .. os.date '%R'
            end,
          },
        },
        extensions = { 'lazy', 'trouble' },
      }
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
