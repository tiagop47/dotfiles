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

-- ============================================================================
-- 4. Cores Base VS Code Exatas
-- ============================================================================
local function apply_vscode_colors()
  -- Editor base
  local bg_editor = "#24292e"
  vim.api.nvim_set_hl(0, "Normal", { fg = "#e1e4e8", bg = bg_editor })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = bg_editor })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = bg_editor })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = bg_editor })
  vim.api.nvim_set_hl(0, "FoldColumn", { bg = bg_editor })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2b3036" })
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#8b949e", bg = bg_editor })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#9ece6a", bg = bg_editor })
  vim.api.nvim_set_hl(0, "Cursor", { bg = "#f78166" })
  vim.api.nvim_set_hl(0, "Visual", { bg = "#593f3c" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1f2428" })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#1f2428" })

  -- Sidebar / explorer
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "#0d1117" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "#0d1117" })
  vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "#0d1117" })
  vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "#0d1117" })

  -- Statusline / Tabline / Winbar
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "#161b22" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#161b22" })
  vim.api.nvim_set_hl(0, "TabLine", { bg = "#161b22" })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = "#161b22" })
  vim.api.nvim_set_hl(0, "WindowTabFill", { bg = "#161b22" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("VSCodeBaseColors", { clear = true }),
  callback = apply_vscode_colors,
})

apply_vscode_colors()

