return {
  {
    "projekt0n/github-nvim-theme",
    priority = 1000,
    config = function()
      require("github-theme").setup({
        options = {
          transparent = false,
          terminal_colors = true,
        },
      })
      vim.cmd.colorscheme("github_dark_default")

      -- O GitHub Dark deixa alguns grupos semânticos do LSP quase sem cor.
      -- Estes grupos são importantes para distinguir métodos/tipos externos
      -- (por exemplo, APIs provenientes de pacotes NuGet).
      vim.api.nvim_set_hl(0, "@function.method", { fg = "#d2a8ff" })
      vim.api.nvim_set_hl(0, "@method.call", { fg = "#d2a8ff" })
      vim.api.nvim_set_hl(0, "@property", { fg = "#79c0ff" })
      vim.api.nvim_set_hl(0, "@lsp.type.property", { fg = "#79c0ff" })
      vim.api.nvim_set_hl(0, "@interface", { fg = "#ff7b72" })
      vim.api.nvim_set_hl(0, "@lsp.type.interface", { fg = "#ff7b72" })
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    opts = {
      default = true,
      color_icons = true,
    },
  },
  -- Dressing.nvim: Transforma o Ctrl+. (Code Actions), Renomear e menus do Neovim em janelas flutuantes interativas
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      input = {
        enabled = true,
        border = "rounded",
      },
      select = {
        enabled = true,
        backend = { "telescope", "builtin" },
        telescope = {
          layout_strategy = "cursor",
          layout_config = {
            width = 0.6,
            height = 0.4,
          },
        },
      },
    },
  },
}
