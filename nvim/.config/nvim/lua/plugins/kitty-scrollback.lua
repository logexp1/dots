-- Same rules as scripts/bin/tmux-copy-dedent, applied to yanks from the
-- scrollback.
--
-- Unwrap: TUIs like Claude Code break long paragraphs at the window width
-- themselves, so the terminal sees real newlines. A word wrapper only moves
-- to the next line when the next word does not fit, so if
--   width(previous line) + 1 + width(first word of this line) >= columns
-- the two lines were one. Blank lines, lines starting with a list, table or
-- prompt marker, lines after a rule, and lines whose first word could not fit
-- on any line are left alone. Widths are display widths (Hangul counts 2).
--
-- Dedent: strip trailing whitespace, drop the first line's own leading spaces
-- (a charwise v selection often starts mid-line), and remove the common leading
-- spaces of the remaining non-empty lines, keeping relative indentation. Only
-- spaces count; tabs stay.

local columns -- width of the kitty window the scrollback came from

local function is_block(body)
  return body:match '^[-*+>#|]'
    or body:match '^%d+[.)]%s' or body:match '^%d+[.)]$'
    or vim.iter({ '•', '●', '⎿', '│', '├', '└', '┌', '┐', '┘', '┬', '┴', '┼', '─', '╭', '╮', '╯', '╰', '❯', '※' })
      :any(function(m) return vim.startswith(body, m) end)
end

local function is_rule(s)
  return s ~= '' and vim.fn.match(s, [[^[─━═_ -]\+$]]) == 0
end

-- lines: yanked text; full: the buffer lines they came from (same count)
local function unwrap(lines, full, width)
  local dw = vim.fn.strdisplaywidth
  local out, prev_w = {}, 0
  for i, line in ipairs(lines) do
    line = line:gsub('%s+$', '')
    local body = line:gsub('^ +', '')
    local prev = out[#out] and vim.trim(out[#out]) or ''
    local word = dw(body:match '^[^ ]*')
    if
      prev ~= ''
      and body ~= ''
      and not is_block(body)
      and not is_rule(prev)
      and prev_w + 1 + word >= width
      and #line - #body + word <= width
    then
      out[#out] = out[#out] .. ' ' .. body
    else
      out[#out + 1] = line
    end
    -- judge by the last screen row of the original line
    prev_w = dw((full[i] or line):gsub('%s+$', ''))
    while prev_w > width do
      prev_w = prev_w - width
    end
  end
  return out
end

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

local function clean(ev)
  local lines = ev.regcontents
  if ev.regtype:sub(1, 1) ~= '\22' then -- not blockwise
    local first = vim.fn.line "'["
    local full = vim.api.nvim_buf_get_lines(0, first - 1, first - 1 + #lines, false)
    lines = unwrap(lines, full, columns or vim.o.columns)
  end
  return dedent(lines)
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
                vim.fn.setreg(reg, clean(ev), ev.regtype)
              end,
            })
          end,
          after_ready = function(kitty_data)
            columns = kitty_data.columns
          end,
        },
      },
    }
  end,
}

-- vim: ts=2 sts=2 sw=2 et
