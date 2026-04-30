return {
  {
    'nvim-mini/mini.pairs',
    event = 'VeryLazy',
    opts = {
      -- Enable in insert and command mode (useful for regex in :s/foo/(bar)/)
      modes = { insert = true, command = true, terminal = false },
    },
  },

  {
    'folke/ts-comments.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  {
    'nvim-mini/mini.ai',
    event = 'VeryLazy',
    opts = function()
      local ai = require 'mini.ai'
      -- Wrap treesitter specs to fail silently when parser is not installed
      local function ts(spec)
        return function(...)
          local ok, result = pcall(spec, ...)
          if ok then return result end
        end
      end
      return {
        -- Search up to 500 lines for text object boundaries (default 50 is too small)
        n_lines = 500,
        custom_textobjects = {
          -- Code block: vio=inside if/loop/block, vao=around it (treesitter)
          o = ts(ai.gen_spec.treesitter {
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }),
          -- Function: vaf=whole function, vif=body only (treesitter)
          f = ts(ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' }),
          -- Class: vac=whole class, vic=body only (treesitter)
          c = ts(ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' }),
          -- HTML/XML tag: dat deletes <tag>...</tag>, dit deletes content
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
          -- Digits: vid selects a number like 42
          d = { '%f[%d]%d+' },
          -- Word segment: cie changes one camelCase/snake_case segment
          e = {
            { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
            '^().*()$',
          },
          -- Buffer: vag=whole buffer, vig=non-blank content only
          g = function(ai_type)
            local start_line, end_line = 1, vim.fn.line '$'
            if ai_type == 'i' then
              local first = vim.fn.nextnonblank(start_line)
              local last = vim.fn.prevnonblank(end_line)
              start_line = first ~= 0 and first or start_line
              end_line = last ~= 0 and last or end_line
            end
            return {
              from = { line = start_line, col = 1 },
              to = { line = end_line, col = math.max(vim.fn.getline(end_line):len(), 1) },
            }
          end,
          -- Function call: diu deletes args inside func(...), dau includes the call
          u = ai.gen_spec.function_call(),
          -- Function call without dot: treats vim.fn.call as just "call"
          U = ai.gen_spec.function_call { name_pattern = '[%w_]' },
        },
      }
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
