return {
  -- Mason (Gestor de pacotes LSP, formatters e debuggers)
  { "williamboman/mason.nvim", config = true },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "angularls" },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "Hoffs/omnisharp-extended-lsp.nvim",
    },
    config = function()
      -- Configuração visual de Diagnósticos (erros com sublinhado ondulado como no VS Code)
      vim.diagnostic.config({
        underline = true,
        virtual_text = { prefix = "●", spacing = 2 },
        signs = true,
        update_in_insert = true, -- Atualiza os erros instantaneamente enquanto digitas!
        severity_sort = true,
        float = { border = "rounded", source = "always" },
      })

      local caps = require("cmp_nvim_lsp").default_capabilities()
      for _, s in ipairs({ "lua_ls", "pyright", "ts_ls", "angularls" }) do
        vim.lsp.config[s] = { capabilities = caps }
        vim.lsp.enable(s)
      end

      -- Configuração dedicada OmniSharp para C# no Windows com descompilador ativado
      local omni = vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.exe"
      if vim.fn.executable(omni) == 1 then
        vim.lsp.config["omnisharp"] = {
          capabilities = caps,
          cmd = {
            omni,
            "-z",
            "--hostPID", tostring(vim.fn.getpid()),
            "DotNet:enablePackageRestore=false",
            "--encoding", "utf-8",
            "--languageserver",
            "FormattingOptions:EnableEditorConfigSupport=true",
            "Sdk:IncludePrereleases=true",
            "RoslynExtensionsOptions:EnableDecompilationSupport=true",
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
              EnableImportCompletion = true, -- Auto-import de usings ao escolher sugestão no autocomplete!
            },
          },
        }
        vim.lsp.enable("omnisharp")
      end

      -- Keymaps universais de LSP
      vim.keymap.set("n", "<C-q>", vim.lsp.buf.hover, { desc = "Documentação rápida" })
      vim.keymap.set({ "n", "v" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Sugestões e ações de código" })
      vim.keymap.set({ "n", "i" }, "<C-S-Space>", vim.lsp.buf.signature_help, { desc = "Parâmetros esperados" })

      -- Função inteligente: Ir para implementação (ou definição/descompilação), abrindo Telescope se houver múltiplas
      local function go_to_implementation()
        local has_omnisharp_ext, omni_ext = pcall(require, "omnisharp_extended")
        if has_omnisharp_ext and vim.bo.filetype == "cs" then
          -- Para C#, o omnisharp_extended usa Telescope para descompilação e definições/implementações
          omni_ext.telescope_lsp_definitions()
          return
        end

        local clients = vim.lsp.get_clients({ bufnr = 0 })
        for _, client in ipairs(clients) do
          if client.supports_method("textDocument/implementation") then
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

      -- F12: Ir para implementação / definição
      vim.keymap.set("n", "<F12>", go_to_implementation, { desc = "Ir para implementação/definição (com descompilação .NET)" })

      -- Ctrl + Clique esquerdo: Ir para implementação (abre Telescope se houver múltiplas)
      vim.keymap.set("n", "<C-LeftMouse>", function()
        -- Move o cursor para onde clicaste antes de chamar a implementação
        local mouse = vim.fn.getmousepos()
        if mouse and mouse.winid > 0 then
          vim.api.nvim_set_current_win(mouse.winid)
          vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, mouse.column - 1 })
        end
        go_to_implementation()
      end, { desc = "Ctrl+Clique: Ir para implementação (Telescope se múltiplas)" })

      -- Alt+Shift+F: Formatar ficheiro
      vim.keymap.set("n", "<A-S-f>", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        local can_format = false
        for _, client in ipairs(clients) do
          if client.supports_method("textDocument/formatting") then
            can_format = true
            break
          end
        end
        if can_format then
          vim.lsp.buf.format({ async = true })
        else
          vim.cmd("normal! gg=G")
        end
      end, { desc = "Formatar/indentar ficheiro" })
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
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
}

