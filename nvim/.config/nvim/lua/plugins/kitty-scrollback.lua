return {
  'mikesmithgh/kitty-scrollback.nvim',
  lazy = true,
  cmd = { 'KittyScrollbackGenerateKittens', 'KittyScrollbackCheckHealth' },
  event = { 'User KittyScrollbackLaunch' },
  config = function()
    require('kitty-scrollback').setup {
      {
        paste_window = {
          yank_register_enabled = false,
        },
        callbacks = {
          after_setup = function()
            vim.opt.clipboard = 'unnamedplus'
          end,
        },
      },
    }
  end,
}

-- vim: ts=2 sts=2 sw=2 et
