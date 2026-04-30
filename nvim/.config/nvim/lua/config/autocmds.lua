local function augroup(name)
  return vim.api.nvim_create_augroup('config_' .. name, { clear = true })
end

-- Reload file if changed externally
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup 'checktime',
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'checktime'
    end
  end,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup 'highlight_yank',
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- Equalize splits across all tabs when terminal is resized
vim.api.nvim_create_autocmd('VimResized', {
  group = augroup 'resize_splits',
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup 'last_loc',
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
      return
    end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close utility windows with q
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'close_with_q',
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'dap-float',
    'dbout',
    'gitsigns-blame',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'spectre_panel',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, { buffer = event.buf, silent = true, desc = 'Quit buffer' })
    end)
  end,
})

-- Make man pages unlisted
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'man_unlisted',
  pattern = 'man',
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- Enable wrap and spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'wrap_spell',
  pattern = { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Show all characters in JSON (no concealing)
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'json_conceal',
  pattern = { 'json', 'jsonc', 'json5' },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Auto-create intermediate directories on save
vim.api.nvim_create_autocmd('BufWritePre', {
  group = augroup 'auto_create_dir',
  callback = function(event)
    if event.match:match '^%w%w+:[\\/][\\/]' then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

-- Auto change directory to current buffer's directory
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup 'auto_lcd',
  callback = function()
    if vim.bo.filetype == 'oil' then
      return
    end
    local filepath = vim.fn.expand '%:p:h'
    if filepath ~= '' and vim.fn.isdirectory(filepath) == 1 then
      vim.cmd('lcd ' .. filepath)
    end
  end,
})

-- LSP: keymaps, inlay hints, and document highlighting on attach
vim.api.nvim_create_autocmd('LspAttach', {
  group = augroup 'lsp_attach',
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Pyright: notify venv path after attach
    if client and client.name == 'pyright' then
      local root = client.config.root_dir or vim.fn.getcwd()
      for _, venv in ipairs { '/.venv/bin/python', '/venv/bin/python' } do
        local python = root .. venv
        if vim.fn.executable(python) == 1 then
          client.config.settings = vim.tbl_deep_extend('force', client.config.settings or {}, {
            python = { pythonPath = python },
          })
          client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
          break
        end
      end
    end

    local map = function(keys, func, desc, mode)
      vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grr', function() Snacks.picker.lsp_references() end, 'Goto References')
    map('gri', function() Snacks.picker.lsp_implementations() end, 'Goto Implementation')
    map('grd', function() Snacks.picker.lsp_definitions() end, 'Goto Definition')
    map('grD', vim.lsp.buf.declaration, 'Goto Declaration')
    map('gO',  function() Snacks.picker.lsp_symbols() end, 'Document Symbols')
    map('gW',  function() Snacks.picker.lsp_workspace_symbols() end, 'Workspace Symbols')
    map('grt', function() Snacks.picker.lsp_type_definitions() end, 'Goto Type Definition')

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, 'Toggle Inlay Hints')
    end

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local hi = vim.api.nvim_create_augroup('lsp_highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf, group = hi, callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf, group = hi, callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.api.nvim_create_autocmd('LspDetach', {
  group = augroup 'lsp_detach',
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds { group = 'lsp_highlight', buffer = event.buf }
  end,
})

-- vim: ts=2 sts=2 sw=2 et
