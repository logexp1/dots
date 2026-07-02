local map = vim.keymap.set

-- require("which-key").add({
-- 	{ "t", group = "+t-prefix" },
-- })

-- Swap ; and : so ; enters command mode and : repeats f/t motion
map({ 'n', 'v' }, ';', ':', { desc = 'Command mode' })
map({ 'n', 'v' }, ':', ';', { desc = 'Repeat f/t motion' })

-- Swap q and Q for macro recording
map('n', 'q', '<Nop>', { desc = 'Disabled (use Q for macros)' })
map('n', 'Q', 'q', { desc = 'Record macro' })

map('n', 't-', '<cmd>split<cr>', { desc = 'Split window horizontally' })
map('n', "t'", '<cmd>vsplit<cr>', { desc = 'Split window vertically' })

map('n', 'th', '<C-w>h', { desc = 'Go to left window' })
map('n', 'tj', '<C-w>j', { desc = 'Go to lower window' })
map('n', 'tk', '<C-w>k', { desc = 'Go to upper window' })
map('n', 'tl', '<C-w>l', { desc = 'Go to right window' })

map('n', 'tq', ':close<CR>', { desc = 'close current window', noremap = true, silent = true })
map('n', 'td', ':bdelete!<CR>', { desc = 'delete current window', noremap = true, silent = true })
map('n', 'tm', '<C-w>o', { desc = 'Close other windows' })

map('n', 't=', '<C-w>=', { desc = 'equalize window sizes' })

map('n', 't_', '<cmd>resize -5<cr>', { desc = 'Decrease window height' })
map('n', 't+', '<cmd>resize +5<cr>', { desc = 'Increase window height' })

map('n', 'tc', 'gcc', { desc = 'Toggle comment line', remap = true })
map('v', 'tc', 'gc', { desc = 'Togle comment selection', remap = true })

map('i', '<Esc>', '<Esc>`^', { desc = 'Exit insert mode without moving cursor' })
map('n', 'a', 'A', { desc = 'Append at end of line' })

map('n', 'U', '<C-r>', { desc = 'Redo', noremap = true })

map({ 'n', 'i', 'v' }, '<C-b>', function()
  local alt = vim.fn.bufnr '#'
  if alt ~= -1 and vim.api.nvim_buf_is_valid(alt) then
    vim.cmd 'buffer #'
  end
end, { desc = 'Switch to last buffer' })

map('n', '<C-j>', '<C-d>zz', { desc = 'Scroll down half page' })
map('n', '<C-k>', '<C-u>zz', { desc = 'Scroll up half page' })
-- Insert mode에서도 스크롤 가능 (C-o로 normal mode 명령어 실행)
map('i', '<C-j>', '<C-o><C-d>zz', { desc = 'Scroll down half page' })
map('i', '<C-k>', '<C-o><C-u>zz', { desc = 'Scroll up half page' })
map('v', '<C-j>', '<C-d>zz', { desc = 'Scroll down half page' })
map('v', '<C-k>', '<C-u>zz', { desc = 'Scroll up half page' })

map('n', 'j', 'gjzz', { desc = 'move cursor down (visual line)' })
map('n', 'k', 'gkzz', { desc = 'move cursor up (visual line)' })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

map('n', '<leader>xD', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })

map('n', ',e', function()
  vim.cmd('edit ' .. vim.fn.stdpath 'config' .. '/init.lua')
end, { desc = 'Edit init.lua' })

-- Exit terminal mode
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Move lines up/down
map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move line down' })
map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move line up' })
map('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move line down' })
map('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move line up' })
map('v', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move selection down' })
map('v', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move selection up' })

-- n/N always forward/backward regardless of search direction
map({ 'n' }, 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result' })
map({ 'x', 'o' }, 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
map({ 'n' }, 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result' })
map({ 'x', 'o' }, 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })

-- Undo breakpoints — each sentence is its own undo step
map('i', ',', ',<c-g>u')
map('i', '.', '.<c-g>u')
map('i', ';', ';<c-g>u')

-- Files
map('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New File' })

-- Save
map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- better indenting
map('x', '<', '<gv')
map('x', '>', '>gv')
-- quit
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit All' })

-- markdown buffer에서만 원하는 매핑 수동 등록
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', '<CR>', '<Plug>(iwe-lsp-go-to-definition)', opts)
    vim.keymap.set('v', '<CR>', '<Plug>(iwe-lsp-link)', opts)
    vim.keymap.set('i', '/d', '<Plug>(iwe-insert-date)', opts)
    vim.keymap.set('i', '/w', '<Plug>(iwe-insert-week)', opts)
    vim.keymap.set('n', '<C-n>', '<Plug>(iwe-link-next)', opts)
    vim.keymap.set('n', '<C-p>', '<Plug>(iwe-link-prev)', opts)

    -- iwe picker keybindings. iwe.nvim only registers these inside the
    -- enable_markdown_mappings gate (which we keep off to preserve our own
    -- <CR>/- mappings), so bind the always-available <Plug> targets here.
    vim.keymap.set('n', 'gs', '<Plug>(iwe-picker-paths)', opts) -- node-find (org-roam-node-find equiv)
    vim.keymap.set('n', 'gf', '<Plug>(iwe-picker-find-files)', opts) -- find by filename
    vim.keymap.set('n', 'ga', '<Plug>(iwe-picker-roots)', opts) -- namespace roots
    vim.keymap.set('n', 'g/', '<Plug>(iwe-picker-grep)', opts) -- live grep
    vim.keymap.set('n', 'gb', '<Plug>(iwe-picker-blockreferences)', opts) -- block references
    vim.keymap.set('n', 'gR', '<Plug>(iwe-picker-backlinks)', opts) -- backlinks
    vim.keymap.set('n', 'go', '<Plug>(iwe-picker-headers)', opts) -- document headers
    -- "-" 는 의도적으로 제외 → oil 유지
  end,
})
