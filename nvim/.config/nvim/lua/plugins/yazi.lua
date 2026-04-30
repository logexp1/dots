return {
  'mikavilpas/yazi.nvim',
  version = '*',
  event = 'VeryLazy',
  dependencies = {
    { 'nvim-lua/plenary.nvim', lazy = true },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
  keys = {
    { '<leader>-', '<cmd>Yazi cwd<cr>',    desc = 'Open yazi in cwd' },
    { '<C-Up>',    '<cmd>Yazi toggle<cr>', desc = 'Resume last yazi session' },
  },
  config = function(_, opts)
    require('yazi').setup(opts)
    -- Route directory opens: neogit → oil, everything else → yazi
    vim.api.nvim_create_autocmd('BufEnter', {
      callback = function(ev)
        local name = vim.api.nvim_buf_get_name(ev.buf)
        if vim.fn.isdirectory(name) ~= 1 then return end
        local prev_ft = vim.bo[vim.fn.bufnr '#'].filetype
        vim.schedule(function()
          -- Leave the directory buffer before doing anything so that yazi's
          -- 'q' returns to a real buffer instead of re-triggering this autocmd.
          local alt = vim.fn.bufnr '#'
          if alt ~= ev.buf and vim.api.nvim_buf_is_valid(alt) then
            vim.api.nvim_set_current_buf(alt)
          else
            vim.cmd 'enew'
          end
          if vim.api.nvim_buf_is_valid(ev.buf) then
            vim.api.nvim_buf_delete(ev.buf, { force = true })
          end

          if prev_ft:match '^Neogit' then
            require('oil').open(name)
          else
            require('yazi').yazi(nil, name)
          end
        end)
      end,
    })
  end,
  opts = {
    open_for_directories = false, -- handled by custom BufEnter above
    clipboard_register = '+',
    yazi_floating_window_border = 'rounded',
    integrations = {
      grep_in_directory = 'snacks.picker',
      grep_in_selected_files = 'snacks.picker',
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
