return {
  -- Telescope (Fuzzy Finder e Pesquisa)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
        cond = function() return vim.fn.executable("cmake") == 1 or vim.fn.executable("make") == 1 end,
      },
    },
    config = function()
      local t = require("telescope")
      local a = require("telescope.actions")
      t.setup({
        defaults = {
          layout_strategy = "flex",
          layout_config = { width = 0.9, height = 0.85 },
          mappings = {
            i = {
              ["<Esc>"] = a.close,
              ["<C-j>"] = a.move_selection_next,
              ["<C-k>"] = a.move_selection_previous,
              ["<C-v>"] = function()
                local text = vim.fn.getreg("+")
                if text == "" then text = vim.fn.getreg('"') end
                text = text:gsub("[\r\n]+", " ")
                vim.api.nvim_put({ text }, "c", true, true)
              end,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
            tiebreak = function(current, existing, prompt)
              -- Prioriza correspondência de tipo de extensão para agrupar ficheiros semelhantes (.cs com .cs, .kt com .kt)
              local function get_ext(path)
                return path:match("^.+%.(%w+)$") or ""
              end
              local ext_cur = get_ext(current.value or "")
              local ext_ex = get_ext(existing.value or "")
              if ext_cur ~= ext_ex then
                return ext_cur < ext_ex
              end
              return false
            end,
          },
          live_grep = {
            mappings = {
              i = {
                ["<CR>"] = function(prompt_bufnr)
                  local action_state = require("telescope.actions.state")
                  local selected = action_state.get_selected_entry()
                  if selected then
                    a.select_default(prompt_bufnr)
                  end
                end,
              },
            },
          },
        },
      })
      pcall(t.load_extension, "fzf")

      local b = require("telescope.builtin")

      -- Pesquisa no projeto: se estiver em visual mode pesquisa a seleção; em normal mode abre com prompt
      local function live_grep_selection()
        b.live_grep()
      end
      local function live_grep_visual()
        -- Guarda registo anterior
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! "yy')
        local text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        text = text:gsub("[\r\n]+", " "):gsub("^%s*(.-)%s*$", "%1")
        b.live_grep({ default_text = text })
      end

      vim.keymap.set("n", "<C-p>", b.find_files, { desc = "Procurar ficheiros" })
      vim.keymap.set("n", "<C-S-f>", live_grep_selection, { desc = "Pesquisar no projeto" })
      vim.keymap.set("v", "<C-S-f>", live_grep_visual, { desc = "Pesquisar texto selecionado no projeto" })
      vim.keymap.set("n", "<C-S-F>", live_grep_selection, { desc = "Pesquisar no projeto" })
      vim.keymap.set("v", "<C-S-F>", live_grep_visual, { desc = "Pesquisar texto selecionado no projeto" })
      vim.keymap.set({ "n", "i" }, "<C-f>", b.current_buffer_fuzzy_find, { desc = "Pesquisar no ficheiro (Ctrl+F)" })
      vim.keymap.set({ "n", "i" }, "<C-S-o>", b.lsp_document_symbols, { desc = "Símbolos e métodos do ficheiro (Ctrl+Shift+O)" })
      vim.keymap.set({ "n", "i" }, "<C-S-O>", b.lsp_document_symbols, { desc = "Símbolos e métodos do ficheiro (Ctrl+Shift+O)" })
      vim.keymap.set({ "n", "i" }, "<C-S-m>", b.diagnostics, { desc = "Problemas / Diagnostics (Ctrl+Shift+M)" })
      vim.keymap.set({ "n", "i" }, "<C-S-M>", b.diagnostics, { desc = "Problemas / Diagnostics (Ctrl+Shift+M)" })
      vim.keymap.set("n", "<leader>ss", b.lsp_document_symbols, { desc = "Símbolos do ficheiro" })
      vim.keymap.set("n", "<leader>sw", b.lsp_workspace_symbols, { desc = "Símbolos do projeto" })
      vim.keymap.set("n", "<leader>xx", b.diagnostics, { desc = "Problemas / Diagnostics" })
      vim.keymap.set("n", "<leader>fg", b.live_grep, { desc = "Grep" })
      vim.keymap.set("n", "<leader>fb", b.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fr", b.oldfiles, { desc = "Recentes" })
    end,
  },

  -- Neo-tree (Explorador de ficheiros)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "s1n7ax/nvim-window-picker",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        window = {
          width = 32,
          mappings = {
            ["<Del>"] = "delete",
            ["<BS>"] = "navigate_up",
            ["d"] = "delete",
          },
        },
        filesystem = {
          bind_to_cwd = false,
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
          },
          use_libuv_file_watcher = true,
          filtered_items = { visible = true, hide_dotfiles = false },
          window = {
            mappings = {
              ["<Del>"] = "delete",
              ["<BS>"] = "navigate_up",
              ["u"] = "navigate_up",
              ["."] = "set_root",
              ["H"] = "toggle_hidden",
            },
          },
        },
      })
      -- Atalhos de navegação do FileTree
      -- Ctrl+Shift+E foca o FileTree
      vim.keymap.set({ "n", "i", "v" }, "<C-S-e>", "<Cmd>Neotree focus<CR>", { desc = "Abrir/Focar FileTree (Ctrl+Shift+E)" })
      vim.keymap.set({ "n", "i", "v" }, "<C-S-E>", "<Cmd>Neotree focus<CR>", { desc = "Abrir/Focar FileTree (Ctrl+Shift+E)" })
      -- Atalho rápido para repor o FileTree na raiz do projeto (cwd original onde abriste o nvim)
      vim.keymap.set("n", "<leader>er", function()
        vim.cmd("Neotree dir=" .. vim.fn.fnameescape(vim.fn.getcwd()))
      end, { desc = "Repor FileTree na raiz do projeto" })
      vim.keymap.set({ "n", "i", "v", "t" }, "<A-b>", "<Cmd>Neotree close<CR>", { desc = "Fechar FileTree (Alt+B)" })
      vim.keymap.set({ "n", "i", "v", "t" }, "<A-B>", "<Cmd>Neotree close<CR>", { desc = "Fechar FileTree (Alt+B)" })
      vim.keymap.set("n", "<C-b>", "<Cmd>Neotree toggle<CR>", { desc = "Alternar FileTree (Ctrl+B)" })
    end,
  },

  -- Bufferline (Separadores de topo)
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          show_close_icon = false,
          show_buffer_close_icons = false,
          separator_style = "thin",
          tab_size = 18,
          max_name_length = 18,
          min_name_length = 0,
          padding = 0,
          custom_filter = function(buf_number)
            local name = vim.fn.bufname(buf_number)
            if name == "" and not vim.bo[buf_number].modified then return false end
            return true
          end,
        },
      })
      vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>")
      vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>")
      vim.keymap.set("n", "<C-Tab>", ":BufferLineCycleNext<CR>", { desc = "Próxima tab" })
      vim.keymap.set("n", "<C-S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Tab anterior" })
      for i = 1, 5 do
        vim.keymap.set("n", "<A-" .. i .. ">", function()
          vim.cmd("BufferLineGoToBuffer " .. i)
        end, { desc = "Ir para tab " .. i })
      end
      vim.keymap.set("n", "<leader>x", ":bdelete<CR>", { desc = "Fechar buffer" })
    end,
  },

  -- Lualine (Barra de estado inferior)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function lsp_status()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then return "LSP: —" end
        local names = vim.tbl_map(function(client) return client.name end, clients)
        return "LSP: " .. table.concat(names, ", ")
      end
      require("lualine").setup({
        options = {
          theme = {
            normal = { a = { fg = "#0d1117", bg = "#ffb347", gui = "bold" }, b = { fg = "#f0f6fc", bg = "#30363d" }, c = { fg = "#f0f6fc", bg = "#161b22" } },
            insert = { a = { fg = "#0d1117", bg = "#7ee787", gui = "bold" }, b = { fg = "#f0f6fc", bg = "#30363d" }, c = { fg = "#f0f6fc", bg = "#161b22" } },
            visual = { a = { fg = "#0d1117", bg = "#d2a8ff", gui = "bold" }, b = { fg = "#f0f6fc", bg = "#30363d" }, c = { fg = "#f0f6fc", bg = "#161b22" } },
            replace = { a = { fg = "#0d1117", bg = "#ff7b72", gui = "bold" }, b = { fg = "#f0f6fc", bg = "#30363d" }, c = { fg = "#f0f6fc", bg = "#161b22" } },
            command = { a = { fg = "#0d1117", bg = "#79c0ff", gui = "bold" }, b = { fg = "#f0f6fc", bg = "#30363d" }, c = { fg = "#f0f6fc", bg = "#161b22" } },
            inactive = { a = { fg = "#8b949e", bg = "#161b22" }, b = { fg = "#8b949e", bg = "#161b22" }, c = { fg = "#8b949e", bg = "#161b22" } },
          },
        },
        sections = {
          lualine_x = { lsp_status, "encoding", "fileformat", "filetype" },
        },
      })
    end,
  },

  -- ToggleTerm (Terminais integrados com suporte a teclado PT)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      local toggleterm = require("toggleterm")
      toggleterm.setup({
        size = 18,
        open_mapping = nil,
        direction = "horizontal",
        persist_size = true,
        start_in_insert = true,
        close_on_exit = false,
        shade_terminals = false,
        winbar = {
          enabled = true,
          name_formatter = function(term)
            return string.format("  Term %d ", term.id)
          end,
        },
        shell = "powershell.exe -NoLogo",
      })

      local function toggle_main()
        local has_open, _ = require("toggleterm.ui").find_open_windows()
        if has_open then
          toggleterm.toggle_all(true)
        else
          toggleterm.toggle()
        end
      end

      local function new_terminal()
        local all = require("toggleterm.terminal").get_all()
        local next_num = 1
        for _, term in pairs(all) do
          if term.id >= next_num then next_num = term.id + 1 end
        end
        -- Fecha todos os terminais abertos primeiro para o novo ocupar a mesma barra e não dividir o ecrã!
        toggleterm.toggle_all(true)
        toggleterm.toggle(next_num)
      end

      local function cycle_terminal(direction)
        local all = require("toggleterm.terminal").get_all()
        local ids = {}
        for _, term in pairs(all) do table.insert(ids, term.id) end
        table.sort(ids)
        if #ids <= 1 then return end
        local current = vim.b.toggle_number or ids[1]
        local next_id = ids[1]
        for i, id in ipairs(ids) do
          if id == current then
            if direction == -1 then
              local prev_idx = i - 1
              if prev_idx < 1 then prev_idx = #ids end
              next_id = ids[prev_idx]
            else
              next_id = ids[(i % #ids) + 1]
            end
            break
          end
        end
        toggleterm.toggle_all(true)
        toggleterm.toggle(next_id)
      end

      -- Menu seletor estilo popup para ver todos os terminais abertos e escolher qual focar
      local function select_terminal()
        local all = require("toggleterm.terminal").get_all()
        local items = {}
        for _, term in pairs(all) do
          local status = term:is_open() and " [Aberto]" or " [Oculto]"
          table.insert(items, {
            id = term.id,
            label = string.format("Terminal #%d%s", term.id, status),
          })
        end
        if #items == 0 then
          toggleterm.toggle(1)
          return
        end
        vim.ui.select(items, {
          prompt = "Terminais Ativos:",
          format_item = function(item) return item.label end,
        }, function(choice)
          if choice then
            toggleterm.toggle_all(true)
            toggleterm.toggle(choice.id)
          end
        end)
      end

      -- Atalhos estilo VS Code para abrir/fechar o terminal inferior
      for _, key in ipairs({ "<C-`>", "<C-'>", "<C-~>", "<C-ç>", "<C-;>" }) do
        vim.keymap.set({ "n", "i", "t" }, key, toggle_main, { desc = "Toggle terminal inferior (abre/fecha)" })
      end
      for _, key in ipairs({ "<C-S-`>", "<C-S-'>", "<C-S-ç>", "<C-S-;>", "<C-:>", "<C-Ç>" }) do
        vim.keymap.set({ "n", "i", "t" }, key, new_terminal, { desc = "Novo terminal inferior" })
      end
      vim.keymap.set({ "n", "i", "t" }, "<C-F12>", function() cycle_terminal(1) end, { desc = "Próximo terminal" })
      vim.keymap.set({ "n", "i", "t" }, "<C-F11>", function() cycle_terminal(-1) end, { desc = "Terminal anterior" })
      vim.keymap.set({ "n", "i", "t" }, "<C-S-t>", select_terminal, { desc = "Listar terminais abertos (menu interativo)" })
      vim.keymap.set({ "n", "i", "t" }, "<C-S-T>", select_terminal, { desc = "Listar terminais abertos (menu interativo)" })
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Modo normal no terminal (permite navegar e clicar)" })
      vim.keymap.set("t", "<C-\\>", [[<C-\><C-n>]], { desc = "Modo normal no terminal" })

      -- Abrir ficheiro ou link com parsing inteligente para outputs e logs do .NET / compiladores
      local function open_link_or_file_under_cursor()
        local line_str = vim.api.nvim_get_current_line()

        -- 1. Se contiver URL http:// ou https://
        local url = line_str:match("(https?://[%w%-_%.%?%/%#%:=%%]+)")
        if url then
          vim.ui.open(url)
          return
        end

        -- 2. Deteção de logs típicos do dotnet (ex: C:\projects\...\ArtigoService.cs(26,13) ou C:/projects/.../Program.cs:26:13)
        -- Formato dotnet build: Caminho(linha,coluna): error CS...
        local path, lnum, col = line_str:match("([A-Za-z]:[%w%._\\/%-]+)%(?(%d+)[,:]?(%d*)%)?")

        -- Formato stacktrace dotnet: at Namespace.Class() in C:\...\File.cs:line 42
        if not path then
          path, lnum = line_str:match("in%s+([A-Za-z]:[%w%._\\/%-]+):line%s+(%d+)")
        end

        -- Formato relativo: Arquivo.cs:25:10 ou Arquivo.cs(25,10)
        if not path then
          path, lnum, col = line_str:match("([%w%._\\/%-]+%.cs)[:%(](%d+)[,:]?(%d*)%)?")
        end

        -- Se encontrou um ficheiro no log
        if path then
          -- Limpa pontuação final caso exista
          path = path:gsub("[,%):]+$", "")
          if vim.fn.filereadable(path) == 1 then
            vim.cmd("wincmd p") -- foca a janela de código principal
            vim.cmd("edit " .. vim.fn.fnameescape(path))
            if lnum and tonumber(lnum) then
              local l = tonumber(lnum)
              local c = tonumber(col) or 1
              vim.api.nvim_win_set_cursor(0, { l, math.max(0, c - 1) })
            end
            return
          end
        end

        -- Fallback: tenta expandir palavra sob cursor ou comando gf
        local cfile = vim.fn.expand("<cfile>")
        if cfile and vim.fn.filereadable(cfile) == 1 then
          vim.cmd("wincmd p")
          vim.cmd("edit " .. vim.fn.fnameescape(cfile))
          return
        end
        pcall(vim.cmd, "normal! gf")
      end

      -- No terminal: duplo clique com o rato, botão esquerdo (<CR>) ou 'gx' salta logo para o ficheiro e linha!
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function()
          vim.keymap.set("n", "<CR>", open_link_or_file_under_cursor, { buffer = true, desc = "Saltar para ficheiro/linha do log" })
          vim.keymap.set("n", "gx", open_link_or_file_under_cursor, { buffer = true, desc = "Abrir ficheiro ou link" })
          vim.keymap.set("n", "<2-LeftMouse>", open_link_or_file_under_cursor, { buffer = true, desc = "Duplo-clique para saltar para o código" })
        end,
      })
    end,
  },

  -- Notificações e UI de comandos
  {
    "rcarriga/nvim-notify",
    config = function()
      local notify = require("notify")
      notify.setup({ background_colour = "#1e1e1e" })
      vim.notify = notify
    end,
  },
  {
    "folke/noice.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    config = function()
      local ok, noice = pcall(require, "noice")
      if ok then
        noice.setup({
          presets = { command_palette = true, long_message_to_split = true },
          routes = {
            {
              filter = {
                event = "msg_show",
                any = {
                  { find = "%d+ line" },
                  { find = "%d+ more line" },
                  { find = "%d+ fewer line" },
                  { find = "%d+ lines yanked" },
                  { find = "written" },
                },
              },
              opts = { skip = true },
            },
          },
        })
      end
    end,
  },

  -- Git signs
  { "lewis6991/gitsigns.nvim", config = true },

  -- Diffview (Diffs lado a lado estilo VS Code / IntelliJ)
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
    config = true,
  },

  -- Neogit (Painel Source Control interativo estilo VS Code / Magit)
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    config = function()
      require("neogit").setup({
        kind = "tab", -- Abre numa tab limpa
        disable_hint = false, -- Mostra a barra de ajuda com todos os comandos sempre visível!
        status = {
          show_head_commit_hash = true,
          recent_commit_count = 10,
          HEAD_folded = false,
          mode_padding = 3,
          mode_text = {
            ["M"] = "Modificado",
            ["N"] = "Novo",
            ["A"] = "Adicionado",
            ["D"] = "Apagado",
            ["C"] = "Copiado",
            ["U"] = "Conflito",
            ["R"] = "Renomeado",
          },
        },
        integrations = {
          diffview = true,
          telescope = true,
        },
        mappings = {
          status = {
            ["?"] = "HelpPopup",
          },
        },
      })
    end,
  },

  -- Ferramentas de edição (Comentários, Autopairs, Which-Key)
  { "numToStr/Comment.nvim", config = true },
  { "windwp/nvim-autopairs", config = true },
  { "folke/which-key.nvim", config = true },

  -- Multi-Cursor (vim-visual-multi) configurado estilo VS Code
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      vim.g.VM_default_mappings = 0
      vim.g.VM_set_statusline = 2
      vim.g.VM_silent_exit = 1
      vim.g.VM_quit_after_leaving_insert_mode = 0
      vim.g.VM_maps = {
        ["Find Under"] = "<A-d>",
        ["Find Subword Under"] = "<A-d>",
        ["Skip Region"] = "<A-D>",
        ["Remove Region"] = "<A-q>",
        ["Select All"] = "<C-A-l>",
        ["Undo"] = "u",
        ["Redo"] = "<C-r>",
      }
    end,
  },

  -- Mini.Surround (Manipulação ultra-rápida de chavetas, parêntesis, aspas e tags)
  {
    "echasnovski/mini.surround",
    version = false,
    opts = {
      mappings = {
        add = "sa", -- Adicionar surround (ex: saiw" para rodear palavra com aspas)
        delete = "sd", -- Apagar surround (ex: sd" para remover aspas)
        find = "sf", -- Procurar surround à direita
        find_left = "sF", -- Procurar surround à esquerda
        highlight = "sh", -- Realçar surround
        replace = "sr", -- Substituir surround (ex: sr"' substitui aspas duplas por simples)
        update_n_lines = "sn",
      },
    },
  },
}
