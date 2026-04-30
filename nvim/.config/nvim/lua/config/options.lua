vim.o.termguicolors = true
vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false

vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 1000
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.splitkeep = 'screen'
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10

vim.o.wrap = true
vim.o.linebreak = true
vim.o.showbreak = '↪ '

vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false

vim.opt.breakindentopt = 'shift:2,min:40,sbr'

vim.o.foldlevelstart = 99

vim.o.shiftround = true
vim.o.smartindent = true
vim.o.virtualedit = 'block'
vim.o.pumheight = 10
vim.o.sidescrolloff = 8
vim.opt.formatoptions = 'jcroqlnt'

vim.o.grepprg = 'rg --vimgrep --smart-case'
vim.o.grepformat = '%f:%l:%c:%m'

-- vim: ts=2 sts=2 sw=2 et
