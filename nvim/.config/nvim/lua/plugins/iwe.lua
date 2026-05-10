return {
  'iwe-org/iwe.nvim',
  ft = 'markdown',
  dependencies = {
    -- 'nvim-telescope/telescope.nvim',
    'folke/snacks.nvim',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('iwe').setup {
      lsp = {
        cmd = { 'iwes' },
        auto_format_on_save = true,
        enable_inlay_hints = true,
        debounce_text_changes = 500,
      },
      mappings = {
        enable_markdown_mappings = false,
        enable_picker_keybindings = true, -- gf, gs, ga, g/, gb, gR, go
        enable_lsp_keybindings = true, -- <leader>h, <leader>l (refactor)
        enable_preview_keybindings = true, -- <leader>ps, pe, ph, pw
      },
      picker = {
        backend = 'snacks',
        fallback_notify = true,
      },
      preview = {
        output_dir = '~/tmp/iwe-preview',
        auto_open = true,
      },
    }
  end,
}
