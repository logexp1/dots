-- ~/.config/nvim/lua/plugins/jupynvim.lua
return {
  {
    'sheng-tse/jupynvim',
    -- BufReadCmd를 후킹하므로 lazy load 불가
    lazy = false,

    -- Rust backend 빌드
    build = function()
      local core = vim.fn.stdpath 'data' .. '/lazy/jupynvim/core'
      vim.notify('Building jupynvim-core (Rust)...', vim.log.levels.INFO)
      local result = vim.fn.system {
        'cargo',
        'build',
        '--release',
        '--manifest-path',
        core .. '/Cargo.toml',
      }
      if vim.v.shell_error ~= 0 then
        vim.notify('jupynvim build failed:\n' .. result, vim.log.levels.ERROR)
      else
        vim.notify('jupynvim-core built successfully', vim.log.levels.INFO)
      end
    end,

    opts = {
      -- "placeholder": Kitty Unicode placeholder protocol
      --   이미지가 버퍼 텍스트에 anchor되어 스크롤할 때 따라옴
      --   animated GIF에 필수
      image_renderer = 'placeholder',

      log_level = 'info',
    },

    config = function(_, opts)
      require('jupynvim').setup(opts)

      -- 1. jupynvim의 <C-j>/<C-k>를 글로벌 스크롤 동작으로 덮어쓰기
      --    (jupynvim 기본은 prev/next cell output 진입이지만,
      --     글로벌 half-page scroll을 더 자주 쓰므로 우선)
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
        pattern = '*.ipynb',
        callback = function()
          vim.defer_fn(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(buf) then
                local name = vim.api.nvim_buf_get_name(buf)
                if name:match '%.ipynb$' then
                  vim.keymap.set('n', '<C-j>', '<C-d>zz', {
                    buffer = buf,
                    desc = 'Scroll down half page (override jupynvim)',
                  })
                  vim.keymap.set('n', '<C-k>', '<C-u>zz', {
                    buffer = buf,
                    desc = 'Scroll up half page (override jupynvim)',
                  })
                end
              end
            end
          end, 200)
        end,
      })

      -- 2. 추가 keymap (자주 쓸 만한 것들)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'ipynb',
        callback = function(ev)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
          end

          -- emacs ob-jupyter에서 자주 쓰던 C-c C-c 흉내
          map('n', '<C-c><C-c>', '<cmd>JupynvimRunCell<cr>', 'Run cell (ob-jupyter style)')

          -- 디버그용 — kernel 상태 빨리 확인
          map('n', '<leader>n?', '<cmd>JupynvimDebug<cr>', 'Show kernel/cell debug info')
        end,
      })

      -- 3. LSP attach 확인용 헬퍼 명령
      vim.api.nvim_create_user_command('JupynvimLspInfo', function()
        local clients = vim.lsp.get_clients { bufnr = 0 }
        if vim.tbl_isempty(clients) then
          vim.notify('No LSP client attached', vim.log.levels.WARN)
          return
        end
        for _, c in ipairs(clients) do
          vim.notify(('Attached: %s'):format(c.name), vim.log.levels.INFO)
        end
      end, { desc = 'Show LSP clients attached to current buffer' })
    end,
  },
}
