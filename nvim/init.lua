-- =============================================================================
-- NEOVIM CONFIGURATION (MINIMAL STABLE FOR WSL)
-- =============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- UI & THEME
  { 'projekt0n/github-nvim-theme', lazy = false, priority = 1000, config = function() vim.cmd('colorscheme github_dark_default') end },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() require("nvim-tree").setup() end },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = function() require('lualine').setup() end },

  -- LSP (O essencial)
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

  -- JAVA TESTS & GRADLE
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim", "rcasia/neotest-java" },
    config = function() require("neotest").setup({ adapters = { require("neotest-java") } }) end
  },

  -- UTILS
  { 'akinsho/toggleterm.nvim', config = function() require("toggleterm").setup({ open_mapping = [[<C-ç>]], direction = 'horizontal' }) end },
  { 'mg979/vim-visual-multi' },
})

-- Mapeamentos básicos para teste
local keymap = vim.keymap.set
keymap('n', '<C-p>', ':Telescope find_files<CR>')
keymap('n', '<C-S-E>', ':NvimTreeToggle<CR>')
keymap('n', '<leader>tr', function() require("neotest").run.run() end)
keymap('n', '<leader>ts', function() require("neotest").summary.toggle() end)

-- Neovide
if vim.g.neovide then
    vim.g.neovide_fullscreen = true
    vim.o.guifont = "Consolas:h11"
end
