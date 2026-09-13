-- Líderes
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bytecode caching para arranque rápido
if vim.loader then
  vim.loader.enable()
end

-- Garante que binários do Mason e do NPM estão sempre no PATH interno do Neovim (Windows)
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
local npm_bin = vim.fn.expand("$APPDATA/npm")
if vim.fn.isdirectory(mason_bin) == 1 and not vim.env.PATH:find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ";" .. vim.env.PATH
end
if vim.fn.isdirectory(npm_bin) == 1 and not vim.env.PATH:find(npm_bin, 1, true) then
  vim.env.PATH = npm_bin .. ";" .. vim.env.PATH
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

