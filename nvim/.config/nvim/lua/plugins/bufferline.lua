return {
  {
    'akinsho/bufferline.nvim',
    version = '*',
    event = 'VeryLazy',
    keys = {
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
      { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
      { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
      { '[B', '<cmd>BufferLineMovePrev<cr>', desc = 'Move Buffer Prev' },
      { ']B', '<cmd>BufferLineMoveNext<cr>', desc = 'Move Buffer Next' },
      { '<leader>bp', '<cmd>BufferLineTogglePin<cr>', desc = 'Toggle Pin' },
      { '<leader>bP', '<cmd>BufferLineGroupClose ungrouped<cr>', desc = 'Delete Non-Pinned Buffers' },
      { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Delete Buffers to the Right' },
      { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Delete Buffers to the Left' },
      { '<leader>bj', '<cmd>BufferLinePick<cr>', desc = 'Pick Buffer' },
    },
    opts = {
      options = {
        close_command = function(n)
          Snacks.bufdelete(n)
        end,
        right_mouse_command = function(n)
          Snacks.bufdelete(n)
        end,
        diagnostics = 'nvim_lsp',
        always_show_bufferline = false,
        diagnostics_indicator = function(_, _, diag)
          local ret = (diag.error and '󰅚 ' .. diag.error .. ' ' or '') .. (diag.warning and '󰀪 ' .. diag.warning or '')
          return vim.trim(ret)
        end,
      },
    },
    config = function(_, opts)
      require('bufferline').setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete' }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
