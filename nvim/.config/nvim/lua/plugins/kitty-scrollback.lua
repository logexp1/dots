-- Same rule as scripts/bin/tmux-copy-dedent: strip trailing whitespace, drop
-- the first line's own leading spaces (a charwise v selection often starts
-- mid-line), and remove the common leading spaces of the remaining non-empty
-- lines, keeping relative indentation. Only spaces count; tabs stay.
local function dedent(lines)
  local out, min = {}, nil
  for i, line in ipairs(lines) do
    line = line:gsub('%s+$', '')
    out[i] = line
    if i > 1 and line ~= '' then
      local n = #line:match '^ *'
      if not min or n < min then
        min = n
      end
    end
  end
  if out[1] then
    out[1] = out[1]:gsub('^ +', '')
  end
  for i = 2, #out do
    out[i] = out[i]:sub((min or 0) + 1)
  end
  return out
end

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
            -- The plugin quits on the next tick after a yank to the clipboard,
            -- so rewriting the register here lands before it exits.
            vim.api.nvim_create_autocmd('TextYankPost', {
              group = vim.api.nvim_create_augroup('KsbDedentYank', { clear = true }),
              callback = function()
                local ev = vim.v.event
                if ev.operator ~= 'y' or (ev.regname ~= '+' and ev.regname ~= '') then
                  return
                end
                local reg = ev.regname == '' and '+' or ev.regname
                vim.fn.setreg(reg, dedent(ev.regcontents), ev.regtype)
              end,
            })
          end,
        },
      },
    }
  end,
}

-- vim: ts=2 sts=2 sw=2 et
