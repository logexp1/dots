return {
  'keaising/im-select.nvim',
  opts = {
    default_im_select = 'keyboard-us',
    default_command = 'fcitx5-remote',
    set_default_events = { 'InsertLeave', 'CmdlineEnter', 'CmdlineLeave' },
    set_previous_events = { 'InsertEnter' },
    async_switch_im = true,
  },
}

-- vim: ts=2 sts=2 sw=2 et
