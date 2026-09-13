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
