return {
  'okuuva/auto-save.nvim',
  enabled = true,
  version = '^1.0.0',
  cmd = 'ASToggle',
  event = { 'InsertLeave', 'TextChanged' },
  opts = {
    {
      enabled = true,
      trigger_events = {
        immediate_save = { 'BufLeave', 'FocusLost', 'QuitPre', 'VimSuspend', 'WinClosed' },
        defer_save = { 'InsertLeave', 'TextChanged' },
        cancel_deferred_save = { 'InsertEnter' },
      },
      condition = function(buf)
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname:match '%(proposed%)' or bufname:match '%(NEW FILE %- proposed%)' or bufname:match '%(New%)' then
          return false
        end
        if vim.b[buf].claudecode_diff_tab_name or vim.b[buf].claudecode_diff_new_win or vim.b[buf].claudecode_diff_target_win then
          return false
        end
        if vim.fn.getbufvar(buf, '&buftype') == 'acwrite' then
          return false
        end
        return true
      end,
      write_all_buffers = false,
      noautocmd = false,
      lockmarks = false,
      debounce_delay = 2000,
      debug = false,
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
