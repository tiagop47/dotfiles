-- Configurações Globais
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.scrolloff = 8
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.softtabstop = 2
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.cmdheight = 0
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "split"
opt.cursorline = true
opt.laststatus = 3
opt.showtabline = 0

-- Browser integration for WSL: always open links/files in Windows default browser.
local uname = vim.loop.os_uname()
local is_wsl = vim.fn.has("wsl") == 1 or (uname and uname.release and uname.release:match("microsoft"))
if is_wsl and vim.fn.executable("wslview") == 1 then
  vim.g.netrw_browsex_viewer = "wslview"
  vim.env.BROWSER = "wslview"
  vim.g.mkdp_browserfunc = "MKDP_browserfunc"

  vim.ui.open = function(uri)
    vim.fn.jobstart({ "wslview", uri }, { detach = true })
    return true
  end

  vim.cmd([[
    function! MKDP_browserfunc(url)
      call system('wslview ' . shellescape(a:url))
    endfunction
  ]])
end

-- Neovide
if vim.g.neovide then
    vim.g.neovide_fullscreen = true
    vim.o.guifont = "Consolas:h12" -- Aumentado para h12
    vim.g.neovide_scale_factor = 1.0
    vim.g.neovide_opacity = 0.97
end

-- Função para forçar cores personalizadas (Verde Neon e Amarelo Torrado)
local function apply_custom_colors()
    vim.api.nvim_set_hl(0, 'LineNr', { fg = '#39FF14' }) -- Verde Neon
    vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#228B22' }) -- Verde Floresta
    vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#228B22' })
    vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#39FF14', bold = true })
    vim.api.nvim_set_hl(0, 'Cursor', { bg = '#DAA520', fg = '#000000' }) -- Amarelo Torrado
end

-- Aplicar ao carregar e sempre que o tema mudar
vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_custom_colors })
apply_custom_colors()

vim.opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
