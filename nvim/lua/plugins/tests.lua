return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nsidorenco/neotest-vstest",
      "marilari88/neotest-vitest",
    },
    config = function()
      local vstest_adapter = require("neotest-vstest")
      local vitest_adapter = require("neotest-vitest")({
        filter_dir = function(name)
          return name ~= "node_modules" and name ~= "dist"
        end,
      })

      -- Prefer a solution that actually lists tests over a duplicate without them.
      vim.g.neotest_vstest = {
        solution_selector = function(solutions)
          local candidates = {}
          for _, solution in ipairs(solutions) do
            local content = table.concat(vim.fn.readfile(solution), "\n"):lower()
            if content:match("test[^\n]*%.[cf]sproj") then
              candidates[#candidates + 1] = solution
            end
          end
          return #candidates == 1 and candidates[1] or nil
        end,
      }

      -- Include projects beside the solution directory (e.g. src/ and Tests/).
      local find_root = vstest_adapter.root
      vstest_adapter.root = function(path)
        local root = find_root(path)
        if not root then return nil end
        local files = require("neotest.lib").files
        root = files.match_root_pattern(".git")(root) or root
        return (root:gsub("/", files.sep))
      end

      require("neotest").setup({
        adapters = {
          vstest_adapter,
          vitest_adapter,
        },
        discovery = {
          enabled = true,
          concurrent = 1,
          filter_dir = function(name)
            return name ~= "node_modules" and name ~= "bin" and name ~= "obj"
              and name ~= "TestResults" and name:sub(1, 1) ~= "."
          end,
        },
        status = { signs = true, virtual_text = false },
        diagnostic = { enabled = true },
        icons = { passed = "✔", failed = "✘", running = "◷", skipped = "↷", unknown = "○" },
        summary = {
          open = "botright vsplit | vertical resize 48",
          follow = true,
          expand_errors = true,
          mappings = {
            jumpto = { "<CR>", "<2-LeftMouse>" },
            expand = "<Tab>",
          },
        },
        output = { open_on_run = false },
        quickfix = { open = false },
        floating = { border = "rounded", max_width = 0.85, max_height = 0.8 },
      })

      -- Evita o bug de "Select window:" travado no Windows/Neovide quando se clica num teste.
      -- Abre imediatamente o teste na janela de código apropriada sem perguntar interativamente.
      local neotest_ui = require("neotest.lib").ui
      neotest_ui.open_buf = function(bufnr, line, column)
        local api = vim.api
        local target_win = nil

        local function is_usable_win(win)
          if not api.nvim_win_is_valid(win) or api.nvim_win_get_config(win).relative ~= "" then
            return false
          end
          -- Neovim 0.10+: respeita a opção winfixbuf que bloqueia a troca de buffers (ex: janelas especiais/sidebars)
          if vim.wo[win].winfixbuf then
            return false
          end
          local b = api.nvim_win_get_buf(win)
          local buftype = api.nvim_buf_get_option(b, "buftype")
          local filetype = api.nvim_buf_get_option(b, "filetype")
          return buftype == "" and filetype ~= "neo-tree" and filetype ~= "neotest-summary"
        end

        -- 1. Se o buffer já estiver aberto numa janela visível e utilizável, reutiliza-a
        for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
          if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == bufnr and not vim.wo[win].winfixbuf then
            target_win = win
            break
          end
        end

        -- 2. Procura a janela anterior do utilizador
        if not target_win then
          local prev_win = vim.fn.winnr("#") > 0 and vim.fn.win_getid(vim.fn.winnr("#")) or nil
          if prev_win and is_usable_win(prev_win) then
            target_win = prev_win
          end
        end

        -- 3. Se ainda não tiver janela, escolhe qualquer janela de edição válida
        if not target_win then
          for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
            if is_usable_win(win) then
              target_win = win
              break
            end
          end
        end

        -- 4. Fallback: se nenhuma janela aberta for utilizável, cria uma nova janela editável
        if not target_win or vim.wo[target_win].winfixbuf then
          -- Procura uma janela não-flutuante para dar split
          for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
            if api.nvim_win_is_valid(win) and api.nvim_win_get_config(win).relative == "" then
              api.nvim_set_current_win(win)
              vim.cmd("split")
              target_win = api.nvim_get_current_win()
              vim.wo[target_win].winfixbuf = false
              break
            end
          end
          if not target_win then
            vim.cmd("new")
            target_win = api.nvim_get_current_win()
            vim.wo[target_win].winfixbuf = false
          end
        end

        if api.nvim_buf_is_valid(bufnr) and api.nvim_win_is_valid(target_win) then
          -- Garante explicitamente que winfixbuf está desativado na janela alvo antes de trocar
          vim.wo[target_win].winfixbuf = false
          local ok, _ = pcall(api.nvim_win_set_buf, target_win, bufnr)
          if ok then
            if line then
              pcall(api.nvim_win_set_cursor, target_win, { line + 1, column or 0 })
            end
            api.nvim_set_current_win(target_win)
          end
        end
      end

      -- Previne crash assíncrono do neotest (Invalid buffer id) quando um buffer foi fechado/recarregado
      local nio_api = require("nio").api
      local orig_nio_del_extmark = nio_api.nvim_buf_del_extmark
      nio_api.nvim_buf_del_extmark = function(buf, ns, id)
        if not vim.api.nvim_buf_is_valid(buf) then
          return true
        end
        local ok, err = pcall(orig_nio_del_extmark, buf, ns, id)
        if not ok then
          return true
        end
        return err
      end

      local orig_del_extmark = vim.api.nvim_buf_del_extmark
      vim.api.nvim_buf_del_extmark = function(buf, ns, id)
        if not vim.api.nvim_buf_is_valid(buf) then
          return true
        end
        local ok, err = pcall(orig_del_extmark, buf, ns, id)
        if not ok then
          return true
        end
        return err
      end
      -- Only test failures get these settings; LSP diagnostics keep their own style.
      vim.diagnostic.config({
        virtual_text = {
          prefix = "✘",
          spacing = 3,
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\r", "")
            message = message:match("^(.-)\n%s*at ") or message
            return message:gsub("\n%s*", " | ")
          end,
        },
        virtual_lines = false,
        signs = false,
        underline = true,
        float = { border = "rounded", source = "always" },
      }, vim.api.nvim_create_namespace("neotest"))
      local function colors()
        vim.api.nvim_set_hl(0, "NeotestPassed", { fg = "#3fb950", bold = true })
        vim.api.nvim_set_hl(0, "NeotestFailed", { fg = "#f85149", bold = true })
        vim.api.nvim_set_hl(0, "NeotestRunning", { fg = "#e3b341", bold = true })
      end
      colors()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("NeotestUserColors", { clear = true }),
        callback = colors,
      })
    end,
  },
}
