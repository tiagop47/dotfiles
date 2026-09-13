-- Líderes
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bytecode caching para arranque rápido
if vim.loader then
  vim.loader.enable()
end

-- 1. Opções base, atalhos universais, autocmds e Neovide
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.neovide")

-- 2. Gestor de Plugins (lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 3. Carrega automaticamente todos os ficheiros dentro de lua/plugins/
require("lazy").setup("plugins", {
  rocks = { enabled = false },
  install = { colorscheme = { "github_dark_default" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
