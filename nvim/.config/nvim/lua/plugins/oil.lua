return {
  'barrettruth/canola.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    { '-', '<CMD>Oil<CR>', desc = 'Open parent directory' },
  },
  config = function()
    -- ── Mark system ─────────────────────────────────────────────────────
    local marks = {}
    local ns = vim.api.nvim_create_namespace 'oil_marks'

    local function get_entry_path()
      local oil = require 'oil'
      local entry = oil.get_cursor_entry()
      local dir = oil.get_current_dir()
      if not entry or not dir then
        return nil
      end
      return dir .. entry.name
    end

    local function refresh_marks(buf)
      local ok, oil = pcall(require, 'oil')
      if not ok then
        return
      end
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      local dir = oil.get_current_dir(buf)
      if not dir then
        return
      end
      for i = 1, vim.api.nvim_buf_line_count(buf) do
        local entry = oil.get_entry_on_line(buf, i)
        if entry and marks[dir .. entry.name] then
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
            virt_text = { { '●', 'DiagnosticWarn' } },
            virt_text_pos = 'right_align',
          })
        end
      end
    end

    local function toggle_mark()
      local path = get_entry_path()
      if not path then
        return
      end
      if marks[path] then
        marks[path] = nil
      else
        marks[path] = true
      end
      local buf = vim.api.nvim_get_current_buf()
      refresh_marks(buf)
      local row = vim.api.nvim_win_get_cursor(0)[1]
      if row < vim.api.nvim_buf_line_count(buf) then
        vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
      end
    end

    local function unmark()
      local path = get_entry_path()
      if not path then
        return
      end
      marks[path] = nil
      local buf = vim.api.nvim_get_current_buf()
      refresh_marks(buf)
      local row = vim.api.nvim_win_get_cursor(0)[1]
      if row < vim.api.nvim_buf_line_count(buf) then
        vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
      end
    end

    local function clear_marks()
      marks = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
        end
      end
      vim.notify 'Marks cleared'
    end

    local function paste_marks(move)
      local oil = require 'oil'
      local dest = oil.get_current_dir()
      if not dest then
        vim.notify('Not in an oil buffer', vim.log.levels.ERROR)
        return
      end
      local paths = vim.tbl_keys(marks)
      if #paths == 0 then
        vim.notify('No marked files', vim.log.levels.WARN)
        return
      end
      local errors = {}
      for _, src in ipairs(paths) do
        local cmd = move and { 'mv', src, dest } or { 'cp', '-r', src, dest }
        local result = vim.system(cmd):wait()
        if result.code ~= 0 then
          table.insert(errors, result.stderr)
        end
      end
      if #errors > 0 then
        vim.notify('Errors:\n' .. table.concat(errors, '\n'), vim.log.levels.ERROR)
      else
        vim.notify((move and 'Moved' or 'Copied') .. ' ' .. #paths .. ' file(s) to ' .. dest)
        if move then
          clear_marks()
        end
      end

      -- 모든 보이는 oil 윈도우 refresh (양쪽 pane 동기화)
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match '^oil://' then
          vim.api.nvim_win_call(win, function()
            vim.cmd 'edit'
          end)
        end
      end
    end

    -- ── File openers ────────────────────────────────────────────────────
    local function launch(filepath, cmd)
      vim.fn.jobstart(vim.list_extend(cmd, { filepath }), { detach = true })
    end

    local openers = {
      edit = function(p)
        vim.cmd('edit ' .. vim.fn.fnameescape(p))
      end,
      browse = function(p)
        launch(p, { 'firefox' })
      end,
      image = function(p)
        launch(p, { 'loupe' })
      end,
      video = function(p)
        launch(p, { 'mpv', '--save-position-on-quit' })
      end,
      audio = function(p)
        launch(p, { 'mpv', '--no-video', '--osd-level=3' })
      end,
      pdf = function(p)
        launch(p, { 'evince' })
      end,
      office = function(p)
        launch(p, { 'flatpak', 'run', 'org.libreoffice.LibreOffice' })
      end,
      torrent = function(p)
        launch(p, { 'transmission-remote', '--add' })
      end,
      gimp = function(p)
        launch(p, { 'gimp' })
      end,
    }

    local open_rules = {
      { mime = '^text/html', opener = 'browse' },
      { name = '%.xcf$', opener = 'gimp' },
      { mime = '^image/', opener = 'image' },
      { mime = '^video/', opener = 'video' },
      { mime = '^audio/', opener = 'audio' },
      { mime = 'application/ogg', opener = 'audio' },
      { mime = 'application/pdf', opener = 'pdf' },
      { mime = 'application/vnd%.openxmlformats', opener = 'office' },
      { mime = 'application/vnd%.oasis%.opendocument', opener = 'office' },
      { mime = 'application/vnd%.ms%-', opener = 'office' },
      { mime = 'application/msword', opener = 'office' },
      { name = '%.torrent$', opener = 'torrent' },
      { mime = 'application/x%-bittorrent', opener = 'torrent' },
      { mime = '^text/', opener = 'edit' },
      { mime = 'application/json', opener = 'edit' },
      { mime = 'application/xml', opener = 'edit' },
      { mime = 'inode/x%-empty', opener = 'edit' },
    }

    local function open_file(filepath, name)
      local mime = vim.fn.system({ 'file', '--mime-type', '-b', filepath }):gsub('%s+', '')
      for _, rule in ipairs(open_rules) do
        if (rule.mime and mime:match(rule.mime)) or (rule.name and name:match(rule.name)) then
          openers[rule.opener](filepath)
          return
        end
      end
      openers.edit(filepath)
    end

    local function smart_enter()
      local oil = require 'oil'
      local entry = oil.get_cursor_entry()
      if not entry then
        return
      end
      if entry.type == 'directory' then
        require('oil.actions').select.callback()
        return
      end
      local dir = oil.get_current_dir()
      if not dir then
        return
      end
      open_file(dir .. entry.name, entry.name)
    end

    local function chmod()
      local oil = require 'oil'
      local entry = oil.get_cursor_entry()
      local dir = oil.get_current_dir()
      if not entry or not dir then
        return
      end
      local filepath = dir .. entry.name
      vim.ui.input({ prompt = 'chmod ' .. entry.name .. ': ' }, function(mode)
        if not mode or mode == '' then
          return
        end
        local use_sudo = vim.fn.filewritable(filepath) == 0
        local cmd = use_sudo and { 'sudo', 'chmod', mode, filepath } or { 'chmod', mode, filepath }
        local result = vim.system(cmd):wait()
        if result.code ~= 0 then
          vim.notify(result.stderr, vim.log.levels.ERROR)
        else
          oil.open(dir)
        end
      end)
    end

    local function extract_archive()
      local oil = require 'oil'
      local entry = oil.get_cursor_entry()
      local dir = oil.get_current_dir()
      if not entry then
        return
      end
      vim.fn.jobstart({ 'aunpack', '-D', entry.name }, {
        cwd = dir,
        on_exit = function(_, code)
          if code == 0 then
            require('oil').open(dir)
          end
        end,
      })
    end

    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = 'oil://*',
      callback = function(ev)
        refresh_marks(ev.buf)
      end,
    })

    -- ── Auto-refresh on focus regain ────────────────────────────────────
    -- Pick up files added/removed externally when nvim regains focus.
    -- Skip if buffer is dirty so in-progress rename/create edits aren't lost.
    vim.api.nvim_create_autocmd('FocusGained', {
      pattern = 'oil://*',
      callback = function(ev)
        if vim.bo[ev.buf].modified then return end
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) and not vim.bo[ev.buf].modified then
            vim.api.nvim_buf_call(ev.buf, function() vim.cmd 'edit' end)
          end
        end)
      end,
    })

    -- ── Cursor position memory ───────────────────────────────────────────
    local cursor_positions = {}

    vim.api.nvim_create_autocmd('BufLeave', {
      pattern = 'oil://*',
      callback = function(ev)
        cursor_positions[vim.api.nvim_buf_get_name(ev.buf)] = vim.api.nvim_win_get_cursor(0)
      end,
    })

    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = 'oil://*',
      callback = function(ev)
        vim.schedule(function()
          local pos = cursor_positions[vim.api.nvim_buf_get_name(ev.buf)]
          if pos and pos[1] <= vim.api.nvim_buf_line_count(ev.buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, pos)
          end
        end)
      end,
    })

    local function s(sort)
      return function()
        require('oil').set_sort(sort)
      end
    end

    local sort_hydra = require 'hydra' {
      name = 'Sort',
      mode = 'n',
      hint = [[
 n: Name (A→Z)      N: Name (Z→A)
 s: Size (↑)        S: Size (↓)
 m: Modified (↑)    M: Modified (↓)
 c: Created (↑)     C: Created (↓)
 a: Accessed (↑)    A: Accessed (↓)
 <Esc>: cancel
]],
      config = { hint = { type = 'window', position = 'bottom' } },
      heads = {
        { 'n', s { { 'type', 'asc' }, { 'name', 'asc' } }, { desc = 'Name (A→Z)', exit = true } },
        { 'N', s { { 'type', 'asc' }, { 'name', 'desc' } }, { desc = 'Name (Z→A)', exit = true } },
        { 's', s { { 'type', 'asc' }, { 'size', 'asc' } }, { desc = 'Size (small→large)', exit = true } },
        { 'S', s { { 'type', 'asc' }, { 'size', 'desc' } }, { desc = 'Size (large→small)', exit = true } },
        { 'm', s { { 'type', 'asc' }, { 'mtime', 'desc' } }, { desc = 'Modified (newest)', exit = true } },
        { 'M', s { { 'type', 'asc' }, { 'mtime', 'asc' } }, { desc = 'Modified (oldest)', exit = true } },
        { 'c', s { { 'type', 'asc' }, { 'birthtime', 'desc' } }, { desc = 'Created (newest)', exit = true } },
        { 'C', s { { 'type', 'asc' }, { 'birthtime', 'asc' } }, { desc = 'Created (oldest)', exit = true } },
        { 'a', s { { 'type', 'asc' }, { 'atime', 'desc' } }, { desc = 'Accessed (newest)', exit = true } },
        { 'A', s { { 'type', 'asc' }, { 'atime', 'asc' } }, { desc = 'Accessed (oldest)', exit = true } },
        { '<Esc>', nil, { exit = true, desc = false } },
        { 'q', nil, { exit = true, desc = false } },
      },
    }

    -- ── Bookmarks ───────────────────────────────────────────────────────
    local bookmarks = {
      ['/'] = '/',
      b = '/bin/',
      t = '/tmp/',
      s = vim.fn.expand '~/src',
      h = vim.fn.expand '~/',
      d = vim.fn.expand '~/Downloads',
      e = vim.fn.expand '~/.config/nvim/',
      p = vim.fn.expand '~/Pictures/Screenshots/',
    }
    local bookmark_maps = {}
    for key, path in pairs(bookmarks) do
      bookmark_maps["'" .. key] = {
        desc = 'Jump to ' .. path,
        callback = function()
          require('oil').open(path)
        end,
      }
    end

    -- ── Winbar ──────────────────────────────────────────────────────────
    function _G.get_oil_winbar()
      local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
      local dir = require('oil').get_current_dir(bufnr)
      if dir then
        return vim.fn.fnamemodify(dir, ':~')
      else
        return vim.api.nvim_buf_get_name(0)
      end
    end

    require('oil').setup {
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = false,
      cleanup_delay_ms = 2000,
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name, _)
          return name == '..'
        end,
      },
      keymaps = vim.tbl_extend('force', {
        ['q'] = 'actions.close',
        ['<CR>'] = { desc = 'Smart enter', callback = smart_enter },
        ['<S-h>'] = { 'actions.parent', mode = 'n' },
        ['<S-l>'] = 'actions.select',
        ['O'] = {
          desc = 'Sort',
          callback = function()
            sort_hydra:activate()
          end,
        },
        ['s'] = { 'actions.change_sort', mode = 'n' },
        ['?'] = { 'actions.show_help', mode = 'n' },
        ['x'] = { desc = 'Extract archive', callback = extract_archive },
        ['cm'] = { desc = 'chmod', callback = chmod },
        ['cd'] = {
          desc = 'Create directory',
          callback = function()
            local dir = require('oil').get_current_dir()
            if not dir then
              return
            end
            vim.ui.input({ prompt = 'New directory: ' }, function(name)
              if not name or name == '' then
                return
              end
              vim.system({ 'mkdir', '-p', dir .. name }):wait()
              require('oil').open(dir)
            end)
          end,
        },
        ['<Tab>'] = { desc = 'Toggle mark', callback = toggle_mark },
        ['m'] = { desc = 'Toggle mark', callback = toggle_mark },
        ['<S-Tab>'] = { desc = 'Unmark under cursor', callback = unmark },
        ['M'] = { desc = 'Clear all marks', callback = clear_marks },
        ['p'] = {
          desc = 'Paste (copy) marked files here',
          callback = function()
            paste_marks(false)
          end,
        },
        ['P'] = {
          desc = 'Paste (move) marked files here',
          callback = function()
            paste_marks(true)
          end,
        },
        ['gs'] = {
          desc = 'Open vertical split',
          callback = function()
            local dir = require('oil').get_current_dir()
            vim.cmd 'vsplit'
            require('oil').open(dir)
          end,
        },
      }, bookmark_maps),
      columns = { 'icon', 'permissions', 'size', 'mtime' },
      buf_options = { buflisted = false, bufhidden = 'hide' },
      win_options = {
        winbar = '%!v:lua.get_oil_winbar()',
        wrap = false,
        signcolumn = 'no',
        cursorcolumn = false,
        foldcolumn = '0',
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = 'nvic',
      },
    }
  end,
}

-- vim: ts=2 sts=2 sw=2 et
