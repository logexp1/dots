return {
  'axieax/urlview.nvim',
  cmd = 'UrlView',
  keys = {
    { 'tf', '<cmd>UrlView buffer action=system<cr>',    desc = 'Open URL in browser' },
    { 'ty', '<cmd>UrlView buffer action=clipboard<cr>', desc = 'Copy URL to clipboard' },
  },
  opts = {
    default_picker = 'telescope',
  },
}

-- vim: ts=2 sts=2 sw=2 et
