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
  { 'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons', config = function() require("bufferline").setup({}) end },
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = function() require('lualine').setup({ options = { theme = 'auto' } }) end },
  { 'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end },
  { "karb94/neoscroll.nvim", config = function() require('neoscroll').setup() end },

  -- LSP E AUTOCOMPLETAR (A PARTE NOVA)
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    dependencies = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},             -- Required
      {'williamboman/mason.nvim'},           -- Optional
      {'williamboman/mason-lspconfig.nvim'}, -- Optional

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},         -- Required
      {'hrsh7th/cmp-nvim-lsp'},     -- Required
      {'hrsh7th/cmp-buffer'},       -- Optional
      {'hrsh7th/cmp-path'},         -- Optional
      {'saadparwaiz1/cmp_luasnip'}, -- Optional
      {'hrsh7th/cmp-nvim-lua'},     -- Optional

      -- Snippets
      {'L3MON4D3/LuaSnip'},             -- Required
      {'rafamadriz/friendly-snippets'}, -- Optional
    }
  },
  -- Suporte específico para Java (jdtls)
  { 'mfussenegger/nvim-jdtls' },
})

-- 3. CONFIGURAÇÃO LSP (LSP-ZERO)
local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  -- Atalhos padrão do LSP (estilo VSCode)
  local opts = {buffer = bufnr, remap = false}
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)     -- Ir para definição
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)           -- Ver documentação (Hover)
  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts) -- Quick Fix
  vim.keymap.set("n", "<F2>", function() vim.lsp.buf.rename() end, opts)       -- Renomear (F2 no VSCode)
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {'vtsls', 'jdtls', 'html', 'cssls', 'emmet_ls'}, -- Garante instalação de JS, Java, HTML, CSS e Emmet
  handlers = {
    lsp_zero.default_setup,
  },
})

-- Autocompletar (CMP)
local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({select = true}), -- Enter confirma sugestão
    ['<Tab>'] = cmp_action.luasnip_jump_forward(),   -- Tab navega no snippet
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
keymap('n', '<C-b>', ':NvimTreeToggle<CR>', { silent = true })
keymap({'n', 'i', 'v'}, '<C-s>', '<Esc>:w<CR>', { silent = true })
keymap("n", "<C-k>", "<C-u>zz", { silent = true })
keymap("n", "<C-j>", "<C-d>zz", { silent = true })
keymap("v", "<C-c>", '"+y')
keymap("i", "<C-v>", '<C-r>+')
keymap("n", "<C-v>", '"+p')

-- 7. NEOVIDE (WINDOWS)
if vim.g.neovide then
    vim.o.guifont = "FiraCode Nerd Font:h12"
    vim.g.neovide_transparency = 0.95
    vim.g.neovide_cursor_vfx_mode = "railgun"
    vim.g.neovide_cursor_animation_length = 0.08
    vim.g.neovide_scroll_animation_length = 0.3
end
