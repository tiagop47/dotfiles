-- Líderes
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bytecode caching para arranque rápido
if vim.loader then
  vim.loader.enable()
end

-- Garante que binários do Mason, NPM e .NET tools estão sempre no PATH interno do Neovim (Windows)
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
local npm_bin = vim.fn.expand("$APPDATA/npm")
local dotnet_tools = vim.fn.expand("~/.dotnet/tools")
if vim.fn.isdirectory(mason_bin) == 1 and not vim.env.PATH:find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ";" .. vim.env.PATH
end
if vim.fn.isdirectory(npm_bin) == 1 and not vim.env.PATH:find(npm_bin, 1, true) then
  vim.env.PATH = npm_bin .. ";" .. vim.env.PATH
end
if vim.fn.isdirectory(dotnet_tools) == 1 and not vim.env.PATH:find(dotnet_tools, 1, true) then
  vim.env.PATH = dotnet_tools .. ";" .. vim.env.PATH
end

-- 1. Opções base, atalhos universais, autocmds e Neovide
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.neovide")
require("config.window_tabs")
require("config.dotnet_test")

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
  defaults = { lazy = false },
  rocks = { enabled = false },
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = false },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
