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
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
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
  { "numToStr/Comment.nvim", opts = {} }, -- Comentários fáceis com `gcc` ou `gc`
  { "echasnovski/mini.surround", opts = {} }, -- Manipular aspas, parênteses, etc.
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
  { "folke/trouble.nvim", opts = {} },
  -- Removido lsp_lines devido a instabilidade com versões novas do Neovim


  -- DEBUGGING & TESTES
  { "mfussenegger/nvim-dap", dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" } },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "rcasia/neotest-java", "haydenmeade/neotest-jest" },
    config = function()
      require("neotest").setup({ adapters = { require("neotest-java"), require("neotest-jest")({ jestCommand = "npm test --" }) } })
    end
  },

  -- UTILS
  { 'akinsho/toggleterm.nvim', opts = { open_mapping = [[<C-ç>]], direction = 'float' } },
  { 'Exafunction/codeium.vim' },
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
  ensure_installed = {'vtsls', 'angularls', 'eslint', 'html', 'cssls', 'emmet_ls'},
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
  ensure_installed = { 'prettier', 'prettierd', 'eslint_d' }
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
