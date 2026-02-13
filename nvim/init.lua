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

  -- DIAGNÓSTICOS (ERRORLENS & TROUBLE)
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
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
  {
    'barrett-ruth/live-server.nvim',
    config = function()
      vim.g.live_server = {
        args = { '--no-browser' }
      }
    end
  },
  { 'akinsho/toggleterm.nvim', config = function() 
    require("toggleterm").setup({ 
      open_mapping = [[<C-ç>]], 
      direction = 'horizontal', 
      size = 12, 
      dir = "curr_dir",
      highlights = {
        Normal = { guibg = "#0d0d14" },
        NormalFloat = { guibg = "#0d0d14" },
        FloatBorder = { guifg = "#33FF33", guibg = "#0d0d14" },
      }
    }) 
  end },
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
  { "karb94/neoscroll.nvim", config = function() require('neoscroll').setup({ mappings = {'<C-u>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb'} }) end },
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
  handlers = {
    lsp_zero.default_setup,
    html = function()
      require('lspconfig').html.setup({
        capabilities = require('cmp_nvim_lsp').default_capabilities()
      })
    end,
  },
})

-- Configuração do Autocomplete (CMP)
local cmp = require('cmp')
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({select = true}), -- Enter para aceitar
    ['<Tab>'] = cmp.mapping.select_next_item(),    -- Tab para o próximo
    ['<S-Tab>'] = cmp.mapping.select_prev_item(), -- Shift+Tab para o anterior
  }),
  sources = {
    {name = 'nvim_lsp'},
    {name = 'luasnip'},
  }
})

-- OPÇÕES & ATALHOS
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.scrolloff = 8

-- Cores dos Números (Verde)
vim.api.nvim_set_hl(0, 'LineNr', { fg = '#00ff00' })
vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#008800' })
vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#008800' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#00ff00', bold = true })

-- Forçar Cores de Diagnósticos (Evita sobreposição pelo tema)
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#FF5555", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#FFB86C", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#8BE9FD", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#50FA7B", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#FF5555" })
    vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#FF5555", bg = "#331111" })
  end,
})

-- Aplicar imediatamente para a sessão atual
vim.cmd("doautocmd ColorScheme")

-- Cor do Cursor (Amarelo)
vim.api.nvim_set_hl(0, 'Cursor', { bg = '#ffff00', fg = '#000000' })
vim.opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

-- Auto-save (Estilo VS Code)
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "FocusLost" }, {
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! wall")
    end
  end,
})

local keymap = vim.keymap.set
keymap('n', '<C-p>', ':Telescope find_files<CR>')
keymap('n', '<C-S-F>', ':Telescope live_grep<CR>')
keymap('n', '<C-S-E>', ':NvimTreeToggle<CR>')
keymap('n', '<M-m>', '<cmd>Trouble diagnostics toggle<CR>') -- Alt + M para ver todos os erros (ESLint, etc)
keymap('n', '<leader>xx', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>') -- Erros apenas do ficheiro atual
keymap({'n', 'i', 'v'}, '<C-s>', '<Esc>:w<CR>')
keymap("n", "<C-k>", "15kzz")
keymap("n", "<C-j>", "15jzz")
keymap("n", "<M-S-F>", function() require("conform").format({ lsp_fallback = true }) end)

-- Toggle Codeium Auto-complete
local codeium_active = true
keymap({'n', 'i', 'v'}, '<C-S-C>', function()
    if codeium_active then
        vim.cmd('CodeiumDisable')
        codeium_active = false
        print("Codeium Desativado")
    else
        vim.cmd('CodeiumEnable')
        codeium_active = true
        print("Codeium Ativado")
    end
end)

-- Live Server Toggle (Alt + l + o)
local live_server_running = false
keymap('n', '<M-l>o', function()
    if live_server_running then
        vim.cmd('LiveServerStop')
        live_server_running = false
        print("Live Server Parado")
    else
        local current_file = vim.fn.expand('%')
        if current_file == "" then current_file = "index.html" end
        
        -- Forçar porta 8080 e abrir o ficheiro atual
        vim.g.live_server = {
            args = { "--port=8080", "--open=" .. current_file }
        }
        
        vim.cmd('LiveServerStart')
        live_server_running = true
        print("Live Server em http://127.0.0.1:8080/ a abrir " .. current_file)
    end
end)

-- TESTES (Agora com Espaço como Leader)
keymap("n", "<leader>tr", function() require("neotest").run.run() end)
keymap("n", "<leader>tl", "<cmd>Trouble qflist toggle<CR>") -- Ver lista de testes/erros no Trouble
keymap("n", "<leader>ts", function() require("neotest").summary.toggle() end)
keymap("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end)
keymap("n", "<leader>gr", ":GradleRun<CR>")

keymap("v", "<C-c>", '"+y')
keymap("i", "<C-v>", '<C-r>+')
keymap("c", "<C-v>", '<C-r>+') -- Adicionado para colar em prompts/comando
keymap("n", "<C-v>", '"+p')
keymap({'n', 'v', 'i'}, '<C-z>', '<Esc>u')

-- Abrir links com Ctrl + Clique (Estilo VS Code)
keymap('n', '<C-LeftMouse>', 'gx')
keymap('t', '<C-LeftMouse>', [[<C-\><C-n><LeftMouse>gx]])
keymap('i', '<C-LeftMouse>', '<Esc><LeftMouse>gx')

-- CONFIGURAÇÃO DE CORES DO TERMINAL (Alta Visibilidade)
local function set_terminal_colors()
    -- Fundo mais escuro para contraste máximo com as cores neon
    vim.api.nvim_set_hl(0, "Terminal", { bg = "#0d0d14", fg = "#ffffff" })
    
    -- Cores ANSI Ultra-Vibrantes (Estilo High-Contrast)
    vim.g.terminal_color_0  = "#0d0d14"
    vim.g.terminal_color_1  = "#FF3333" -- Vermelho Puro (Erro)
    vim.g.terminal_color_2  = "#33FF33" -- Verde Neon
    vim.g.terminal_color_3  = "#FFFF00" -- Amarelo Puro (Warning)
    vim.g.terminal_color_4  = "#3399FF" -- Azul Brilhante
    vim.g.terminal_color_5  = "#FF33FF" -- Magenta
    vim.g.terminal_color_6  = "#00FFFF" -- Cyan Neon
    vim.g.terminal_color_7  = "#FFFFFF" -- Branco Puro
    
    -- Cores Brilhantes (Bright Variants)
    vim.g.terminal_color_8  = "#555555"
    vim.g.terminal_color_9  = "#FF6666"
    vim.g.terminal_color_10 = "#66FF66"
    vim.g.terminal_color_11 = "#FFFF66"
    vim.g.terminal_color_12 = "#66B2FF"
    vim.g.terminal_color_13 = "#FF66FF"
    vim.g.terminal_color_14 = "#66FFFF"
    vim.g.terminal_color_15 = "#F0F0F0"
end

-- Aplicar ao carregar e sempre que o tema mudar
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_terminal_colors })
set_terminal_colors()

-- NEOVIDE
if vim.g.neovide then
    vim.g.neovide_fullscreen = true
    vim.o.guifont = "Consolas:h11"
    vim.g.neovide_scale_factor = 1.0
    vim.g.neovide_opacity = 0.97
    vim.keymap.set("n", "<C-=>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end)
    vim.keymap.set("n", "<C-+>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end)
    vim.keymap.set("n", "<C-->", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1 end)
end
