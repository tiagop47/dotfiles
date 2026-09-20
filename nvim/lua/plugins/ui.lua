return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
        options = {
          styles = {
            comments = "NONE",
            functions = "NONE",
            keywords = "NONE",
            variables = "NONE",
            conditionals = "NONE",
            constants = "NONE",
            numbers = "NONE",
            operators = "NONE",
            strings = "NONE",
            types = "NONE",
          },
        },
      })
      vim.cmd("colorscheme github_dark_default")

      -- Sublinhados ondulados estilo VS Code para erros
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#f85149" })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "#d29922" })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "#58a6ff" })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#3fb950" })

      -- Inlay Hints ténues e discretas estilo VS Code (sem caixa/fundo intrusivo)
      vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#7d8590", bg = "NONE", italic = false })
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
