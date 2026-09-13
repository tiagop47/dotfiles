return {
  -- Mason (Carregado apenas quando chamas :Mason explicitamente - poupa ~80ms no arranque!)
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
    opts = {
      ensure_installed = { "lua_ls", "pyright", "ts_ls", "angularls" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "Hoffs/omnisharp-extended-lsp.nvim",
    },
    config = function()
      -- Configuração visual de Diagnósticos (erros com sublinhado ondulado como no VS Code)
      -- Filtra avisos irritantes de estilo que poluem o ecrã (unused variables, unused expressions, IDE0058, IDE0059, etc.)
      local function filter_diagnostics(diagnostics)
        return vim.tbl_filter(function(d)
          local msg = d.message:lower()
          local code = tostring(d.code or "")
          -- C# / Roslyn unused warnings
          if msg:find("expression value is never used")
             or msg:find("value assigned to.*never used")
             or msg:find("is never used")
             or msg:find("is assigned but its value is never used")
             or msg:find("is never assigned")
             or msg:find("unnecessary using directive")
             or code == "IDE0058" -- expression value is never used
             or code == "IDE0059" -- unnecessary assignment of a value
             or code == "IDE0051" -- unused private member
             or code == "IDE0052" -- unread private member
             or code == "IDE0005" -- unnecessary using
             or code == "CS8019"  -- unnecessary using directive
             or code == "CS0168"  -- variable is declared but never used
             or code == "CS0219"  -- variable is assigned but never used
             -- WebDev (TypeScript / ESLint / Angular) unused warnings
             or code == "6133"    -- TS: declared but value is never read
             or code == "6196"    -- TS: unused type/import
             or code == "6192"    -- TS: unused import
             -- Naming rules / Underscores (úteis em testes estilo Metodo_Cenario_Resultado)
             or msg:find("remove underscore")
             or msg:find("identifiers should not contain underscores")
             or code == "CA1707"
          then
            return false
          end
          return true
        end, diagnostics)
      end

      local orig_set = vim.diagnostic.set
      vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
        orig_set(namespace, bufnr, filter_diagnostics(diagnostics), opts)
      end

      vim.diagnostic.config({
        -- No VS Code, o texto ao lado da linha SÓ aparece para ERROS REAIS que partem a compilação!
        virtual_text = {
          prefix = "●",
          spacing = 2,
          severity = { min = vim.diagnostic.severity.ERROR },
        },
        -- Sublinhado apenas para Avisos e Erros (ignora sugestões de estilo/hints)
        underline = {
          severity = { min = vim.diagnostic.severity.WARN },
        },
        signs = {
          severity = { min = vim.diagnostic.severity.WARN },
        },
        update_in_insert = false, -- No VS Code só valida quando pausas a digitação, não enquanto estás a meio de uma palavra!
        severity_sort = true,
        float = { border = "rounded", source = "always" },
      })

      local caps = require("cmp_nvim_lsp").default_capabilities()
      local function root_for(bufnr, markers)
        return function(client_root, on_dir)
          local root = vim.fs.root(client_root, markers)
          if root then
            on_dir(root)
          end
        end
      end

      vim.lsp.config.lua_ls = {
        capabilities = caps,
        cmd = { vim.fn.has("win32") == 1 and "lua-language-server.cmd" or "lua-language-server" },
        root_dir = root_for(nil, { ".luarc.json", ".luarc.jsonc", ".git" }),
      }
      vim.lsp.config.pyright = {
        capabilities = caps,
        cmd = { vim.fn.has("win32") == 1 and "pyright-langserver.cmd" or "pyright-langserver", "--stdio" },
        root_dir = root_for(nil, { "pyproject.toml", "setup.py", "requirements.txt", ".git" }),
      }
      vim.lsp.config.ts_ls = {
        capabilities = caps,
        cmd = { vim.fn.has("win32") == 1 and "typescript-language-server.cmd" or "typescript-language-server", "--stdio" },
        root_dir = root_for(nil, { "tsconfig.json", "jsconfig.json", "package.json", ".git" }),
      }
      vim.lsp.config.angularls = {
        capabilities = caps,
        filetypes = { "typescript", "html", "htmlangular" },
        cmd = {
          "ngserver.cmd",
          "--stdio",
          "--tsProbeLocations",
          table.concat({
            vim.fn.expand("$APPDATA/npm/node_modules"),
            vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules",
          }, ","),
          "--ngProbeLocations",
          table.concat({
            vim.fn.expand("$APPDATA/npm/node_modules"),
            vim.fn.stdpath("data") .. "/mason/packages/angular-language-server/node_modules",
          }, ","),
        },
        root_dir = root_for(nil, { "angular.json", "project.json", "package.json", ".git" }),
      }

      -- OTIMIZAÇÃO: Ativa os LSPs apenas quando abres ficheiros dessa linguagem (Lazy filetype triggering)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "lua" },
        callback = function() pcall(vim.lsp.enable, "lua_ls") end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python" },
        callback = function() pcall(vim.lsp.enable, "pyright") end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
        callback = function() pcall(vim.lsp.enable, "ts_ls") end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "typescript", "html", "htmlangular" },
        callback = function() pcall(vim.lsp.enable, "angularls") end,
      })

      -- Configuração dedicada OmniSharp para C# no Windows com descompilador ativado
      local omni = vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.exe"
      if vim.fn.executable(omni) == 1 then
        vim.lsp.config["omnisharp"] = {
          capabilities = caps,
          root_dir = root_for(nil, {
            "global.json",
            "*.sln",
            "*.slnx",
            "*.csproj",
            ".git",
          }),
          cmd = {
            omni,
            "-z",
            "--hostPID", tostring(vim.fn.getpid()),
            "DotNet:enablePackageRestore=false",
            "--encoding", "utf-8",
            "--languageserver",
          },
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = true,
              OrganizeImports = true,
              NewLinesForBracesInTypes = true,
              NewLinesForBracesInMethods = true,
              NewLinesForBracesInProperties = true,
              NewLinesForBracesInAccessors = true,
              NewLinesForBracesInAnonymousMethods = true,
              NewLinesForBracesInControlBlocks = true,
              NewLinesForBracesInAnonymousTypes = true,
              NewLinesForBracesInObjectCollectionArrayInitializers = true,
              NewLinesForBracesInLambdaExpressionBody = true,
            },
            RoslynExtensionsOptions = {
              EnableDecompilationSupport = true,
              EnableAnalyzersSupport = true,
              EnableImportCompletion = true,
              DocumentAnalysisTimeoutMs = 30000,
              AnalyzeOpenDocumentsOnly = true, -- OTIMIZAÇÃO: Compila e analisa só ficheiros abertos (boot 10x mais rápido!)
            },
            MsBuild = {
              LoadProjectsOnDemand = false,
            },
          },
        }

        -- Ativa OmniSharp apenas quando abres ficheiros C# (.cs)
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "cs" },
          callback = function() pcall(vim.lsp.enable, "omnisharp") end,
        })
      end

      -- Keymaps universais de LSP
      vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, { desc = "Renomear símbolo em todo o projeto (F2 Refactor)" })
      vim.keymap.set("n", "<C-q>", vim.lsp.buf.hover, { desc = "Documentação rápida" })
      vim.keymap.set({ "n", "v" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Sugestões e ações de código" })
      vim.keymap.set({ "n", "i" }, "<C-S-Space>", vim.lsp.buf.signature_help, { desc = "Parâmetros esperados" })

      local function go_to_angular_file_reference()
        if not vim.tbl_contains({ "typescript", "typescriptreact" }, vim.bo.filetype) then
          return false
        end

        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1
        for _, pattern in ipairs({
          "templateUrl%s*:%s*['\"]([^'\"]+)['\"]",
          "styleUrl%s*:%s*['\"]([^'\"]+)['\"]",
          "styleUrls%s*:%s*%[[^]]*['\"]([^'\"]+)['\"]",
        }) do
          local start_pos, end_pos, path = line:find(pattern)
          if path and col >= start_pos and col <= end_pos then
            local source = vim.api.nvim_buf_get_name(0)
            local target = vim.fn.fnamemodify(source, ":h") .. "/" .. path
            target = vim.fn.fnamemodify(target, ":p")
            if vim.fn.filereadable(target) == 1 then
              vim.cmd.edit(vim.fn.fnameescape(target))
              return true
            end
          end
        end
        return false
      end

      -- Função inteligente: Ir para implementação (ou definição/descompilação), abrindo Telescope se houver múltiplas
      local function go_to_implementation()
        if go_to_angular_file_reference() then
          return
        end

        local has_omnisharp_ext, omni_ext = pcall(require, "omnisharp_extended")
        if has_omnisharp_ext and vim.bo.filetype == "cs" then
          -- Para C#, o omnisharp_extended usa Telescope para descompilação e definições/implementações
          omni_ext.telescope_lsp_definitions()
          return
        end

        local clients = vim.lsp.get_clients({ bufnr = 0 })
        for _, client in ipairs(clients) do
          if client:supports_method("textDocument/implementation") then
            -- Telescope lsp_implementations mostra a lista no Telescope se houver mais de 1, ou salta direto se for 1 só!
            local has_telescope, tb = pcall(require, "telescope.builtin")
            if has_telescope then
              tb.lsp_implementations()
            else
              vim.lsp.buf.implementation()
            end
            return
          end
        end

        local has_telescope, tb = pcall(require, "telescope.builtin")
        if has_telescope then
          tb.lsp_definitions()
        else
          vim.lsp.buf.definition()
        end
      end

      -- Ctrl + F12: Mostrar todas as implementações da interface no Telescope
      local function show_all_implementations()
        local has_omnisharp_ext, omni_ext = pcall(require, "omnisharp_extended")
        if has_omnisharp_ext and vim.bo.filetype == "cs" then
          omni_ext.telescope_lsp_implementation()
          return
        end

        local has_telescope, tb = pcall(require, "telescope.builtin")
        if has_telescope then
          tb.lsp_implementations()
        else
          vim.lsp.buf.implementation()
        end
      end

      vim.keymap.set("n", "<C-F12>", show_all_implementations, { desc = "Mostrar todas as implementações da interface (Telescope)" })
      vim.keymap.set("n", "<F12>", go_to_implementation, { desc = "Ir para implementação/definição (com descompilação .NET)" })

      -- Ctrl + Clique esquerdo: Ir para implementação (abre Telescope se houver múltiplas)
      vim.keymap.set("n", "<C-LeftMouse>", function()
        -- Move o cursor para onde clicaste antes de chamar a implementação
        local mouse = vim.fn.getmousepos()
        if mouse and mouse.winid > 0 then
          vim.api.nvim_set_current_win(mouse.winid)
          local bufnr = vim.api.nvim_win_get_buf(mouse.winid)
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          local line = math.max(1, math.min(mouse.line, line_count))
          local line_text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
          local column = math.max(0, math.min(mouse.column - 1, #line_text))
          vim.api.nvim_win_set_cursor(mouse.winid, { line, column })
        end
        go_to_implementation()
      end, { desc = "Ctrl+Clique: Ir para implementação (Telescope se múltiplas)" })

      -- Alt+Shift+F: Formatar ficheiro (Prettier para HTML/Web/Angular, LSP para C#/Python/Lua)
      vim.keymap.set("n", "<A-S-f>", function()
        local ft = vim.bo.filetype
        local web_fts = {
          html = true,
          htmlangular = true,
          typescript = true,
          javascript = true,
          typescriptreact = true,
          javascriptreact = true,
          json = true,
          css = true,
          scss = true,
        }

        -- Para ficheiros Web/HTML/Angular, formata com Prettier
        local prettier_bin = vim.fn.exepath("prettier.cmd")
        if prettier_bin == "" then prettier_bin = vim.fn.exepath("prettier") end
        if prettier_bin == "" then
          local global_npm_prettier = vim.fn.expand("$APPDATA/npm/prettier.cmd")
          if vim.fn.filereadable(global_npm_prettier) == 1 then
            prettier_bin = global_npm_prettier
          end
        end

        if web_fts[ft] and prettier_bin ~= "" then
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local input_text = table.concat(lines, "\n")
          local parser = (ft == "html") and "html" or ((ft == "htmlangular") and "angular" or ((ft == "css" or ft == "scss") and "css" or ((ft == "json") and "json" or "typescript")))

          local obj = vim.system({ prettier_bin, "--parser", parser }, { stdin = input_text }):wait()
          if obj.code == 0 and obj.stdout and #obj.stdout > 0 then
            local formatted = vim.split(obj.stdout:gsub("\r\n", "\n"), "\n", { trimempty = false })
            -- Se a última linha for vazia após quebra, remove para não criar linha extra
            if #formatted > 0 and formatted[#formatted] == "" then
              table.remove(formatted, #formatted)
            end
            vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
            vim.notify("Ficheiro formatado com Prettier!", vim.log.levels.INFO)
            return
          elseif obj.stderr and #obj.stderr > 0 then
            vim.notify("Erro no Prettier: " .. obj.stderr, vim.log.levels.WARN)
          end
        end

        local clients = vim.lsp.get_clients({ bufnr = 0 })
        local can_format = false
        for _, client in ipairs(clients) do
          if client:supports_method("textDocument/formatting") then
            can_format = true
            break
          end
        end
        if can_format then
          vim.lsp.buf.format({ async = true })
        else
          vim.cmd("normal! gg=G")
        end
      end, { desc = "Formatar/indentar ficheiro (Prettier / LSP)" })
    end,
  },

  -- Autocompletion (nvim-cmp + snippets)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Carrega snippets prontos estilo VS Code (prop, propfull, ctor, get/set, etc.)
      pcall(function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end)
      -- Templates Angular usam o filetype htmlangular; reutiliza os snippets
      -- de HTML e Angular para permitir expansões como div, ngFor e ngIf.
      luasnip.filetype_extend("htmlangular", { "html", "angular" })

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        window = {
          completion = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
          }),
          documentation = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
          }),
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            local icons = {
              Text = "󰉿 Text",
              Method = "󰆧 Method",
              Function = "󰊕 Function",
              Constructor = " Constructor",
              Field = "󰜢 Field",
              Variable = "󰀫 Variable",
              Class = "󰠱 Class",
              Interface = " Interface",
              Module = " Module",
              Property = "󰜢 Property",
              Unit = "󰑭 Unit",
              Value = "󰎠 Value",
              Enum = " Enum",
              Keyword = "󰌋 Keyword",
              Snippet = " Snippet",
              Color = "󰏘 Color",
              File = "󰈙 File",
              Reference = "󰈇 Reference",
              Folder = "󰉋 Folder",
              EnumMember = " EnumMember",
              Constant = "󰏿 Constant",
              Struct = "󰙅 Struct",
              Event = " Event",
              Operator = "󰆕 Operator",
              TypeParameter = "󰅲 TypeParam",
            }
            vim_item.kind = icons[vim_item.kind] or vim_item.kind
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
        }, {
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
      })
    end,
  },
}

