return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    main = 'nvim-treesitter',
    opts = {
      ensure_installed = {
        'lua', 'python', 'bash', 'markdown', 'markdown_inline',
        'json', 'yaml', 'toml', 'vim', 'vimdoc', 'regex',
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
