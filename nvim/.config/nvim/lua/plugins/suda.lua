return {
  'lambdalisue/vim-suda',
  lazy = true,
  cmd = { 'SudaRead', 'SudaWrite' },
  keys = {
    {
      '<leader>fu',
      function()
        local file = vim.fn.expand '%:p'
        if file == '' then return end
        if file:match '^/usr/share/nvim' then return end
        if vim.fn.filewritable(file) == 1 then
          vim.notify('File is already writable', vim.log.levels.INFO)
          return
        end
        vim.cmd('SudaRead ' .. vim.fn.fnameescape(file))
      end,
      desc = 'Sudo edit current file',
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
