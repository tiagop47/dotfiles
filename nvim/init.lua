-- =============================================================================
-- PROFESSIONAL NEOVIM CONFIGURATION (JS & ANGULAR OPTIMIZED)
-- =============================================================================

require("config.options")

-- 1. BOOTSTRAP LAZY.NVIM
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- UI & THEME
  {
    'sainnhe/gruvbox-material',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = 'hard'
      vim.g.gruvbox_material_better_performance = 1
      vim.cmd('colorscheme gruvbox-material')
    end
  },
  { "SmiteshP/nvim-navic", dependencies = "neovim/nvim-lspconfig" },
  { 
    "nvim-tree/nvim-tree.lua", 
    dependencies = "nvim-tree/nvim-web-devicons", 
    opts = { 
      view = { width = 30 },
      filters = {
        git_ignored = false, -- Não esconder ficheiros do .gitignore
        dotfiles = false,
      },
      git = {
        enable = true,
        ignore = false, -- Forçar a exibição mesmo que o git ignore
      },
    } 
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          sorting_strategy = 'ascending',
          layout_config = { prompt_position = 'top' },
          file_ignore_patterns = { 'node_modules', '.git/' },
        },
        pickers = {
          find_files = { hidden = true },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
          },
        },
      })
      pcall(telescope.load_extension, 'fzf')
      pcall(telescope.load_extension, 'refactoring')
    end
  },
  { 
    'nvim-lualine/lualine.nvim', 
    dependencies = { 'nvim-tree/nvim-web-devicons', 'SmiteshP/nvim-navic' }, 
    config = function() 
      require('lualine').setup({ 
        sections = { lualine_c = { { 'filename', path = 1 }, { function() return require("nvim-navic").get_location() end, cond = function() return require("nvim-navic").is_available() end } } } 
      }) 
    end 
  },

  -- PRODUTIVIDADE PROFISSIONAL (O que faltava)
  { "lewis6991/gitsigns.nvim", opts = {} }, -- Indicadores de Git na margem
  { "folke/which-key.nvim", opts = {} }, -- Ajuda visual para atalhos
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  }, -- Visualização de diffs estilo IDE
  { "numToStr/Comment.nvim", opts = {} }, -- Comentários fáceis com `gcc` ou `gc`
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter", "nvim-telescope/telescope.nvim" },
    opts = {},
  }, -- Refactors tipo IDE (extract/inline/etc.)
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
  }, -- Sessões por projeto
  {
    "echasnovski/mini.surround",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  }, -- Manipular aspas, parênteses, etc.
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} }, -- Guias de indentação
  { "windwp/nvim-autopairs", config = true },

  -- TREESITTER (Syntax Highlighting)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = { "windwp/nvim-ts-autotag" },
    config = function()
      local status, configs = pcall(require, "nvim-treesitter.configs")
      if status then
        configs.setup({
          ensure_installed = { "javascript", "typescript", "html", "css", "lua", "json", "markdown", "java" },
          highlight = { enable = true },
          autotag = { enable = true },
        })
      end
    end
  },

  -- LSP & AUTOCOMPLETE
  {
    'VonHeikemen/lsp-zero.nvim', branch = 'v3.x',
    dependencies = {
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
      {'WhoIsSethDaniel/mason-tool-installer.nvim'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'L3MON4D3/LuaSnip'},
    }
  },

  -- FERRAMENTAS ANGULAR & JS
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettier" },
        css = { "prettier" },
        json = { "prettier" },
        angular = { "prettier" },
      },
      format_on_save = { lsp_fallback = true, timeout_ms = 500 },
    }
  },

  -- DIAGNÓSTICOS & UI
  {
    "folke/trouble.nvim",
    opts = {
      auto_close = true,
      auto_preview = true,
      focus = true,
      warn_no_results = false,
      modes = {
        lsp_references = {
          params = {
            include_declaration = true,
          },
        },
      },
    }
  },
  -- Removido lsp_lines devido a instabilidade com versões novas do Neovim


  -- DEBUGGING & TESTES
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      {
        "rcarriga/nvim-dap-ui",
        config = function()
          local dap = require("dap")
          local dapui = require("dapui")

          dapui.setup()

          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
          end
        end,
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    }
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "rcasia/neotest-java", "haydenmeade/neotest-jest" },
    config = function()
      require("neotest").setup({ adapters = { require("neotest-java"), require("neotest-jest")({ jestCommand = "npm test --" }) } })
    end
  },

  -- UTILS
  { 
    'akinsho/toggleterm.nvim', 
    opts = { 
      open_mapping = [[<C-ç>]], 
      direction = 'float',
      start_in_insert = true,
      persist_mode = true,
      float_opts = {
        border = 'rounded',
      },
    } 
  },
  { 
    'mg979/vim-visual-multi', 
    init = function() 
      vim.g.VM_default_mappings = 0 
      vim.g.VM_maps = {
        ['Find Under'] = '<C-d>',
        ['Find Next'] = '<C-d>',
        ['Select All'] = '<C-S-L>',
      }
    end 
  },
  {
    "stevearc/overseer.nvim",
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 12,
        max_height = 18,
        default_detail = 1,
      },
    },
  }, -- Task runner (build/test/run)
  { "karb94/neoscroll.nvim", config = true },
})

-- CONFIGURAÇÃO LSP PROFISSIONAL
local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(client, bufnr)
  -- Breadcrumbs
  if client.server_capabilities.documentSymbolProvider then
    require("nvim-navic").attach(client, bufnr)
  end
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {'vtsls', 'angularls', 'eslint', 'html', 'cssls', 'emmet_ls', 'jdtls'},
  handlers = {
    lsp_zero.default_setup,
    angularls = function()
      require('lspconfig').angularls.setup({
        -- Configuração para garantir que funciona em projetos Angular
        root_dir = require('lspconfig.util').root_pattern("angular.json", "nx.json", "package.json"),
      })
    end,
  },
})

require('mason-tool-installer').setup({
  ensure_installed = { 'prettier', 'prettierd', 'eslint_d', 'jdtls' }
})

-- CMP (Autocomplete)
local cmp = require('cmp')
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({select = true}),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
  }),
  sources = { {name = 'nvim_lsp'}, {name = 'luasnip'} }
})

require("config.keymaps")

pcall(function()
  local wk = require("which-key")
  wk.add({
    { "<leader>f", group = "Find" },
    { "<leader>g", group = "Git" },
    { "<leader>o", group = "Tasks" },
    { "<leader>r", group = "Refactor" },
    { "<leader>s", group = "Session" },
    { "<leader>t", group = "Tests" },
    { "<leader>x", group = "Diagnostics" },
    { "<leader>d", group = "Debug" },
  })
end)

-- Auto-save on focus lost / leave insert
vim.diagnostic.config({
  virtual_text = {
    prefix = '●', -- Círculo elegante antes do erro
    spacing = 4,
  },
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'always',
  },
})

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "FocusLost" }, {
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! wall")
    end
  end,
})
