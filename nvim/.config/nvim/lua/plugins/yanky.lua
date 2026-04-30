return {
  'gbprod/yanky.nvim',
  opts = {},
  keys = {
    {
      'tp',
      function()
        local buf = vim.api.nvim_get_current_buf()
        local win = vim.api.nvim_get_current_win()
        local cursor = vim.api.nvim_win_get_cursor(win)
        local ns = vim.api.nvim_create_namespace 'yanky_preview'

        local function clear_preview()
          pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
        end

        local function show_preview(item)
          clear_preview()
          if not item then return end
          local lines = vim.split(item.text, '\n')
          local is_linewise = item.regtype == 'V'

          if is_linewise then
            local virt_lines = vim.tbl_map(function(l)
              return { { l, 'Comment' } }
            end, lines)
            pcall(vim.api.nvim_buf_set_extmark, buf, ns, cursor[1] - 1, 0, {
              virt_lines = virt_lines,
            })
          else
            pcall(vim.api.nvim_buf_set_extmark, buf, ns, cursor[1] - 1, cursor[2] + 1, {
              virt_text = { { lines[1], 'Comment' } },
              virt_text_pos = 'inline',
            })
            if #lines > 1 then
              local rest = vim.tbl_map(function(l)
                return { { l, 'Comment' } }
              end, vim.list_slice(lines, 2))
              pcall(vim.api.nvim_buf_set_extmark, buf, ns, cursor[1] - 1, 0, {
                virt_lines = rest,
              })
            end
          end
        end

        vim.cmd 'normal! zz'

        local history = require('yanky.history').all()
        local items = {}
        local seen = {}
        for _, entry in ipairs(history) do
          local text = type(entry.regcontents) == 'table'
            and table.concat(entry.regcontents, '\n')
            or entry.regcontents
          if not seen[text] then
            seen[text] = true
            items[#items + 1] = {
              text = text,
              regcontents = entry.regcontents,
              regtype = entry.regtype,
            }
          end
        end

        Snacks.picker.pick {
          title = 'Yank History',
          items = items,
          layout = { preset = 'ivy', preview = false },
          format = function(item)
            local line = item.text:gsub('\n', '↵ ')
            return { { line, 'Normal' } }
          end,
          on_change = function(_, item)
            show_preview(item)
          end,
          confirm = function(picker, item)
            clear_preview()
            picker:close()
            vim.schedule(function()
              if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
                vim.api.nvim_win_set_cursor(win, cursor)
              end
              local lines = type(item.regcontents) == 'table'
                and item.regcontents
                or vim.split(item.text, '\n')
              local put_type = (item.regtype == 'V') and 'l' or 'c'
              vim.api.nvim_put(lines, put_type, true, true)
            end)
          end,
          win = {
            input = {
              on_close = clear_preview,
            },
          },
        }
      end,
      desc = 'Yank history picker',
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
