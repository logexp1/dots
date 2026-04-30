-- Equalize splits when terminal is resized
vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    vim.cmd 'wincmd ='
  end,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Auto change directory to current buffer's directory
vim.api.nvim_create_autocmd('BufEnter', {
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

-- Markdown: header-based folding + Tab to toggle
function _G.markdown_foldexpr()
  local line = vim.fn.getline(vim.v.lnum)
  local level = line:match '^(#+)%s'
  if level then return '>' .. #level end
  return '='
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(ev)
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.markdown_foldexpr()'
    vim.schedule(function()
      vim.keymap.set('n', '-', function() require('oil').open() end, { buffer = ev.buf, desc = 'Open parent directory' })
    end)
    vim.keymap.set('n', '<Tab>', function()
      if vim.api.nvim_get_current_line():match '^#' then
        pcall(vim.cmd, 'normal! za')
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
      end
    end, { buffer = ev.buf, desc = 'Toggle fold on header' })
  end,
})

-- vim: ts=2 sts=2 sw=2 et
