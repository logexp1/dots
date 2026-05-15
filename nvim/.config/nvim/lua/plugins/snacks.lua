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
    config = function(_, opts)
      local function open_trash()
        local files_dir = vim.fn.expand '~/.local/share/Trash/files'
        local info_dir = vim.fn.expand '~/.local/share/Trash/info'

        local function fmt_size(bytes)
          if not bytes then
            return '   ?'
          end
          if bytes < 1024 then
            return string.format('%4d', bytes)
          end
          if bytes < 1024 * 1024 then
            return string.format('%3.0fk', bytes / 1024)
          end
          if bytes < 1024 * 1024 * 1024 then
            return string.format('%3.0fM', bytes / (1024 * 1024))
          end
          return string.format('%3.0fG', bytes / (1024 * 1024 * 1024))
        end

        local items = {}
        local handle = vim.uv.fs_scandir(files_dir)
        if handle then
          local i = 0
          while true do
            local name, ftype = vim.uv.fs_scandir_next(handle)
            if not name then
              break
            end
            i = i + 1
            local info_path = info_dir .. '/' .. name .. '.trashinfo'
            local file_path = files_dir .. '/' .. name
            local original, date = '(unknown)', '(unknown)'
            local f = io.open(info_path, 'r')
            if f then
              local content = f:read '*a'
              f:close()
              local p = content:match 'Path=([^\n]+)'
              local d = content:match 'DeletionDate=([^\n]+)'
              if p then
                original = p:gsub('%%(%x%x)', function(hex)
                  return string.char(tonumber(hex, 16))
                end)
              end
              if d then
                date = d:gsub('T', ' ')
              end
            end
            local stat = vim.uv.fs_stat(file_path)
            table.insert(items, {
              idx = i,
              text = name .. ' ' .. original .. ' ' .. date,
              file = file_path,
              name = name,
              original = original,
              info_path = info_path,
              date = date,
              size_str = fmt_size(stat and stat.size),
              is_dir = ftype == 'directory',
            })
          end
        end

        if #items == 0 then
          vim.notify('Trash is empty', vim.log.levels.INFO)
          return
        end

        table.sort(items, function(a, b)
          return a.date > b.date
        end)
        local seen, deduped = {}, {}
        for _, item in ipairs(items) do
          if not seen[item.original] then
            seen[item.original] = true
            deduped[#deduped + 1] = item
          end
        end
        items = deduped
        for i, item in ipairs(items) do
          item.idx = i
        end

        Snacks.picker.pick {
          title = '  Trash',
          preview = false,
          layout = { preset = 'telescope' },
          finder = function()
            return items
          end,
          format = function(item, _)
            local t = item.is_dir and { 'd', 'Directory' } or { '-', 'Comment' }
            return {
              { t[1] .. '  ', t[2] },
              { item.size_str .. '  ', 'Number' },
              { item.date .. '  ', 'Comment' },
              { item.original, item.is_dir and 'Directory' or 'SnacksPickerFile' },
            }
          end,
          confirm = function(picker, _)
            local selected = picker:selected { fallback = true }
            local label = #selected == 1 and ('"' .. selected[1].name .. '"') or (#selected .. ' files')
            if vim.fn.confirm('Restore ' .. label .. '?', '&Yes\n&No', 2) ~= 1 then
              return
            end
            picker:close()
            local ok, fail = 0, 0
            for _, sel in ipairs(selected) do
              local dest_dir = vim.fn.fnamemodify(sel.original, ':h')
              if vim.fn.isdirectory(dest_dir) == 0 then
                vim.fn.mkdir(dest_dir, 'p')
              end
              local result = vim.system({ 'mv', sel.file, sel.original }):wait()
              if result.code ~= 0 then
                fail = fail + 1
                vim.notify('Restore failed: ' .. sel.name .. ': ' .. (result.stderr or ''), vim.log.levels.ERROR)
              else
                vim.fn.delete(sel.info_path)
                ok = ok + 1
              end
            end
            if ok > 0 then
              vim.notify('Restored ' .. ok .. ' file(s)' .. (fail > 0 and (', ' .. fail .. ' failed') or ''))
            end
          end,
          win = {
            input = {
              keys = { ['<C-d>'] = { 'purge', mode = { 'n', 'i' } } },
            },
            list = {
              keys = { ['d'] = 'purge' },
            },
          },
          actions = {
            purge = function(picker, _)
              local selected = picker:selected { fallback = true }
              local label = #selected == 1 and ('"' .. selected[1].name .. '"') or (#selected .. ' files')
              if vim.fn.confirm('Permanently delete ' .. label .. '?', '&Yes\n&No', 2) ~= 1 then
                return
              end
              picker:close()
              for _, sel in ipairs(selected) do
                vim.fn.delete(sel.file, 'rf')
                vim.fn.delete(sel.info_path)
              end
              vim.notify('Permanently deleted ' .. #selected .. ' file(s)')
            end,
          },
        }
      end

      vim.api.nvim_create_user_command('Trashed', open_trash, { desc = 'Browse and restore trashed files' })
      require('snacks').setup(opts)
    end,
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
          Snacks.picker.commands()
        end,
        desc = 'Commands',
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
        '<leader>ft',
        '<cmd>Trashed<cr>',
        desc = 'Trash',
      },
    },
  },
}
