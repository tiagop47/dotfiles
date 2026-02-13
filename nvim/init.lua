-- =============================================================================
-- NEOVIM CONFIGURATION (VSCODE STYLE FOR NEOVIDE)
-- =============================================================================

-- 1. BOOTSTRAP LAZY.NVIM
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. PLUGINS
require("lazy").setup({
  -- TEMA E UI
  {
    'projekt0n/github-nvim-theme',
    lazy = false, priority = 1000,
    config = function()
      require('github-theme').setup({ options = { transparent = false, hide_end_of_buffer = true } })
      vim.cmd('colorscheme github_dark_default')
    end
  },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() require("nvim-tree").setup({ view = { width = 30 }, renderer = { indent_markers = { enable = true } } }) end },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' }, config = function() require('telescope').setup({ defaults = { file_ignore_patterns = { "node_modules", ".git/" } } }) end },
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = function() 
    require('lualine').setup({ 
      options = { theme = 'auto' },
      sections = { lualine_c = {{ 'filename', path = 1 }} }
    }) 
  end },
  { 'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end },
  { "karb94/neoscroll.nvim", config = function() require('neoscroll').setup() end },

  -- LSP E AUTOCOMPLETAR
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    dependencies = {
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
      {'hrsh7th/cmp-nvim-lua'},
      {'L3MON4D3/LuaSnip'},
      {'rafamadriz/friendly-snippets'},
    }
  },
  { 'mfussenegger/nvim-jdtls' },
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        java = { "google-java-format" },
      },
    },
  },
  
  -- Multi-cursor estilo VSCode (Ctrl+D)
  {
    'mg979/vim-visual-multi',
    init = function()
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        ['Find Under'] = '<C-d>',
        ['Find Next'] = '<C-d>',
        ['Select All'] = '<C-S-L>',
        ['Skip Region'] = '<C-x>',
      }
    end
  },

  -- Diagnósticos ultra intrusivos (ErrorLens real)
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()
      -- Desativar virtual text padrão para não poluir
      vim.diagnostic.config({ virtual_text = false, virtual_lines = true })
    end,
  },

  -- Linter (Análise estilo Sonar)
  {
    'mfussenegger/nvim-lint',
    config = function()
      require('lint').linters_by_ft = {
        javascript = {'eslint'},
        typescript = {'eslint'},
        java = {'checkstyle'},
      }
      -- Correr linter ao gravar e ao entrar
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
        callback = function() require("lint").try_lint() end,
      })
    end
  },

  -- Terminal integrado (Ctrl+ç estilo VSCode)
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-ç>]],
        direction = 'horizontal',
        size = 12,
      })
    end
  },
})

-- 3. CONFIGURAÇÃO LSP (LSP-ZERO)
local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "<F12>", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<F2>", function() vim.lsp.buf.rename() end, opts)
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {'vtsls', 'jdtls', 'html', 'cssls', 'emmet_ls', 'eslint', 'sonarlint-language-server'},
  handlers = { lsp_zero.default_setup },
})

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({select = true}),
    ['<Tab>'] = cmp_action.luasnip_jump_forward(),
    ['<S-Tab>'] = cmp_action.luasnip_jump_backward(),
  })
})

-- 4. OPÇÕES GERAIS
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.scrolloff = 8

-- 5. CUSTOMIZAÇÃO DE CORES
vim.api.nvim_set_hl(0, "LineNr", { fg = "#32CD32" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#39FF14", bold = true })
vim.api.nvim_set_hl(0, "Cursor", { bg = "#d6b600", fg = "NONE" })

-- 6. ATALHOS (KEYMAPS)
local keymap = vim.keymap.set
keymap('n', '<C-p>', ':Telescope find_files<CR>', { silent = true })
keymap('n', '<C-.>', function() vim.lsp.buf.code_action() end, { silent = true })
keymap('n', '<C-S-E>', ':NvimTreeToggle<CR>', { silent = true })
keymap({'n', 'i', 'v'}, '<C-s>', '<Esc>:w<CR>', { silent = true })
keymap("n", "<C-k>", "<C-u>zz", { silent = true })
keymap("n", "<C-j>", "<C-d>zz", { silent = true })
keymap("n", "<M-S-F>", function() require("conform").format({ lsp_fallback = true, async = true }) end, { desc = "Formatar documento" })
keymap("v", "<C-c>", '"+y')
keymap("i", "<C-v>", '<C-r>+')
keymap("n", "<C-v>", '"+p')
keymap({'n', 'v', 'i'}, '<C-z>', '<Esc>u', { silent = true })

-- 7. NEOVIDE (WINDOWS)
if vim.g.neovide then
    vim.o.guifont = "Consolas:h12" -- Usando Consolas como padrão seguro, muda para a tua se preferires
    vim.g.neovide_fullscreen = true
    vim.g.neovide_scale_factor = 1.0
    vim.g.neovide_opacity = 0.95
    vim.g.neovide_cursor_vfx_mode = "railgun"
    
    -- Atalhos para Zoom (Ctrl + e Ctrl -)
    vim.keymap.set("n", "<C-=>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end)
    vim.keymap.set("n", "<C-+>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end)
    vim.keymap.set("n", "<C-->", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1 end)
end
