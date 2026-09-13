return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      ts.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      ts.install({
        "c", "c_sharp", "lua", "vim", "vimdoc", "javascript", "typescript",
        "html", "css", "json", "python",
      })

      local group = vim.api.nvim_create_augroup("UserTreesitterHighlight", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "c", "cs", "lua", "javascript", "typescript", "html", "css", "json", "python" },
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
          vim.bo[args.buf].indentexpr = "v:lua.vim.treesitter.indent()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable = true,
      max_lines = 3, -- No máximo 3 linhas fixas no topo para não roubar espaço
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 1,
      trim_scope = "outer",
      mode = "cursor",
    },
  },
}
