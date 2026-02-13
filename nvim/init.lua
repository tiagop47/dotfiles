-- =============================================================================
-- NEOVIM CONFIGURATION (VSCODE STYLE - STABLE)
-- =============================================================================

-- 1. BOOTSTRAP LAZY.NVIM
vim.g.mapleader = " " -- DEFINIR ESPAÇO COMO LEADER

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- UI & THEME
  { 
    'projekt0n/github-nvim-theme', 
    lazy = false, priority = 1000, 
    config = function() 
      require('github-theme').setup({ options = { transparent = false } })
      vim.cmd('colorscheme github_dark_default') 
    end 
  },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() require("nvim-tree").setup({ view = { width = 30 } }) end },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
  { 
    'nvim-lualine/lualine.nvim', 
    dependencies = { 'nvim-tree/nvim-web-devicons' }, 
    config = function() 
      require('lualine').setup({ sections = { lualine_c = {{ 'filename', path = 0 }} } }) 
    end 
  },

  -- TREESITTER (Destaque de Sintaxe e Deteção de Testes)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local status, configs = pcall(require, "nvim-treesitter.configs")
      if not status then return end
      
      configs.setup({
        ensure_installed = { "java", "javascript", "typescript", "html", "css", "lua" },
        sync_install = false,
        auto_install = true,
        highlight = { enable = true },
      })
    end
  },

  -- LSP & AUTOCOMPLETE
  {
    'VonHeikemen/lsp-zero.nvim', branch = 'v3.x',
    dependencies = {
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'L3MON4D3/LuaSnip'},
    }
  },
  { 'mfussenegger/nvim-jdtls' },
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        html = { "prettier" },
        java = { "google-java-format" },
      },
    },
  },

  -- DIAGNÓSTICOS (ERRORLENS)
  {
    "Maan2003/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()
      vim.diagnostic.config({ virtual_text = false, virtual_lines = true })
    end,
  },

  -- TESTES (JAVA & JEST)
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "rcasia/neotest-java",
      "haydenmeade/neotest-jest",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-java")({
            ignore_wrapper = false,
          }),
          require("neotest-jest")({ jestCommand = "npm test --" }),
        }
      })
    end
  },

  -- UTILS
  { 'Exafunction/codeium.vim', config = function() end },
  { 'akinsho/toggleterm.nvim', config = function() require("toggleterm").setup({ open_mapping = [[<C-ç>]], direction = 'horizontal', size = 12, dir = "curr_dir" }) end },
  { 
    'mg979/vim-visual-multi', 
    init = function() 
      vim.g.VM_default_mappings = 0 -- Desativar padrões para não haver conflito
      vim.g.VM_maps = {
        ['Find Under'] = '<C-d>',
        ['Find Next'] = '<C-d>',
        ['Select All'] = '<C-S-L>',
        ['Skip Region'] = '<C-x>',
      }
    end 
  },
  { "karb94/neoscroll.nvim", config = function() require('neoscroll').setup() end },
})

-- CONFIGURAÇÃO LSP
local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr}
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<F12>", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<C-.>", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {'vtsls', 'jdtls', 'html', 'eslint'},
  handlers = { lsp_zero.default_setup },
})

-- OPÇÕES & ATALHOS
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.scrolloff = 8

local keymap = vim.keymap.set
keymap('n', '<C-p>', ':Telescope find_files<CR>')
keymap('n', '<C-S-F>', ':Telescope live_grep<CR>')
keymap('n', '<C-S-E>', ':NvimTreeToggle<CR>')
keymap({'n', 'i', 'v'}, '<C-s>', '<Esc>:w<CR>')
keymap("n", "<C-k>", "<C-u>zz")
keymap("n", "<C-j>", "<C-d>zz")
keymap("n", "<M-S-F>", function() require("conform").format({ lsp_fallback = true }) end)

-- TESTES (Agora com Espaço como Leader)
keymap("n", "<leader>tr", function() require("neotest").run.run() end)
keymap("n", "<leader>ts", function() require("neotest").summary.toggle() end)
keymap("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end)
keymap("n", "<leader>gr", ":GradleRun<CR>")

keymap("v", "<C-c>", '"+y')
keymap("i", "<C-v>", '<C-r>+')
keymap("c", "<C-v>", '<C-r>+') -- Adicionado para colar em prompts/comando
keymap("n", "<C-v>", '"+p')
keymap({'n', 'v', 'i'}, '<C-z>', '<Esc>u')

-- NEOVIDE
if vim.g.neovide then
    vim.g.neovide_fullscreen = true
    vim.o.guifont = "Consolas:h11"
    vim.g.neovide_scale_factor = 1.0
    vim.g.neovide_opacity = 0.95
    vim.keymap.set("n", "<C-=>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end)
    vim.keymap.set("n", "<C-+>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end)
    vim.keymap.set("n", "<C-->", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1 end)
end
